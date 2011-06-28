
Client = require('mysql').Client
crypto = require('crypto')

md5 = (s) ->
    hsh = crypto.createHash('md5')
    hsh.update(s)
    hsh.digest('hex')

client = null
settings = null

exports.init_mysql_auth = (settings, callback) ->
    settings = m = settings.auth.mysql
    client = new Client()
    client.host = m.host
    client.port = m.port
    client.user = m.username
    client.password = m.password
    client.database = m.database
    client.connect(callback)


sql = "SELECT pass FROM users WHERE name = ?"

exports.auth_user = (username, password) -> (callback) ->
    client.query sql, [username], (err, results, fields) ->
        return callback err if err?
        ok = results.length > 0 and results[0]['pass'] == md5(password)
        callback null, ok
