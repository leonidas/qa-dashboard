# Must be set before requireing multisage
set :default_stage, "staging"
require 'capistrano/ext/multistage'
require 'bundler/capistrano'
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


namespace :deploy do
  desc "Restart the app server"
  task :restart, :roles => :app do
    #run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Start the app server"
  task :start, :roles => :app do
    #run "cd #{current_path} && passenger start --daemonize --environment #{rails_env} --port 3000" 
  end

  desc "Stop the app server"
  task :stop, :roles => :app do
    #run "cd #{current_path} && passenger stop"
  end
end
