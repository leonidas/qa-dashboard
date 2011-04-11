
PORT   = 3030

require.paths.unshift './node_modules'
require.paths.push 'server'

app = require('app').app

app.listen(PORT)

