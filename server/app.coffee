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

express = require('express')
db = require('queries')
http = require('http')

create_app = (basedir, dbm) ->

    PUBLIC = basedir + "/public"
    COFFEE = basedir + "/client/coffee"
    LESS   = basedir + "/client/less"

    app = express.createServer()

    app.configure ->
        app.use express.compiler
            src: COFFEE
            dest: PUBLIC
            enable: ['coffeescript']
        app.use express.compiler
            src: LESS
            dest: PUBLIC
            enable: ['less']

        app.use express.cookieParser()
        app.use express.bodyParser()
        app.use express.session {secret: "TODO"}
        app.use express.static PUBLIC

    app.configure "development", ->
        app.use express.logger()
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    app.configure "production", ->
        app.use express.logger()
        app.use express.errorHandler()

    app.get "/reports/latest/:hw", (req,res) ->
       db.latest_reports req.params.hw, (err, arr) ->
           res.send arr

    app.get "/reports/groups/:hw", (req,res) ->
        db.groups_for_hw req.params.hw, (err, arr) ->
            res.send arr

    app.get "/widget/:widget/config", (req, res) ->
        db.widget_config req.params.widget, (err, cfg) ->
            res.send cfg

    app.get "/bugs/:hw/top/:n", (req, res) ->
        db.latest_bug_counts req.params.hw, (err,arr) ->
            res.send arr[0..parseInt(req.params.n)]

    app.post "/user/dashboard/save", (req, res) ->
        uname = "dummy"
        db.save_dashboard uname, req.body, (err) ->
            if err
                res.send {status:"error", error:err}
            else
                res.send {status:"OK"}

    app.get "/user/dashboard", (req, res) ->
        uname = "dummy"
        db.user_dashboard uname, (err, dashb) ->
           res.send dashb

exports.create_app = create_app
