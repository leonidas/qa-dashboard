
express = require('express')
queries = require('queries')
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

    app.get "/reports/latest/:hw", (req,res) ->
       queries.latest_reports req.params.hw, (err, arr) ->
           res.send arr

    app.get "/reports/groups/:hw", (req,res) ->
        queries.groups_for_hw req.params.hw, (err, arr) ->
            res.send arr

    app.get "/widget/:widget/config", (req, res) ->
        queries.widget_config req.params.widget, (err, cfg) ->
            res.send cfg

    app.get "/bugs/:hw/top/:n", (req, res) ->
        queries.latest_bug_counts req.params.hw, (err,arr) ->
            res.send arr[0..parseInt(req.params.n)]

    app.post "/user/dashboard/save", (req, res) ->
        uname = "dummy"
        queries.save_dashboard uname, req.body, (err) ->
            if err
                res.send {status:"error", error:err}
            else
                res.send {status:"OK"}

exports.create_app = create_app
