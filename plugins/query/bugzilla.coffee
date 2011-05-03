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
    async   = require('async')
    _       = require('underscore')
    plugins = require('plugins')


    reports = db.collection('qa-reports')
    bugs    = db.collection('bugs')

    api = {}

    merge_counts = (c1, c2) ->
        merged = {}
        for b,c of c1
            merged[b] = (merged[b] ? 0) + c
        for b,c of c2
            merged[b] = (merged[b] ? 0) + c
        return merged


    api.bug_counts_for_group = (grp) -> (cb) ->
        reports_api = plugins.api.query['qa-reports']
        reports_api.latest_for_group grp, {"features.cases.bugs":1}, (err, r) ->
            return cb? err if err?

            bugcounts = {}
            for fea in r.features
                for c in fea.cases
                    for b in c.bugs
                        bugcounts[b] = (bugcounts[b] ? 0) + 1

            cb? null, bugcounts

    api.bug_counts_for_groups = (grps, cb) ->
        queries = _(grps).map api.bug_counts_for_group
        async.parallel queries, (err, res) ->
            return cb? err if err?
            cb? null, _(res).reduce merge_counts


    api.bugs_by_ids = (ids, cb) ->
        bugs.find({"bug_id":{$in:ids}}).run (err,arr) ->
            return cb err if err?
            bugobjs = {}
            for item in arr
                bugobjs[item.bug_id] = item
            cb null, bugobjs

    api.top_bugs_for_groups = (grps, num, cb) ->
            api.bug_counts_for_groups grps, (err, counts) ->
                return cb? err if err?

                ids = _.keys counts
                api.bugs_by_ids ids, (err, bugs) ->
                    step = (memo,v,k) ->
                        b = bugs[k]
                        if not b? or not b.resolution? or b.resolution == '---'
                            memo.push [v,k,b]
                        return memo
                    bugcount = _.reduce counts, step, []
                    bugcount = _(bugcount).sortBy (x) -> x[0]
                    bugcount.reverse()
                    bugcount = bugcount.slice(0,num)
                    cb? null, bugcount

    name: "bugzilla"
    api: api
    http: post: "/top_for_groups": (req, res) ->
        body   = req.body
        groups = body.groups
        num    = body.num
        api.top_bugs_for_groups groups, num, (err, bugs) ->
            if err?
                console.log err
                res.send 500
            else
                res.send bugs
