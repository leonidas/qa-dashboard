# config valid only for Capistrano 3.1
lock '3.1.0'

require 'capistrano/setup'
require 'capistrano/nvm'
require 'json'

set :nvm_type,     :user
set :nvm_node,     'v0.10.26'
set :nvm_map_bins, %w{node npm}
set :nvm_path,     '$HOME/.nvm' # TODO: Why is this not set automatically?

set :user, 'www-data'

set :application,      'qa-dashboard'
set :repo_url,         'https://github.com/leonidas/qa-dashboard.git'
set :copy_compression, :zip
set :deploy_via,       :remote_cache

set :public_children, %w(img css js)
set :settings_file,   "settings.json"

# Should node modules be installed under shared? This speeds up deployment
# time and keeps the dependencies static (i.e. if module X is already installed
# it will not be reinstalled. If it were reinstalled modules it depends on
# may be different from those used in the previous deployment)
set :shared_node_modules, true

# Exporters base folder
set :exporters_path, 'export'

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence do
      begin
        execute :sudo, '/sbin/restart', fetch(:server_host)
      rescue
        execute :sudo, '/sbin/start', fetch(:server_host)
      end
      sleep 2 # Give some time for the main application
      get_exporters().each do |item|
        begin
          execute :sudo, '/sbin/restart', item[:name]
        rescue
          execute :sudo, '/sbin/start', item[:name]
        end
      end
    end
  end

  desc 'Stop application'
  task :stop do
    on roles(:app), in: :sequence do
      begin
        execute :sudo, '/sbin/stop', fetch(:server_host)
      rescue
      end
      get_exporters().each do |item|
        begin
          execute :sudo, '/sbin/stop', item[:name]
        rescue
        end
      end
    end
  end

  desc 'QA Dashboard setup'
  task :setup do
    invoke 'deploy:check:directories'
    invoke 'qadashboard:setup:directories'
    invoke 'qadashboard:setup:exporters:directories'
    invoke 'qadashboard:setup:settings'
    invoke 'qadashboard:setup:exporters:settings'
    invoke 'qadashboard:setup:upstart'
    invoke 'qadashboard:setup:exporters:upstart'
    invoke 'qadashboard:setup:logrotate'
  end

  task :compile_and_install do
    invoke 'qadashboard:symlink'
    invoke 'qadashboard:node_modules'
    invoke 'qadashboard:compile_assets'
  end

  after :updated, :compile_and_install
end

