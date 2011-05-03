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

    name: "qa-reports"
    http:
        post:
            "/delete": (req, res) ->
                rid = req.body.report_id
                reports.find('report_id':rid)
            "/update": (req, res) ->
                doc = req.body.report
                if not doc? or not doc.report_id?
                    res.send {status:"error", error:"invalid request format"}
                else
                    q = reports.find({'report_id':doc.report_id}).upsert().update(doc)
                    q.run (err) ->
                        if err?
                            res.send {status:"error", error:err}
                        else
                            res.send {status:"ok"}
