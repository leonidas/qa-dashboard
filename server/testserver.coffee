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

mongo = require('mongodb-wrapper')

TEST_SETTINGS =
    "server":
        "host": "localhost",
        "port": 3130
    "db":
        "host": "localhost"
        "port": 27017
    "app":
        "root": __dirname + "/.."
    "auth":
        "method": "dummy"

class TestServer
    constructor: () ->
        @settings   = TEST_SETTINGS
        env         = process.env.NODE_ENV || 'test'
        @db         = mongo.db settings.db.host, settings.db.port, "qadash-#{env}"
        @server_app = require('app').create_app @settings, @db

    start: (callback) ->
        @server_app.listen @settings.server.port, callback

    close: (callback) ->
        @server_app.close()
        callback()

    db_drop: (callback) ->
        @db.dropDatabase (err) ->
            throw err if err?
            callback()

exports.createServer = new TestServer()
