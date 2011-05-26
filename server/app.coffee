
express = require('express')
http    = require('http')
_       = require('underscore')

MongoStore = require('connect-mongo')

HOUR  = 60*60*1000
DAY   = 24*HOUR
MONTH = 30*DAY

create_app = (settings, db) ->
    basedir = settings.app.root

    PUBLIC = basedir + "/public"
    COFFEE = basedir + "/client/coffee"
    LESS   = basedir + "/client/less"

    app = express.createServer()

    store = new MongoStore(db:"qadash-sessions")

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
        app.use express.session
            secret: "TODO"
            store:store
            cookie:
                maxAge: MONTH
        app.use express.static PUBLIC

    app.configure "development", ->
        app.use express.logger()
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    app.configure "staging", ->
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
    require('ldap_shellauth').init_ldap_shellauth settings

    widgetdir = basedir+"/plugins/widgets"
    require('widgets').initialize_widgets widgetdir, app, db

    return app

exports.create_app = create_app
