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

Mongo = require("mongodb")
Db = Mongo.Db
Connection = Mongo.Connection
Server = Mongo.Server

async = require('async')
_ = require('underscore')

HOST = "localhost"
PORT = Connection.DEFAULT_PORT

db = new Db('qadash-db', new Server(HOST, PORT, {}), {native_parser:true})


reports = (cb) ->
    db.collection "reports", cb

widgets = (cb) ->
    db.collection "widgets", cb

users = (cb) ->
    db.collection "users", cb

bugs = (cb) ->
    db.collection "bugs", cb

init_indexes = ->
    reports (err,col) ->
        col.ensureIndex [["qa_id",1]], true, (->)
        col.ensureIndex [["version",1], ["hwproduct",1], ["target","1"], ["testtype",1], ["tested_at",-1]], false, (->)

    users (err, col) ->
        col.ensureIndex [["username",1]], true, (->)

    bugs (err, col) ->
        col.ensureIndex [["bug_id",1]], true, (->)


targets_for_hw = (hw, cb) ->
    reports (err,col) ->
        col.distinct "target", {version:"1.2", hwproduct: hw}, cb

types_for_hw = (hw, target, cb) ->
    reports (err,col) ->
        col.distinct "testtype",
            {version:"1.2", hwproduct: hw, target: target}, cb

groups_for_hw = (hw, cb) ->

    map_target = (target, cb) ->
        map_type = (typ, cb) ->
            cb null, {version:"1.2", hwproduct:hw, target:target, testtype:typ}
        async.waterfall [
            async.apply(types_for_hw, hw, target),
            (types) ->
                async.map(types, map_type, cb) ], cb

    targets_for_hw hw, (err, targets) ->
        async.concat(targets, map_target, cb)

latest_for_group = (g, fields, cb) ->
    if cb == undefined
        cb = fields
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

    reports (err, col) ->
        col.find g, fields, { sort: {"tested_at":-1}, limit: 1 }, (err, cur) ->
            cur.toArray (err, arr) ->
                report = arr[0]
                report.pass_target = 80
                cb null, report


latest_reports = (hw, fields, cb) ->
    groups_for_hw hw, (err, groups) ->
        if cb == undefined
            cb = fields
            async.map groups, latest_for_group, cb
        else
            f = (g, cb) -> latest_for_group g, fields, cb
            async.map groups, f, cb



bug_counts = (hw, cb) ->
    reports (err,col) ->
        col.find {hwproduct:hw}, {"features.cases.bugs":1}, (err,cur) ->
            cur.toArray (err,arr) ->
                bugcount = {}
                _.each arr, (item) ->
                    _.each item.features, (feat)->
                        _.each feat.cases, (tc) ->
                            _.each tc.bugs, (bug) ->
                                bugcount[bug] = (bugcount[bug] or 0) + 1
                cb null, bugcount

bugs_by_ids = (ids, cb) ->
    bugs (err,col) ->
        col.find {"bug_id":{$in:ids}}, (err,cur) ->
            bugobjs = {}
            cur.toArray (err,arr) ->
                _.each arr, (item) ->
                    bugobjs[item.bug_id] = item
                cb null, bugobjs

latest_bug_counts = (hw,cb) ->
    latest_reports hw, {"features.cases.bugs":1}, (err,arr) ->
        bugcount = {}
        _.each arr, (item) ->
            _.each item.features, (feature) ->
                _.each feature.cases, (tc) ->
                    _.each tc.bugs, (bug) ->
                        bugcount[bug] = (bugcount[bug] or 0) + 1
        ids = _.keys bugcount
        bugs_by_ids ids, (err, bugs) ->
            step = (memo,v,k) ->
                b = bugs[k]
                if b == undefined
                    memo.push [v,k,b]
                    return memo
                if b.resolution == null
                    memo.push [v,k,b]
                    return memo
                return memo
            bugcount = _.reduce bugcount, step, []
            bugcount.sort()
            bugcount.reverse()
            cb err, bugcount

db.open init_indexes

exports.reports = reports
exports.targets_for_hw = targets_for_hw
exports.types_for_hw = types_for_hw
exports.groups_for_hw = groups_for_hw
exports.latest_for_group = latest_for_group
exports.latest_reports = latest_reports

exports.latest_bug_counts = latest_bug_counts
