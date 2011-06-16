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

# Utilities for testing

app      = require('app')
testCase = require('nodeunit').testCase
http     = require('http')
monmon   = require('monmon').monmon

TEST_SETTINGS =
    "server":
        "host": "localhost",
        "port": 3130
    "app":
        "root": __dirname + "/.."
    "auth":
        "useldap": false

test_server_app = ""

test_server_start = (callback) ->
    console.log "\x1b[44mStarting test server (port:#{TEST_SETTINGS.server.port})..."
    dbm = monmon.env('test')
    test_server_app = app.create_app TEST_SETTINGS, dbm
    test_server_app.listen TEST_SETTINGS.server.port, callback

test_server_close = (callback) ->
    console.log "\x1b[44mClosing test server..."
    test_server_app.close()
    callback()

read_all = (res, callback) ->
    data = ""

    res.on "data", (chunk) ->
        data += chunk

    res.on "end", ->
        res.body = data
        callback? res

test_server = (env, tests) ->
    orig_setUp    = tests.setUp
    orig_tearDown = tests.tearDown

    dbm = monmon.env(env)

    get = (url, callback) ->
        opts =
            host: TEST_SETTINGS.server.host
            port: TEST_SETTINGS.server.port
            path: url
            method: 'GET'

        http.get opts, (res) ->
            read_all res, callback

    createApp = (callback) ->
        tests.app = app.create_app TEST_SETTINGS, dbm
        tests.app.listen TEST_SETTINGS.server.port, callback

    closeApp = ->
        tests.app.close()

    tests.setUp = (callback) ->
        @get = get
        createApp (err) ->
            if orig_setUp?
                orig_setUp callback
            else
                callback()

    tests.tearDown = (callback) ->
        closeApp()
        if orig_tearDown?
            orig_tearDown callback
        else
            callback()

    return testCase tests

exports.test_server = test_server
exports.test_server_start = test_server_start
exports.test_server_close = test_server_close
