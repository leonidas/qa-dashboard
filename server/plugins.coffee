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

_ = require('underscore')

find_plugins = (path, callback) ->
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

init_plugins = (plugindir, httproot, app, db) ->
    plugins.find_plugins plugindir, (err, modules) ->
        for module in modules
            plugin = module.register_plugin(db)
            for method,funcs in plugin.http
                plugins.init_routes(app, method, httproot, funcs)
