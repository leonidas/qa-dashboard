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
async = require('async')

exports.register_plugin = (db) ->
    bugreports = db.collection('bugs')
    name: "bugs"
    http:
        post: "/update": (req, res) ->
            doc = req.body
            async.map doc.bugs,
                # parse bugreport and return the db query function
                (bug, cb) ->
                    # do parsing and format checking here
                    if not bug.bug_id?
                        err = "invalid document format"
                        cb err, null
                    else
                        cb null, (callback) ->
                            bugreports.update {bug_id: bug.bug_id}, bug, true, (err) ->
                                if err?
                                    callback err, null
                                else
                                    callback null, null
                (err, q_arr) ->
                    if err?
                        res.send {status: "error", error: err} #parse error
                    else
                        # run database queries
                        async.series q_arr, (err) ->
                            if err?
                                res.send {status: "error", error: err } #error in db query
                            else
                                res.send {status: "ok"}




