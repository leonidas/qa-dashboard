#
# This file is part of Meego-QA-Dashboard
#
# Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#

fs = require('fs')
_  = require('underscore')

apis = {}

find_plugins = (path, callback) ->
    fs.readdir path, (err, files) ->
        return callback? err if err?

        ext = if process.env.NODE_ENV in ['production', 'staging']
            "js"
        else
            "coffee"
        rexp = new RegExp "\.#{ext}$"

        files = _(files).filter (fn) -> fn.match rexp

        for fn in files
            console.log "PLUGIN:    loading file #{path}/#{fn}"

        modules = _(files).map (fn) -> require "#{path}/#{fn}"

        callback? err, _(modules).filter (m) -> m.register_plugin?

init_routes = (app, method, root, paths) ->
    m = app[method]
    _(paths).each (f,p) ->
        console.log "PLUGIN: initializing route for #{root+p}"
        m.apply(app, [root+p, f])

init_plugins = (plugindir, httproot, app, db) ->
    console.log "PLUGIN: initializing plugins in #{plugindir}"
    find_plugins plugindir, (err, modules) ->
        for module in modules
            plugin = module.register_plugin(db)
            if plugin.http?
                for method,funcs of plugin.http
                    init_routes(app, method, httproot+"/"+plugin.name, funcs)
            apis[plugin.name] = plugin.api if plugin.api?

exports.init_plugins = init_plugins
exports.get_api = (name) -> apis[name]