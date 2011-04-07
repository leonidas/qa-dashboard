
PORT   = 3030

require.paths.unshift './node_modules'

app = require('./server/app.coffee').app

app.listen(PORT)

