set :application, "qa-dashboard.leonidasoy.fi"
set :deploy_to, "/home/#{user}/#{application}"
set :rails_env, "production"

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
    # TODO: mongodump -> tar -> download -> extract
    #  run "cd #{current_path} && mongodump"
    #  get "#{current_path}/qadash_dbdump.tar", "./qadash_dbdump.tar"
    #  run "rm #{current_path}/qadash_dbdump.tar"
  end
end
