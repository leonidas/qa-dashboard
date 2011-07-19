APPROOT       = __dirname
SETTINGS_FILE = "#{APPROOT}/settings.json"

require.paths.unshift './node_modules'
require.paths.push 'server'
require.paths.push 'server/js'

mysql  = require('mysql_auth')
fs     = require('fs')

settings = JSON.parse fs.readFileSync(SETTINGS_FILE)

mysql.init_mysql_auth settings, (err) ->
    if err?
        console.log "ERROR: #{err}"
        return

