
express  = require('express')
http     = require('http')
_        = require('underscore')
ccs      = require('connect-coffee-script')
cless    = require('connect-less')
passport = require('passport')

MongoStore = require('connect-mongo')(express)

auth = require('authentication')

HOUR  = 60*60*1000
DAY   = 24*HOUR
MONTH = 30*DAY

create_app = (settings, db) ->
    basedir = settings.app.root

    PUBLIC = basedir + "/public"
    COFFEE = basedir + "/client/coffee"
    LESS   = basedir + "/client/less"

    LESS_TARGET   = "#{PUBLIC}/css"
    COFFEE_TARGET = "#{PUBLIC}/js/modules"

    app = express()

    app.dashboard_settings = settings

    env   = process.env.NODE_ENV || 'development'
    store = new MongoStore db: "qadash-sessions-#{env}"

    auth.init_passport settings.auth.method, db

    app.configure ->
        app.use ccs
            src:        COFFEE
            dest:       COFFEE_TARGET
            prefix:     COFFEE_TARGET.substring(PUBLIC.length)
            force:      true
        app.use cless
            src:        LESS
            dst:        LESS_TARGET
            dstRoot:    PUBLIC
            compress:   true

        app.use express.cookieParser 'mmm cookies'
        app.use express.bodyParser()
        app.use express.session
            secret: 'mmm cookies'
            store:  store
            cookie: maxAge: MONTH
        app.use passport.initialize()
        app.use passport.session()
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
    auth.init_authentication app, db

    #switch settings.auth.method
    #    when 'ldap' then require('ldap_shellauth').init_ldap_shellauth settings
    #    when 'mysql' then require('mysql_auth').init_mysql_auth settings

    widgetdir = basedir+"/plugins/widgets"
    require('widgets').initialize_widgets widgetdir, app, db

    return http.createServer app

exports.create_app = create_app
