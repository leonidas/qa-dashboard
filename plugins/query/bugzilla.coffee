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

    # TODO: We will eventually need to support multiple Bugzilla servers
    # -> bug_id cannot be unique
    bugs.ensureIndex    "bug_id", unique: true, ->
    reports.ensureIndex "features.cases.bugs", sparse: true, ->

    merge_counts = (c1, c2) ->
        merged = {}
        merge  = (arr) ->
            for id, item of arr
                if merged[id]?
                    merged[id]['count'] += item.count
                else
                    merged[id] = item
        merge c1
        merge c2
        return merged


    api.bug_counts_for_group = (grp) -> (cb) ->
        reports_api = plugins.api.query['qa-reports']
        fields = "features.cases.bugs":1
        reports_api.latest_for_group(1, fields) grp, (err, r) ->
            return cb? err if err?

            bugcounts = {}
            if r?
                for fea in r.features
                    for c in fea.cases
                        for b in c.bugs
                            # We're only interested in items that are coming
                            # from Bugzilla. QA Reports has other types as well.
                            if b.type == 'bugzilla'
                                key = "#{b.prefix}##{b.id}"
                                bugcounts[key] ?=
                                    count:  0
                                    id:     b.id
                                    url:    b.url
                                bugcounts[key]['count'] += 1

            cb? null, bugcounts

    api.bug_counts_for_groups = (grps, cb) ->
        queries = _(grps).map api.bug_counts_for_group
        async.parallel queries, (err, res) ->
            return cb? err if err?
            cb? null, _(res).reduce merge_counts, {}


    api.bugs_by_ids = (ids, cb) ->
        bugs.find(bug_id: $in: ids).toArray (err, arr) ->
            return cb err if err?
            bugobjs = {}
            for item in arr
                bugobjs[item.bug_id] = item
            cb null, bugobjs

    api.top_bugs_for_groups = (grps, num, cb) ->
        api.bug_counts_for_groups grps, (err, counts) ->
            return cb? err if err?
            ids = _.keys counts

            # Fetch the bugs from bugs collection (descriptions etc.)
            api.bugs_by_ids ids, (err, bugs) ->
                step = (memo,value,prefixed_id) ->
                    b = bugs[prefixed_id]
                    # Skip resolved bugs in blockers
                    if not b? or not b.resolution? or b.resolution == '---'
                        memo.push [value.count, value.id, value.url, b]
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
