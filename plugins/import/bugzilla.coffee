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
_  = require('underscore')

exports.register_plugin = (db) ->
    bugreports = db.collection('bugs')
    name: "bugs"
    http:
        post: "/update": (req, res) ->
            doc = req.body
            #console.log(doc) #debug
            _.each doc.bugs, (bug) ->
                if not bug.bug_id?
                    #res.send {status:"error", error:"invalid document format"}
                    #TODO: needs a break statement or some other way
                else
                    #console.log "bug received with id: " + bug.bug_id #debug
                    q = bugreports.find({'bug_id':bug.bug_id}).upsert().update(bug)
                    q.run (err) ->
                        if err?
                            error = {status:"error", error:err}
            if error?
                res.send error
            else
                res.send {status:"ok"}