namespace :qadashboard do
  task :restart do

  end

  desc 'Symlink files and folders'
  task :symlink do
    invoke 'qadashboard:symlink_settings'
    invoke 'qadashboard:symlink_node_modules'
  end

  desc 'Symlink settings files (app and exporters)'
  task :symlink_settings do
    on roles(:app), in: :parallel do
      execute :rm, '-f',   "#{release_path}/#{fetch(:settings_file)}"
      execute :ln, '-nfs', "#{shared_path}/#{fetch(:settings_file)}", "#{release_path}/#{fetch(:settings_file)}"
    end
    get_exporters().each do |item|
      if item.key?(:config)
        on roles(:app), in: :parallel do
          execute :rm, '-f',   "#{release_path}/#{item[:config]}"
          execute :ln, '-nfs', "#{shared_path}/#{item[:shortname]}/config.json",  "#{release_path}/#{item[:config]}"
        end
      end
    end
  end

  desc 'Symlink node_modules (app and exporters)'
  task :symlink_node_modules do
    if fetch(:shared_node_modules)
      on roles(:app), in: :parallel do
        execute :rm, '-rf',   "#{release_path}/node_modules"
        execute :ln, '-nfs', "#{shared_path}/node_modules", "#{release_path}/node_modules"
      end

      get_exporters().each do |item|
        on roles(:app), in: :parallel do
          execute :rm, '-rf',   "#{release_path}/#{item[:path]}/node_modules"
          execute :ln, '-nfs', "#{shared_path}/#{item[:shortname]}/node_modules", "#{release_path}/#{item[:path]}/node_modules"
        end
      end
    end
  end

  desc 'Install node modules'
  task :node_modules do
    on roles(:app), in: :parallel do
      within release_path do execute :npm, 'install', '--production' end
    end

    get_exporters().each do |item|
      on roles(:app), in: :parallel do
        within "#{release_path}/#{item[:path]}" do
          execute :npm, 'install', '--production'
        end
      end
    end
  end

  desc 'Compile assets locally and upload to remote server'
  task :compile_assets do
    puts "\033[33mWARNING: Client assets are built locally, make sure you are on up-to-date version on master branch\033[0m"
    system("npm install")
    system("npm run bower")
    system("npm run build")
    bundle = File.expand_path('../../public/js/bundle.js', __FILE__)
    css    = File.expand_path('../../public/css/dashboard.css', __FILE__)

    on roles(:app), in: :parallel do
      execute :mkdir, '-pv', "#{current_path}/public/js", "#{current_path}/public/css"
      upload! bundle, "#{current_path}/public/js"
      upload! css,    "#{current_path}/public/css"
    end
  end

  namespace :setup do
    desc 'Create needed shared directories'
    task :directories do
      if fetch(:shared_node_modules)
        on roles(:app), in: :parallel do
          execute :mkdir, '-pv', "#{shared_path}/node_modules"
        end
      end
    end

    desc 'Setup settings file and upload to server'
    task :settings do
      settings = JSON.parse File.read("./#{fetch(:settings_file)}")
      settings['app']['name']    = fetch(:application)
      settings['server']['port'] = fetch(:server_port)

      # Check authentication settings
      if settings['auth']['method'] == 'ldap'
        if settings['auth']['ldap']['adminDn'].empty?
          settings['auth']['ldap']['adminDn'] = Capistrano::CLI.ui.ask 'Please enter LDAP admin DN: '
        end

        if settings['auth']['ldap']['adminPassword'].empty?
          settings['auth']['ldap']['adminPassword'] = Capistrano::CLI.password_prompt "Please enter LDAP password for '#{settings["auth"]["ldap"]["adminDn"]}': "
        end
      end

      file = StringIO.new(JSON.pretty_generate(settings))
      on roles(:app), in: :parallel do
        upload! file, "#{shared_path}/#{fetch(:settings_file)}"
      end
    end

    desc 'Generate upstart configuration for QA Dashboard'
    task :upstart do
      conf = StringIO.new(ERB.new(File.read("./config/upstart.conf")).result(binding))
      on roles(:app), in: :parallel do
        upload! conf, "#{shared_path}/#{fetch(:server_host)}.conf"
      end
      puts "\033[32mNOTICE: Upstart configuration generated to #{shared_path}/#{fetch(:server_host)}.conf\033[0m"
    end

    desc 'Generate logrotate configuration'
    task :logrotate do
      conf = StringIO.new(ERB.new(File.read("config/logrotate.conf")).result(binding))
      on roles(:app), in: :parallel do
        upload! conf, "#{shared_path}/logrotate.conf"
      end
      puts "\033[32mNOTICE: Logrotate configuration generated to #{shared_path}/logrotate.conf\033[0m"
    end


    namespace :exporters do
      desc 'Create directories needed for exporters'
      task :directories do
        get_exporters().each do |item|
          on roles(:app), in: :parallel do
            execute :mkdir, '-pv', "#{shared_path}/#{item[:shortname]}"
            if fetch(:shared_node_modules)
              execute :mkdir, '-pv', "#{shared_path}/#{item[:shortname]}/node_modules"
            end
          end
        end
      end

      desc 'Setup settings files of exporters and upload to server'
      task :settings do
        get_exporters().each do |item|
          if item.key?(:config)
            settings = JSON.parse File.read(item[:config])
            settings['dashboard']['url'] = "http://localhost:#{fetch(:server_port)}"

            file = StringIO.new(JSON.pretty_generate(settings))
            on roles(:app), in: :parallel do
              upload! file, "#{shared_path}/#{item[:shortname]}/config.json"
            end
          end
        end
      end

      desc 'Generate upstart configurations for exports'
      task :upstart do
        get_exporters().each do |item|
          if item.key?(:upstart)
            # Needed in the upstart configuration template
            exporter_path = "#{current_path}/#{item[:path]}"
            exporter      = item[:name]

            target = "#{shared_path}/#{item[:name]}.conf"
            conf   = StringIO.new(ERB.new(File.read(item[:upstart])).result(binding))
            on roles(:app), in: :parallel do upload! conf, target end
            puts "\033[32mNOTICE: Upstart configuration generated to #{target}\033[0m"
          else
            puts "\033[33mWARNING: No upstart configuration file found from #{item[:path]}\033[0m"
          end
        end
      end
    end

  end
end

set :exporters, nil
def get_exporters()
  return fetch(:exporters) unless fetch(:exporters).nil?

  set :exporters, []
  Dir.foreach(fetch(:exporters_path)) do |item|
    next if item == '.' or item == '..'

    fullpath = "#{fetch(:exporters_path)}/#{item}"
    if File.directory?(fullpath)
      exporter = {path: fullpath, name: "qa-dashboard-exporter-#{item}", shortname: item}
      if File.exists?("#{fullpath}/upstart.conf")
        exporter[:upstart] = "#{fullpath}/upstart.conf"
      end
      if File.exists?("#{fullpath}/config.json")
        exporter[:config] = "#{fullpath}/config.json"
      end
      set :exporters,  fetch(:exporters) + [exporter]
    end
  end
  fetch(:exporters)
end
