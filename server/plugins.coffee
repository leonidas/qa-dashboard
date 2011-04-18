# Plugin utilities

_ = require('underscore')

find_plugins_in = (path, callback) ->
    fs.readdir path, (err, files) ->
        return callback? err if err?
        
        ext = if process.env.NODE_ENV in ['production', 'staging']
            "js"
        else
            "coffee"
        rexp = new RegExp "\.#{ext}$"

        files = _(files).filter (fn) -> fn.match rexp
        modules = _(files).map (fn) -> require "#{path}/#{fn}"
        _(modules).filter (m) -> m.register_plugin?

init_routes = (app, method, root, paths) ->
    m = app[method]
    _(paths).each (f,p) -> m root+p, f
