set :application, "qa-dashboard.qa.leonidasoy.fi"
set :deploy_to, "/home/#{user}/#{application}"
set :rails_env, "staging"

ssh_options[:port] = 31915

server "qa-dashboard.qa.leonidasoy.fi", :app, :web, :db, :primary => true

namespace :db do
  desc "Import production database to staging"
  task :import, :roles => :db, :only => {:primary => true} do
    # TODO: upload -> unpack -> mongoimport
    #  upload "./qadash_dbdump.tar", "#{current_path}/qadash_dbdump.tar"
    #  run "cd #{current_path} && mongoimport
  end
end
