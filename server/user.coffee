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

get_user = (db) ->
    users = db.collection("users")
    (username) ->
        (callback) ->
            users.findOne username: username, (err, user) ->
                return callback? err, user if err? or user?

                # Create user dashboard
                doc =
                    username:  username
                    dashboard: {}
                users.insert doc, (err) ->
                    if err?
                        console.log "ERROR: #{err}"
                        return callback? err
                    callback? null, doc

sha = (data) ->
    s = crypto.createHash('sha1')
    s.update(data)
    return s.digest('hex')

generate_new_token = (username) -> (callback) ->
    seed = new Date().getTime() + Math.random()*1000
    data = username + seed
    callback? null, sha(data)

get_token = (db) ->
    users = db.collection("users")
    (username) ->
        (callback) ->
            users.findOne {username: username}, {token: 1}, (err, result) ->
                return callback? err if err?
                if result.token?
                    callback? null, result.token
                else
                    generate_new_token(username) (err, token) ->
                        return callback? err if err?
                        users.update {username: username}, {$set: token: token}, (err, result) ->
                            callback? null, token

exports.init_user = (app, db) ->
    users = db.collection("users")

    token = get_token db

    user  = get_user db

    app.get "/user", (req, res) ->
        username = req.session.username
        if not username?
            res.send {}
        else
            user(username) (err, user) ->
                console.log "ERROR: #{err}" if err?
                if user?
                    delete user._id
                    res.send user
                else
                    res.send {}

    app.get "/user/token", (req, res) ->
        username = req.session.username
        if not username?
            res.send 401
        else
            token(username) (err,token) ->
                if err?
                    res.send {status:"error", error:err}
                else
                    res.send {status:"ok", token:token}

    app.get "/user/dashboard", (req,res) ->
        username = req.session.username
        if not username?
            res.send {}
        else
            users.findOne {username: username}, {dashboard: 1}, (err, user) ->
                if err
                    res.send {status:"error", error:err}
                else
                    res.send {status:"ok", result:user.dashboard}

    app.post "/user/dashboard/save", (req, res) ->
        username = req.session.username

        users.update {username: username}, {$set: dashboard: req.body}, (err) ->
            if err?
                res.send 500
                #res.send {status:"error", error:err}
            else
                res.send {status:"ok"}

    app.get "/shared/:user/:tab", (req,res) ->
        users.findOne {username: req.params.user}, {'dashboard.tabs': 1}, (err, user) ->
            return res.send {status:"error", error:err} if err?
            return res.send {status:"error", error:"No dashboard for user: #{req.params.user}"} if !user? or !user.dashboard? or !user.dashboard.tabs?

            tab = _(user.dashboard.tabs).select (tab) -> tab.name == req.params.tab
            if _.isEmpty(tab)
                res.send {status:"error", error:"Could not find shared dashboard for user:#{req.params.user} with tabname:#{req.params.tab}"}
            else
                res.send {status:"ok", result:_.first(tab)}
