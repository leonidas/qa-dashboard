set :server_host, "#{fetch(:application)}-dev.leonidasoy.fi"
set :deploy_to,   "/home/#{fetch(:user)}/#{fetch(:server_host)}"

# The port number to which the node process binds to
set :server_port,  8000
set :node_env,     'production'

set :keep_releases, 10

server 'localhost', user: fetch(:user), roles: %w{web app db}
