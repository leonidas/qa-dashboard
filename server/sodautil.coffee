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

# Soda and selenium utilities
soda     = require('soda')
testutil = require('testutil')

DEBUG = false

# Soda helpers
# TODO: write helpers here (extend the prototype), for frequently used functions

# Browser functions
browser = null #only one module global browser instance
open_browser = () ->
    if not browser?
        browser = soda.createClient
            host: 'localhost'
            port: 4444
            url: 'http://localhost:3130'
            browser: "firefox"
        if DEBUG
            browser.on 'command', (cmd, args) ->
              console.log ' \x1b[33m%s\x1b[0m: %s', cmd, args.join(', ')
    browser

close_browser = (cb) ->
    if browser?
        browser
            .chain
            .testComplete()
            .end (err) ->
               browser = null
               cb err
    else
        cb null

# CSS selectors
selectors =
    logout_btn    :'css=#logout_btn'
    login_btn     :'css=#user_submit'
    user_login    :'css=#user_login'
    user_password :'css=#user_password'
    logged_user   :'css=#logged_user'

# exports
exports.browser       = open_browser()
exports.close_browser = close_browser
exports.selectors     = selectors
