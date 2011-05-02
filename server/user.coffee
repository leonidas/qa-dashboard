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

auth = require('authentication')

get_user = (db) ->
    users = db.collection("users")
    (username) ->
        query = users.find({username:username}).one()
        (callback) ->
            query.run (err, user) ->
                return callback? err, user if err? or user?
                doc =
                    username: username
                    dashboard: {}
                users.insert(doc).run (err) ->
                    return callback? err if err?
                    callback? doc

exports.init_user = (app, db) ->
    users = db.collection("users")

    token = auth.get_token db

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
            q = users.find({username:username}).fields({dashboard:1}).one()
            q.run (err, user) ->
                console.log "ERROR: #{err}" if err?
                res.send user.dashboard

    app.post "/user/dashboard/save", (req, res) ->
        username = req.session.username
        q = users.find({username:username}).update $set: dashboard: req.body
        q.run (err) ->
            if err
                res.send {status:"error", error:err}
            else
                res.send {status:"OK"}
