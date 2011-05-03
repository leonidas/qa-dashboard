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

coffee = require('coffee-script')
fs     = require('fs')
_      = require('underscore')

auth   = require('authentication')

apis   = {}

find_plugins = (path, callback) ->
    fs.readdir path, (err, files) ->
        return callback? err if err?

        split_filename = (fn) ->
            i = fn.lastIndexOf('.')
            [fn.substr(0,i),fn.substr(i+1)]

        available = {}
        for fn in files
            [basename,ext] = split_filename fn
            if basename not in available or split_filename(available[basename])[1] != 'js'
                    available[basename] = fn

        files = _(available).values()
        modules = _(files).map (fn) -> require "#{path}/#{fn}"
        callback? err, _(modules).filter (m) -> m.register_plugin?

init_routes = (app, db, method, root, paths) ->
    m = app[method]
    secure = auth.secure db
    _(paths).each (f,p) ->
        console.log "PLUGIN: initializing route for #{root+p}"
        f = secure f
        m.apply(app, [root+p, f])

init_plugins = (plugintype, basedir, httproot, app, db, callback) ->
    plugindir = "#{basedir}/plugins/#{plugintype}"
    console.log "PLUGIN: initializing plugins in #{plugindir}"
    find_plugins plugindir, (err, modules) ->
        if err?
            console.log "ERROR: #{err}"
            return callback? err
        for module in modules
            plugin = module.register_plugin(db)
            if plugin.http?
                for method,funcs of plugin.http
                    init_routes(app, db, method, httproot+"/"+plugin.name, funcs)
            apis[plugintype] ?= {}
            apis[plugintype][plugin.name] = plugin.api if plugin.api?
        callback? null, null

exports.init_plugins = init_plugins
exports.api = apis