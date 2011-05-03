
express = require('express')
http    = require('http')
_       = require('underscore')

create_app = (basedir, db) ->

    PUBLIC = basedir + "/public"
    COFFEE = basedir + "/client/coffee"
    LESS   = basedir + "/client/less"

    app = express.createServer()

    app.configure ->
        app.use express.compiler
            src: COFFEE
            dest: PUBLIC
            enable: ['coffeescript']
        app.use express.compiler
            src: LESS
            dest: PUBLIC
            enable: ['less']

        app.use express.cookieParser()
        app.use express.bodyParser()
        app.use express.session {secret: "TODO"}
        app.use express.static PUBLIC

    app.configure "development", ->
        app.use express.logger()
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    app.configure "production", ->
        app.use express.logger()
        app.use express.errorHandler()

    require('import-api').init_import_plugins basedir, app, db
    require('query-api' ).init_query_plugins basedir, app, db
    require('user').init_user app, db
    require('authentication').init_authentication app, db
    require('ldap_shellauth').init_ldap_shellauth basedir

    widgetdir = basedir+"/plugins/widgets"
    require('widgets').initialize_widgets widgetdir, app, db

    return app

exports.create_app = create_app
