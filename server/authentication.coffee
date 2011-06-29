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
ldap  = require('ldap_shellauth')
mysql = require('mysql_auth')

settings = null

sha = (data) ->
    s = crypto.createHash('sha1')
    s.update(data)
    return s.digest('hex')

generate_new_token = (username) -> (callback) ->
    seed = new Date().getTime() + Math.random()*1000
    data = username + seed
    callback? null, sha(data)

authenticate = (username, password) -> (callback) ->
    switch settings.auth.method
        when "ldap"
            ldap.ldap_shellauth(username,password) (err, ok) ->
                console.log err if err?
                callback? err, ok

        when "mysql"
            mysql.auth_user(username,password) (err, ok) ->
                console.log.err if err?
                callback? err, ok

        else
            ok = username == "guest" and password == "guest"
            callback? null, ok

exports.get_token = (db) ->
    users = db.collection("users")
    (username) ->
        user  = users.find({username:username})
        token = user.fields({token:1}).one()
        (callback) ->
            token.run (err, result) ->
                return callback? err if err?
                if result.token?
                    callback? null, result.token
                else
                    pw = result.password
                    generate_new_token(username) (err, token) ->
                        return callback? err if err?
                        op = user.update
                            $set: token: token
                        op.run (err, result) ->
                            callback? null, token

exports.secure = (db) ->
    users = db.collection("users")
    verify_token = (token) -> (callback) ->
        query = users.find({token:token}).fields({}).one()
        query.run (err,result) ->
            callback? err, result?

    (handler) -> (req, res) ->
        if req.session.username?
            handler req, res
        else
            token    = req.body?.token or req.param("token")
            if not token?
                return res.send 403

            if token?
                verify_token(token) (err,valid) ->
                    if err?
                        console.log "ERROR: #{err}"
                    else
                        if valid
                            handler req, res
                        else
                            res.send 403
            else
                res.send 403

exports.init_authentication = (app, db) ->
    users = db.collection("users")
    users.unique().ensureIndex("username").run()
    users.sparse().ensureIndex("token").run()

    # TODO: there should be a nicer way to do this
    settings = app.dashboard_settings

    app.post "/auth/login", (req,res) ->
        login = req.body
        authenticate(login.username, login.password) (err,ok) ->
            if not err? and ok
                req.session.username = login.username
                res.send {status:"ok"}
            else
                res.send {status:"error"}

    app.post "/auth/logout", (req,res) ->
        req.session.destroy (err) ->
            res.send {status:"ok"}

    app.get "/auth/whoami", (req,res) ->
        res.send {username:req.session.username}

