
express  = require('express')
_        = require('underscore')
passport = require('passport')
logger   = require('winston')

MongoStore = require('connect-mongo')(express)

auth = require('authentication')

HOUR  = 60*60*1000
DAY   = 24*HOUR
MONTH = 30*DAY

create_app = (settings, db) ->
    basedir = settings.app.root

    PUBLIC = basedir + "/public"

    app = express()

    app.dashboard_settings = settings

    env   = process.env.NODE_ENV || 'development'
    if env != 'test'
        store = new MongoStore db: "qadash-sessions-#{env}"
    else
        store = new express.session.MemoryStore()

    auth.init_passport settings, db

    expressLogger = express.logger
        stream: write: (msg, encoding) -> logger.info msg
        format: express.logger.default + ' - :response-time ms'

    app.configure ->
        app.use expressLogger

        app.use express.cookieParser 'mmm cookies'
        app.use express.bodyParser(limit: '50mb')
        app.use express.session
            secret: 'mmm cookies'
            store:  store
            cookie: maxAge: MONTH
        app.use passport.initialize()
        app.use passport.session()
        app.use express.static PUBLIC

    app.configure "development", ->
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    app.configure "staging", ->
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    app.configure "production", ->
        app.use express.errorHandler()

    require('import-api').init_import_plugins basedir, app, db
    require('query-api' ).init_query_plugins basedir, app, db
    require('user').init_user app, db
    auth.init_authentication app, db

    widgetdir = basedir+"/plugins/widgets"
    require('widgets').initialize_widgets widgetdir, app, db

    app.get '/config', (req, res) ->
        res.send settings.app.exposed

    app

exports.create_app = create_app
