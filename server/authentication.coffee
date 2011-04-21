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

authenticate = (username, password) -> (callback) ->
    ok = username == "guest" and password == "guest"
    callback? null, ok

exports.init_authentication = (app, db) ->
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

