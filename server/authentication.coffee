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
crypto = require('crypto')
ldap   = require('ldap_shellauth')
mysql  = require('mysql_auth')

{ObjectID}    = require 'mongodb'
passport      = require('passport')
LocalStrategy = require('passport-local').Strategy
bcrypt        = require('bcrypt')

{get_user} = require 'user'

settings = null

encrypt_password = (pwd, cb) ->
    bcrypt.genSalt (err, salt) ->
        return cb? err if err
        bcrypt.hash pwd, salt, cb

verify_password = (pwd, hash, cb) -> bcrypt.compare pwd, hash, cb


strategy   = null
strategies =
    # guest / guest authentication.
    dummy:
        init: (db) ->
            users = db.collection 'users'
            get_or_create_user = get_user db

            # TODO: Can we use same serializers for all methods? To be seen.
            passport.serializeUser (user, cb) ->
                cb null, user._id.toString()

            passport.deserializeUser (id, cb) ->
                users.findOne _id: new ObjectID(id), (err, user) ->
                    return cb err if err
                    return cb "User does not exist" if not user?
                    cb null, user

            passport.use new LocalStrategy (username, password, cb) ->
                process.nextTick ->
                    if username == 'guest' && password == 'guest'
                        get_or_create_user('guest')(cb)
                    else
                        cb null, false, message: 'Incorrect username/password'

            'local' # Return the strategy name for authanticate() to work
    local:
        init: (db) ->
            users = db.collection 'users'
            get_or_create_user = get_user db

            # TODO: Can we use same serializers for all methods? To be seen.
            passport.serializeUser (user, cb) ->
                cb null, user._id.toString()

            passport.deserializeUser (id, cb) ->
                users.findOne _id: new ObjectID(id), (err, user) ->
                    return cb err if err
                    return cb "User does not exist" if not user?
                    cb null, user

            passport.use new LocalStrategy (username, password, cb) ->
                users.findOne username: username, (err, user) ->
                    return cb? err, null, message: 'Login failed' if err?
                    return cb? null, false, message: 'Incorrect username and/or password' if not user?

                    verify_password password, user.password, (err, res) ->
                        return cb? err null, message: 'Incorrect username and/or password' if err?
                        return cb? null, false, message: 'Incorrect username and/or password' if not res

                        cb? null, user

            'local'

# Create a new local user to database.
exports.create_user = (db, username, password, cb) ->
    users = db.collection 'users'
    users.findOne username: username, (err, user) ->
        return cb? err if err?
        return cb? "Username is already taken" if user?

        encrypt_password password, (err, hash) ->
            return cb? err if err
            users.insert username: username, password: hash, dashboard: {}, cb

exports.secure = (db) ->
    users = db.collection("users")
    verify_token = (token) -> (callback) ->
        users.findOne {token: token}, {}, callback

    (handler) -> (req, res) ->
        return handler req, res if req.isAuthenticated()

        token = req.body?.token or req.param("token")
        return res.send 403 unless token?

        verify_token(token) (err, valid) ->
            console.log "ERROR: Verify token failed: #{err}" if err?
            return res.send 500 if err?
            return res.send 403 unless valid
            return handler req, res

exports.init_passport = (method, db) -> strategy = strategies[method].init db

exports.init_authentication = (app, db) ->
    # TODO are this in good location
    users = db.collection("users")
    users.ensureIndex "username", unique: true, ->
    users.ensureIndex "token", sparse: true, ->

    # TODO: there should be a nicer way to do this
    settings = app.dashboard_settings

    app.post "/auth/login", passport.authenticate(strategy), (req, res) ->
        res.send status: 'ok'

    app.post "/auth/logout", (req, res) ->
        req.logout()
        res.send status: 'ok'

    app.get "/auth/whoami", (req,res) ->
        res.send username: req.user.username
