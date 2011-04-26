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

exports.init_user = (app, db) ->
    users = db.collection("users")

    # initialize dummy user
    dummy =
        username:'guest'
        dashboard: {}

    users.find(username:'guest').upsert().update(dummy).run()

    token = auth.get_token db

    app.get "/user", (req, res) ->
        username = req.session.username
        if not username?
            res.send {}
        else
            q = users.find({username:username}).one()
            q.run (err, user) ->
                console.log "ERROR: #{err}" if err?
                res.send user

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
