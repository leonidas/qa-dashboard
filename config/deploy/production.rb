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
    # TODO: fetch to mongodb
    #  run "cd #{current_path} && RAILS_ENV='#{rails_env}' rake db:dump"
    #  get "#{current_path}/qa_reports_production.sql.bz2", "./qa_reports_production.sql.bz2"
    #  run "rm #{current_path}/qa_reports_production.sql.bz2"
  end
end
