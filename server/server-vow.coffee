# server-vow

http = require('http')

DEFAULT_PORT = 3013

class ServerVow
    initialize: (@app, @port) ->

    run: (suite, callback) ->
        port = @port ? DEFAULT_PORT
        app = @app
        app.listen port, 'localhost', (err) ->
            return callback? err if err?
            suite.run (result) ->
                app.close()

    get: (path, callback) ->
        opts =
            host: 'localhost'
            port: @port
            path: path
        http.get opts, (res) ->
            body = ""
            res.on 'data', (chunk) ->
                body += chunk



exports =
    make_server: (app) -> ServerVow(app)
    
