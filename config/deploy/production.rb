set :application, "qa-dashboard.leonidasoy.fi"
set :deploy_to, "/home/#{user}/#{application}"
set :node_env, "production"

ssh_options[:port] = 43398

server "qa-dashboard.leonidasoy.fi", :app, :web, :db, :primary => true

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
