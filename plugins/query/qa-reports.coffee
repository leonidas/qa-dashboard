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
_     = require('underscore')

exports.register_plugin = (db) ->
    reports = db.collection('qa-reports')

    api = {}

    api.targets_for_hw = (hw, callback) ->
        q = reports.find({version:"1.2", hwproduct:hw}).distinct "target"
        q.run callback

    api.types_for_hw = (hw) -> (target, callback) ->
        q = reports.find({version:"1.2",hwproduct:hw,target:target})
        q = q.distinct "testtype"
        q.run callback

    api.groups_for_hw = (hw, callback) ->
        api.targets_for_hw hw, (err, targets) ->
            return callback? err if err?
            async.map targets, api.types_for_hw(hw), (err, types) ->
                return callback? err if err?

                result = []
                for [target,typs] in _.zip(targets,types)
                    for type in typs
                        result.push
                            version:"1.2"
                            target:target
                            testtype:type
                            hwproduct:hw

                callback? null, result

    api.latest_for_group = (grp, fields, callback) ->
        if not callback?
            callback = fields
            fields =
                hwproduct:1
                target:1
                testtype:1
                version:1
                total_cases:1
                total_pass:1
                total_fail:1
                total_na:1
                qa_id:1
        q = reports.find(grp).fields(fields).sort({tested_at:-1}).one()
        q.run callback

    api.latest_reports = (hw, fields, callback) ->
        api.groups_for_hw hw, (err, groups) ->
            return callback? err if err?
            if not callback?
                callback = fields
                async.map groups, api.latest_for_group, callback
            else
                f = (grp, cb) -> api.latest_for_group grp, fields, cb
                async.map groups, f, callback


    name: "qa-reports"
    api: api
    http: get:
        "/latest/:hw": (req,res) ->
            api.latest_reports req.params.hw, (err,arr) ->
                res.send arr

        "/groups/:hw": (req,res) ->
            api.groups_for_hw req.params.hw, (err,arr) ->
                res.send arr
