
PORT   = 3030
PUBLIC = __dirname + "/public"
COFFEE = __dirname + "/client/coffee"
LESS   = __dirname + "/client/less"

express = require('express')
app = express.createServer()

db = require('./server/queries.coffee')
http = require('http')

app.configure ->
    app.use express.compiler
        src: COFFEE
        dest: PUBLIC
        enable: ['coffeescript']
    app.use express.compiler
        src: LESS
        dest: PUBLIC
        enable: ['less']

    app.use express.logger()
    app.use express.cookieParser()
    app.use express.bodyParser()
    app.use express.session {secret: "TODO"}
    app.use express.static PUBLIC

app.configure "development", ->
    app.use express.errorHandler
        dumpExceptions: true
        showStack: true

app.configure "production", ->
    app.use express.errorHandler()

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

app.listen(PORT)

