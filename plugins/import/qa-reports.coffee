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

exports.register_plugin = (db) ->
    reports = db.collection('qa-reports')
    async   = require('async')

    valid_request_format = (doc,res) ->
        if not doc? or not doc.qa_id?
            res.send {status:"error", error:"invalid request format"}
            false
        else
            true

    name: "qa-reports"
    http:
        post:
            "/delete": (req, res) ->
                doc = req.body.report
                return if not valid_request_format(doc,res)

                reports.remove qa_id: doc.qa_id, (err) ->
                    return res.send status: "error", error: err if err?
                    res.send status: 'ok'

            "/update": (req, res) ->
                doc = req.body.report
                return if not valid_request_format(doc,res)

                reports.findOne qa_id: doc.qa_id, (err, old) ->
                    return res.send status: "error", error: err if err?

                    if not old? || (new Date(doc.updated_at) >= new Date(old.updated_at))
                        reports.update {qa_id: doc.qa_id}, doc, true, (err) ->
                            return res.send status: "error", error: err if err?
                            res.send status: 'ok'
                    else
                        res.send {status:"ok", msg:"ignored, more recent report found in db"}

            "/massupdate": (req, res) ->
                doc = req.body.reports
                async.map doc,
                    # parse qa-reports and return the db query function
                    (report, cb) ->
                        # do parsing and format checking here
                        if not report.qa_id?
                            err = "invalid document format"
                            cb err, null
                        else
                            cb null, (callback) ->
                                reports.findOne qa_id: report.qa_id, (err, old) ->
                                    return callback err, null if err?

                                    if not old? || (new Date(report.updated_at) >= new Date(old.updated_at))
                                        reports.update {qa_id: report.qa_id}, report, true, callback
                    (err, q_arr) ->
                        return res.send status: 'error', error: err if err?
                        # run database queries
                        async.series q_arr, (err) ->
                            return res.send status: 'error', error: err if err?
                            res.send status: 'ok'

