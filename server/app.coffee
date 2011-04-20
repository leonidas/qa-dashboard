
express = require('express')
db      = require('queries')
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

    widgetdir = basedir+"/plugins/widgets"
    require('widgets').load_all_widgets widgetdir, (err, widgets) ->
        if err?
            console.log err
            throw err

        app.get "/widgets", (req,res) ->
            res.send _.keys(widgets)

        app.get "/widgets/:name", (req,res) ->
            res.send widgets[req.params.name]

    app.get "/reports/latest/:hw", (req,res) ->
       db.latest_reports req.params.hw, (err, arr) ->
           res.send arr

    app.get "/reports/groups/:hw", (req,res) ->
        db.groups_for_hw req.params.hw, (err, arr) ->
            res.send arr

    app.get "/widget/:widget/config", (req, res) ->
        db.widget_config req.params.widget, (err, cfg) ->
            res.send cfg

    app.get "/bugs/:hw/top/:n", (req, res) ->
        db.latest_bug_counts req.params.hw, (err,arr) ->
            res.send arr[0..parseInt(req.params.n)]

    app.post "/user/dashboard/save", (req, res) ->
        uname = "dummy"
        db.save_dashboard uname, req.body, (err) ->
            if err
                res.send {status:"error", error:err}
            else
                res.send {status:"OK"}

    app.get "/user/dashboard", (req, res) ->
        uname = "dummy"
        db.user_dashboard uname, (err, dashb) ->
           res.send dashb

exports.create_app = create_app
