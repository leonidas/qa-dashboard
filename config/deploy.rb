# Must be set before requireing multisage
set :default_stage, "staging"
require 'capistrano/ext/multistage'
require 'yaml'

set :user, "www-data"
set :use_sudo, false
set :copy_compression, :zip

set :scm, :git
set :repository, "http://git.gitorious.org/meego-quality-assurance/qa-dashboard.git"
set :deploy_via, :remote_cache

set :public_children, %w(img css js)

ssh_options[:forward_agent] = true
ssh_options[:user] = "www-data"

after "deploy:finalize_update", "deploy:install_node_packages"

namespace :deploy do
  desc "Restart the app server"
  task :restart, :roles => :app do
    #run "cd #{current_path} && echo 'restart command received at' >> cap_dummy.txt && date >> cap_dummy.txt"
  end

  desc "Start the app server"
  task :start, :roles => :app do
    #run "cd #{current_path} && echo 'start command received at' >> cap_dummy.txt && date >> cap_dummy.txt"
  end

  desc "Stop the app server"
  task :stop, :roles => :app do
    #run "cd #{current_path} && echo 'stop command received at' >> cap_dummy.txt && date >> cap_dummy.txt"
  end

  desc "Install node packages"
  task :install_node_packages, roles => :app do
    run "cd #{release_path} && npm install --unsafe"
  end

end
