# Must be set before requiring multistage
set :default_stage, "staging"
require 'capistrano/ext/multistage'
require 'json'

set :user, "www-data"
set :use_sudo, false
set :copy_compression, :zip

set :scm, :git
set :repository, "https://github.com/leonidas/qa-dashboard.git"
set :deploy_via, :remote_cache

set :public_children, %w(img css js centage)
set :settings_file, "settings.json"

# Should node modules be installed under shared? This speeds up deployment
# time and keeps the dependencies static (i.e. if module X is already installed
# it will not be reinstalled. If it were reinstalled modules it depends on
# may be different from those used in the previous deployment)
set :shared_node_modules, true

ssh_options[:forward_agent] = true
# default_run_options[:pty]   = true
# default_run_options[:shell] = '/bin/bash'
# ssh_options[:port]          = 22

# Exporters base folder
set :exporters_path, 'export'

after "deploy:setup",         "qadashboard:setup:setup"
after "deploy:symlink",       "qadashboard:symlink"
after "qadashboard:symlink",  "qadashboard:install_node_modules"

namespace :deploy do
  desc "Restart server"
  task :restart, :roles => :app do
    run "sudo /sbin/start #{app_name} || sudo /sbin/restart #{app_name}"
    qadashboard.restart_exporters
  end
  desc "Start server"
  task :start, :roles => :app do
    run "sudo /sbin/start #{app_name}"
    qadashboard.start_exporters
  end
  desc "Stop server"
  task :stop, :roles => :app do
    run "sudo /sbin/stop #{app_name}"
    qadashboard.stop_exporters
  end
end

