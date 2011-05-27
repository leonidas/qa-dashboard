set :app_name, "qa-dashboard"
set :server_host, "#{app_name}.qa.leonidasoy.fi"
set :server_port, 3030

set :application, server_host
set :deploy_to, "/home/#{user}/#{application}"
set :node_env, "staging"

ssh_options[:port] = 31915

server server_host, :app, :web, :db, :primary => true

namespace :db do
  desc "Import production database to staging"
  task :import, :roles => :db, :only => {:primary => true} do
    # TODO: upload -> unpack -> mongoimport
    #  upload "./qadash_dbdump.tar", "#{current_path}/qadash_dbdump.tar"
    #  run "cd #{current_path} && mongoimport
  end
end
