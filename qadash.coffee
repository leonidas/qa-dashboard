
PORT   = 3030

require.paths.unshift './node_modules'
require.paths.push 'server'
require.paths.push 'server/js'

app = require('app').app

app.listen(PORT)