namespace :qadashboard do

  desc "Symlink all settings files"
  task :symlink, :roles => :app do
    qadashboard.symlink_settings
    qadashboard.symlink_node_modules
  end

  desc "Symlink settings file from shared"
  task :symlink_settings, :roles => :app do
    run "rm -f #{current_path}/#{settings_file} && ln -nfs #{shared_path}/#{settings_file} #{current_path}/#{settings_file}"
    get_exporters().each do |item|
      if item.key?(:config)
        run "rm -f #{current_path}/#{item[:config]} && ln -nfs #{shared_path}/#{item[:shortname]}/config.json #{current_path}/#{item[:config]}"
      end
    end
  end

  desc "Symlink node modules folder"
  task :symlink_node_modules, :roles => :app do
    if shared_node_modules
      run "rm -fr #{current_path}/node_modules && ln -nfs #{shared_path}/node_modules #{current_path}/node_modules"
      get_exporters().each do |item|
        run "rm -fr #{current_path}/#{item[:path]}/node_modules && ln -nfs #{shared_path}/#{item[:shortname]}/node_modules #{current_path}/#{item[:path]}/node_modules"
      end
    end
  end

  desc "Install node modules"
  task :install_node_modules, :roles => :app do
    run "cd #{release_path} && npm install --production"
    get_exporters().each do |item|
      run "cd #{release_path}/#{item[:path]} && npm install --production"
    end
  end

  desc "Restart exporters"
  task :restart_exporters, :roles => :app do
    get_exporters().each do |item|
      if item.key?(:upstart)
        run "sudo /sbin/start #{item[:name]} || sudo /sbin/restart #{item[:name]}"
      end
    end
  end

  desc "Stop exporters"
  task :stop_exporters, :roles => :app do
    get_exporters().each do |item|
      if item.key?(:upstart)
        run "sudo /sbin/stop #{item[:name]}"
      end
    end
  end

  desc "Start exporters"
  task :start_exporters, :roles => :app do
    get_exporters().each do |item|
      if item.key?(:upstart)
        run "sudo /sbin/start #{item[:name]}"
      end
    end
  end

  namespace :setup do
    desc "QA Dashboard setup"
    task :setup, :roles => :app do
      get_exporters().each do |item|
        run "mkdir -p #{shared_path}/#{item[:shortname]}"
      end

      if shared_node_modules
        run "mkdir -p #{shared_path}/node_modules"
        get_exporters().each do |item|
          run "mkdir -p #{shared_path}/#{item[:shortname]}/node_modules"
        end
      end

      qadashboard.setup.settings
      qadashboard.setup.settings_exporters
      qadashboard.setup.upstart
      qadashboard.setup.upstart_exporters
      qadashboard.setup.logrotate

      puts "\033[33m\n\nThere are still things you need to do:\033[0m"
      puts "  - Copy the generated upstart configuration files to /etc/init"
      puts "  - Enable restarting the apps without password in /etc/sudoers"
      puts "  - After having deployed the actual application, fix exporters' settings"
      puts "    and run 'cap production qadashboard:restart_exporters\n\n"
    end

    desc "Setup settings file and upload to server"
    task :settings do
      settings = JSON.parse File.read("./#{settings_file}")
      settings["app"]["name"]    = app_name
      settings["server"]["port"] = server_port

      # Check authentication settings
      if settings["auth"]["method"] == "ldap"
        if settings["auth"]["ldap"]["adminDn"].empty?
          settings["auth"]["ldap"]["adminDn"] = Capistrano::CLI.ui.ask "Please enter LDAP admin DN: "
        end

        if settings["auth"]["ldap"]["adminPassword"].empty?
          settings["auth"]["ldap"]["adminPassword"] = Capistrano::CLI.password_prompt "Please enter LDAP password for '#{settings["auth"]["ldap"]["adminDn"]}': "
        end
      end

      put JSON.pretty_generate(settings), "#{shared_path}/#{settings_file}"
    end

    desc "Upload exporter settings to server"
    task :settings_exporters, :roles => :app do
      get_exporters().each do |item|
        if item.key?(:config)
          settings = JSON.parse File.read(item[:config])
          settings["dashboard"]["url"] = "http://localhost:#{server_port}"
          put JSON.pretty_generate(settings), "#{shared_path}/#{item[:shortname]}/config.json"
        end
      end
    end

    desc "Generate upstart configuration for QA Dashboard"
    task :upstart, :roles => :app do
      conf = ERB.new(File.read("./config/upstart.conf")).result(binding)
      put conf, "#{shared_path}/#{app_name}.conf"
      puts "\033[32mNOTICE: Upstart configuration generated to #{shared_path}/#{app_name}.conf\033[0m"
    end

    desc "Generate upstart configurations for exporters"
    task :upstart_exporters, :roles => :app do
      get_exporters().each do |item|
        exporter_path = "#{current_path}/#{item[:path]}"
        exporter      = item[:name]

        if item.key?(:upstart)
          target = "#{shared_path}/#{item[:name]}.conf"
          conf   = ERB.new(File.read(item[:upstart])).result(binding)
          put conf, target
          puts "\033[32mNOTICE: Upstart configuration generated to #{target}\033[0m"
        else
          puts "\033[34mWARNING: No upstart configuration file found from #{fullpath}\033[0m"
        end
      end
    end

    desc "Generate logrotate configuration"
    task :logrotate, :roles => :app do
      conf = ERB.new(File.read("config/logrotate.conf")).result(binding)
      put conf, "#{shared_path}/logrotate.conf"
      puts "\033[32mNOTICE: Logrotate configuration generated to #{shared_path}/logrotate.conf\033[0m"
    end
  end
end

def get_exporters()
  exporters = []
  Dir.foreach(exporters_path) do |item|
    next if item == '.' or item == '..'

    fullpath = "#{exporters_path}/#{item}"
    if File.directory?(fullpath)
      exporter = {path: fullpath, name: "qa-dashboard-exporter-#{item}", shortname: item}
      if File.exists?("#{fullpath}/upstart.conf")
        exporter[:upstart] = "#{fullpath}/upstart.conf"
      end
      if File.exists?("#{fullpath}/config.json")
        exporter[:config] = "#{fullpath}/config.json"
      end
      exporters << exporter
    end
  end
  exporters
end
