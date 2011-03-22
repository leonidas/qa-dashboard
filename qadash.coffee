
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

app.get "/widget/:widget/config", (req, res) ->
    db.widget_config req.params.widget, (err, cfg) ->
        res.send cfg

app.listen(PORT)
