# Must be set before requiring multistage
set :default_stage, "staging"
require 'capistrano/ext/multistage'
require 'json'

set :user, "jenkins"
set :use_sudo, false
set :copy_compression, :zip

set :scm, :git
set :repository, "http://git.gitorious.org/meego-quality-assurance/qa-dashboard.git"
set :deploy_via, :remote_cache

set :public_children, %w(img css js)
set :start_script, "./run-server.sh"
set :settings_file, "settings.json"

ssh_options[:forward_agent] = true
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "jenkins_rsa"), File.join(ENV["HOME"], ".ssh", "id_rsa")]
ssh_options[:user] = "jenkins"
set :gateway, "jenkins@access.meego.com"

after "deploy:finalize_update", "deploy:install_node_packages"
after "deploy:setup", "deploy:settings:setup"
after "deploy:symlink", "deploy:settings:symlink"

namespace :deploy do
  desc "Restart the app server"
  task :restart, :roles => :app do
    run "cd #{current_path} && NODE_ENV=#{node_env} #{start_script} --forever stop && NODE_ENV=#{node_env} #{start_script} --forever start"
  end

  desc "Start the app server"
  task :start, :roles => :app do
    run "cd #{current_path} && NODE_ENV=#{node_env} #{start_script} --forever start"
  end

  desc "Stop the app server"
  task :stop, :roles => :app do
    run "cd #{current_path} && NODE_ENV=#{node_env} #{start_script} --forever stop"
  end

  desc "Install node packages"
  task :install_node_packages, roles => :app do
    run "cd #{release_path} && npm install --unsafe --proxy=http://proxy:3128"
  end

  namespace :settings do

    desc "Setup settings file and upload to shared folder"
    task :setup do
      settings = JSON.parse File.read("./#{settings_file}")
      settings["app"]["name"]    = app_name
      settings["server"]["host"] = server_host
      settings["server"]["port"] = server_port
      settings["server"]["url"]  = "http://" + server_host
      put JSON.pretty_generate(settings), "#{shared_path}/#{settings_file}"
    end

    desc "Symlink settings from shared folder"
    task :symlink do
      run "rm -f #{current_path}/#{settings_file} && ln -nfs #{shared_path}/#{settings_file} #{current_path}/#{settings_file}"
    end

    desc "Update settings file"
    task :update do
      deploy.settings.setup
      deploy.settings.symlink
      deploy.restart
    end
  end
end
