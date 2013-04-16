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

    reports.ensureIndex {qa_id: 1}, {unique: true}, ->
    reports.ensureIndex {release: -1, product: 1, profile: 1}, {sparse: true}, ->
    reports.ensureIndex {testset: 1}, {sparse: true}, ->

    qa_reports_url = ""
    read_settings  = (settings) ->
        qa_reports_url = settings['qa-reports']['url'].replace /\/$/, ''

    api = {}

    # TODO this is not used? Does not work now due to latest_reports change
    api.reports_for_bug = (product, id, cb) ->
        id = parseInt id
        fields =
            qa_id:      1
            title:      1
            profile:    1
            product:    1
            testset:    1
            release:    1
            features:   1
        api.latest_reports 1, product, fields, (err, arr) ->
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
                doc.url = "#{qa_reports_url}/#{r.release}/#{r.profile}/#{r.testset}/#{r.product}/#{r.qa_id}"
                doc.title = r.title
                features = _(r.features).map format_feature
                doc.features =_(features).filter (f) -> f.fail_cases > 0 or f.na_cases > 0
                return doc

            arr = _(arr).filter has_bug
            cb? null,_(arr).map reformat

    api.targets_for_product = (ver, product, callback) ->
        reports.distinct 'profile', {release: ver, product: product}, callback

    api.types_for_product = (ver, product) -> (profile, callback) ->
        reports.distinct 'testset', {release: ver, product: product, profile: profile}, callback

    api.report_groups = (release, profile, testset, product) -> (callback) ->
        filter_row = (row) ->
            r = not release? || release == row.release
            p = not profile? || profile == row.profile
            t = not testset? || testset == row.testset
            h = not product? || product == row.product
            return r && p && t && h

        # There really isn't that many groups that we couldn't just fetch all
        # (because a methods exists) and then filter those.
        api.all_groups (err, groups) ->
            return callback? err if err?
            callback? null, _.filter(groups, filter_row)

    api.latest_for_group = (n, fields) -> (grp, callback) ->
        fields ?=
            product:    1
            profile:    1
            testset:    1
            release:    1
            tested_at:  1
            total_cases:1
            total_pass: 1
            total_fail: 1
            total_na:   1
            qa_id:      1
            tested_at:  1
            title:      1

        reports.find(grp, fields).sort(tested_at: -1, created_at: -1).limit(n).toArray (err, arr) ->
            return callback? err if err?
            arr = _.map arr, (r) -> r.url = "#{qa_reports_url}/#{r.release}/#{r.profile}/#{r.testset}/#{r.product}/#{r.qa_id}"; r
            arr = arr[0] if n == 1
            callback? null, arr

    api.all_releases = (callback) ->
        reports.distinct 'release', callback

    api.all_profiles = (callback) ->
        reports.distinct 'profile', callback

    api.products_for_release = (ver, callback) ->
        reports.distinct 'product', {release: ver}, callback

    api.sets = (release, profile, cb) ->
        reports.distinct 'testset', release: release, profile: profile, cb

    api.products = (release, profile, testset, cb) ->
        reports.distinct 'product', release: release, profile: profile, testset: testset, cb

    # api.product_groups_for_release = (ver) -> (callback) ->
    #     api.products_for_release ver, (err, arr) ->
    #         return callback? err if err?
    #         products = {}
    #         for product in arr
    #             products[product] = api.groups_for_product ver, product
    #         async.parallel products, callback

    # Get all unique groups for given release/profile/testset combination
    api.group_rows_for = (release, profile, testset) -> (cb) ->
        api.products release, profile, testset, (err, arr) ->
            return cb? err if err?

            rows = []
            for product in arr
                row =
                    release: release
                    profile: profile
                    testset: testset
                    product: product
                rows.push row
            cb? null, rows

    # Get all unique groups for given release/profile combination (gets the
    # sets first and then for each set the products)
    api.sets_for_release_profile = (release, profile) -> (cb) ->
        api.sets release, profile, (err, arr) ->
            return cb? err if err?

            products = []
            for testset in arr
                products.push api.group_rows_for release, profile, testset
            async.parallel products, cb


    # Return a flat list of all existing release/target/testset/product
    # combinations, i.e. single item in list is:
    # {release: '', profile: '', testset: '', product: ''}
    api.all_groups = (callback) ->
        async.parallel [
            api.all_releases
            api.all_profiles
        ], (err, results) ->
            return callback? err if err?

            releases = results[0]
            profiles = results[1]

            groups = []
            # Now collect the data
            for r in releases
                for p in profiles
                    groups.push api.sets_for_release_profile r, p

            async.parallel groups, (err, arr) ->
                return callback? err if err?
                arr = _.flatten arr
                return callback? null, arr

    api.latest_reports = (n, release, profile, testset, product, fields, callback) ->
        [fields, callback] = [null, fields] if typeof fields == 'function'

        release = null if release == 'Any'
        profile = null if profile == 'Any'
        testset = null if testset == 'Any'
        product = null if product == 'Any'

        api.report_groups(release, profile, testset, product) (err, groups) ->
            return callback? err if err?
            async.map groups, api.latest_for_group(n, fields), callback

    name: "qa-reports"
    api: api
    http: get:
        "/for_bug/:id/:product": (req,res) ->
            api.reports_for_bug req.params.product, req.params.id, (err, arr) ->
                res.send arr

        # "/latest/:product": (req,res) ->
        #     num = parseInt(req.param("num") ? "1")
        #     api.latest_reports num, "1.2", req.params.product, (err,arr) ->
        #         if err?
        #             console.log err
        #             res.send 500
        #         else
        #             res.send arr

        "/latest/:release/:profile/:testset/:product": (req, res) ->
            num = parseInt(req.param("num") ? "1")
            api.latest_reports num, req.params.release, req.params.profile, req.params.testset, req.params.product, (err,arr) ->
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

        "/url": (req, res) ->
            res.send url: qa_reports_url

    set_settings: read_settings
