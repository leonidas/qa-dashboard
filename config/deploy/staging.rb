set :app_name, "qa-dashboard-dev"
set :server_host, "#{app_name}"
set :server_port, 8000

set :application, server_host
set :deploy_to, "/home/#{user}/#{application}"
set :node_env, "staging"

#set :branch, "fea-new-server-deployment"

set :keep_releases, 5

server server_host, :app, :web, :db, :primary => true

namespace :db do
  desc "Import production database to staging"
  task :import, :roles => :db, :only => {:primary => true} do
    # TODO: upload -> unpack -> mongoimport
    #  upload "./qadash_dbdump.tar", "#{current_path}/qadash_dbdump.tar"
    #  run "cd #{current_path} && mongoimport
  end
end
