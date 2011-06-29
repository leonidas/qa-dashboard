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

    reports.unique().ensureIndex([['qa_id',1]]).run()
    reports.ensureIndex([["release",-1], ["hardware",1], ["profile","1"], ["testtype",1]]).run()


    api = {}

    api.reports_for_bug = (hw, id, cb) ->
        id = parseInt id
        fields =
            qa_id:1
            title:1
            profile:1
            hardware:1
            testtype:1
            release:1
            features:1
        api.latest_reports 1, hw, fields, (err, arr) ->
            return cb? err if err?
            has_bug = (r) ->
                for f in r.features
                    for c in f.cases
                        if id in c.bugs
                            return true
                return false

            count_cases = (cases) ->
                fail_num = 0
                na_num = 0
                for c in cases
                    if id in c.bugs
                        if c.result == -1
                            fail_num += 1
                        if c.result == 0
                            na_num += 1

                fail_count: fail_num
                na_count: na_num

            format_feature = (fea) ->
                doc = {}
                doc.name = fea.name
                cases = count_cases(fea.cases)
                doc.fail_cases = cases.fail_count
                doc.na_cases   = cases.na_count
                doc.qa_id      = fea.qa_id
                return doc

            reformat = (r) ->
                doc = {}
                doc.url = "http://qa-reports.meego.com/#{r.release}/#{r.profile}/#{r.testtype}/#{r.hardware}/#{r.qa_id}"
                doc.title = r.title
                features = _(r.features).map format_feature
                doc.features =_(features).filter (f) -> f.fail_cases > 0 or f.na_cases > 0
                return doc

            arr = _(arr).filter has_bug
            cb? null,_(arr).map reformat

    api.targets_for_hw = (ver, hw, callback) ->
        q = reports.find(release:ver,hardware:hw).distinct "profile"
        q.run callback

    api.types_for_hw = (ver, hw) -> (profile, callback) ->
        q = reports.find(release:ver,hardware:hw,profile:profile)
        q = q.distinct "testtype"
        q.run callback

    api.groups_for_hw = (ver, hw) -> (callback) ->
        api.targets_for_hw ver, hw, (err, targets) ->
            return callback? err if err?
            async.map targets, api.types_for_hw(ver, hw), (err, types) ->
                return callback? err if err?

                result = []
                for [target,typs] in _.zip(targets,types)
                    for type in typs
                        result.push
                            release:ver
                            profile:target
                            testtype:type
                            hardware:hw

                callback? null, result

    api.latest_for_group = (n, fields) -> (grp, callback) ->
        fields ?=
            hardware:1
            profile:1
            testtype:1
            release:1
            tested_at:1
            total_cases:1
            total_pass:1
            total_fail:1
            total_na:1
            qa_id:1
            tested_at:1
            title:1
        q = reports.find(grp).fields(fields).sort(tested_at:-1,created_at:-1).limit(n)
        q.run (err, arr) ->
            return callback? err if err?
            arr = arr[0] if n == 1
            callback? null, arr

    api.all_releases = (callback) ->
        reports.distinct("release").run callback

    api.hws_for_release = (ver, callback) ->
        reports.find({release:ver}).distinct("hardware").run callback

    api.hw_groups_for_release = (ver) -> (callback) ->
        api.hws_for_release ver, (err, arr) ->
            return callback? err if err?
            hws = {}
            for hw in arr
                hws[hw] = api.groups_for_hw ver, hw
            async.parallel hws, callback

    api.all_groups = (callback) ->
        api.all_releases (err, arr) ->
            return callback? err if err?
            releases = {}
            for v in arr
                releases[v] = api.hw_groups_for_release(v)
            async.parallel releases, callback

    api.latest_reports = (n, ver, hw, fields, callback) ->
        api.groups_for_hw(ver, hw) (err, groups) ->
            if not callback?
                callback = fields
                fields = null
            return callback? err if err?
            async.map groups, api.latest_for_group(n,fields), callback

    name: "qa-reports"
    api: api
    http: get:
        "/for_bug/:id/:hw": (req,res) ->
            api.reports_for_bug req.params.hw, req.params.id, (err, arr) ->
                res.send arr

        "/latest/:hw": (req,res) ->
            num = parseInt(req.param("num") ? "1")
            api.latest_reports num, "1.2", req.params.hw, (err,arr) ->
                if err?
                    console.log err
                    res.send 500
                else
                    res.send arr

        "/latest/:ver/:hw": (req, res) ->
            num = parseInt(req.param("num") ? "1")
            api.latest_reports num, req.params.ver, req.params.hw, (err,arr) ->
                if err?
                    console.log err
                    res.send 500
                else
                    res.send arr

        "/groups/:hw": (req,res) ->
            api.groups_for_hw("1.2", req.params.hw) (err,arr) ->
                if err?
                    console.log err
                    res.send 500
                else
                    res.send arr

        "/groups": (req, res) ->
            api.all_groups (err,arr) ->
                if err?
                    console.log err
                    res.send 500
                else
                    res.send arr
