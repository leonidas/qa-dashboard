set :app_name, "qa-dashboard"
set :server_host, "#{app_name}"
set :server_port, 8000

set :application, server_host
set :deploy_to, "/home/#{user}/#{application}"
set :node_env, "production"

set :branch, "fea-new-server-deployment"

server server_host, :app, :web, :db, :primary => true

after "deploy:symlink" do
  # Allow robots to index
  run "rm #{current_path}/public/robots.txt"
  run "touch #{current_path}/public/robots.txt"
end

namespace :db do
  desc "Dump and fetch production database"
  task :dump, :roles => :db, :only => {:primary => true} do
    run "cd #{current_path} && mongodump --db qadash-production && tar -czf qadash-production.tar.gz ./dump/qadash-production"
    get "#{current_path}/qadash-production.tar.gz", "./qadash-production.tar.gz"
    run "rm #{current_path}/qadash-production.tar.gz"
  end
end
