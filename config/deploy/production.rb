set :server_host, "#{fetch(:application)}.leonidasoy.fi"
set :deploy_to,   "/home/#{fetch(:user)}/#{fetch(:server_host)}"

# The port number to which the node process binds to
set :server_port,  8000
set :node_env,     'production'

set :keep_releases, 10

server 'localhost', user: fetch(:user), roles: %w{web app db}

namespace :db do
  desc 'Dump and fetch production database'
  task :dump do
    on roles(:db) do
      within current_path do
        execute :mongodump, '--db', 'qadash-production'
        execute :tar, '-czf', 'qadash-production.tar.gz', './dump/qadash-production'
        download! "#{current_path}/qadash-production.tar.gz", "./qadash-production.tar.gz"
        execute :rm, 'qadash-production.tar.gz'
      end
    end
  end
end
