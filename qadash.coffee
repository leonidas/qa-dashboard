
PORT   = 3030

require.paths.unshift './node_modules'
require.paths.push 'server'

app = require('./server/app.coffee').app

app.listen(PORT)

