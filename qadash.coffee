
PORT   = 3030
PUBLIC = __dirname + "/public"
COFFEE = __dirname + "/client/coffee"
JS     = PUBLIC + "/js"

express = require('express')

app = express.createServer()

app.configure ->
    app.use express.compiler
        src: COFFEE
        dest: PUBLIC
        enable: ['coffeescript']
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

app.listen(PORT)
