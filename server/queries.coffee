
Mongo = require("mongodb")
Db = Mongo.Db
Connection = Mongo.Connection
Server = Mongo.Server

async = require('async')

HOST = "localhost"
PORT = Connection.DEFAULT_PORT

db = new Db('qadash-db', new Server(HOST, PORT, {}), {native_parser:true})
db.open(->)

reports = (cb) ->
    db.collection "reports", cb

widgets = (cb) ->
    db.collection "widgets", cb

users = (cb) ->
    db.collection "users", cb

targets_for_hw = (hw, cb) ->
    reports (err,col) ->
        col.distinct "target", {hwproduct: hw, version:"1.2"}, cb

types_for_hw = (hw, target, cb) ->
    reports (err,col) ->
        col.distinct "testtype", {hwproduct: hw, target: target, version:"1.2"}, cb

groups_for_hw = (hw, cb) ->

    map_target = (target, cb) ->
        map_type = (typ, cb) ->
            cb null, {hwproduct:hw, target:target, testtype:typ}
        async.waterfall [
            async.apply(types_for_hw, hw, target),
            (types) ->
                async.map(types, map_type, cb) ], cb

    targets_for_hw hw, (err, targets) ->
        async.concat(targets, map_target, cb)

latest_for_group = (g, cb) ->
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


latest_reports = (hw, cb) ->
    groups_for_hw hw, (err, groups) ->
        async.map groups, latest_for_group, cb


widget_config = (wgt, cb) ->
    widgets (err,col) ->
        col.find {widget:wgt}, (err, cur) ->
            if err
                cb err, {}
            else
                cur.nextObject(cb)

user_dashboard = (uname, cb) ->
    users (err,col) ->
        col.find {username:uname}, {dashboard:1}, (err, cur) ->
            cur.nextObject (err, obj) ->
                if err
                    cb err, {left_col:[], sidebar:[]}
                else
                    cb null, obj.dashboard

save_dashboard = (uname, dashb, cb) ->
    users (err,col) ->
        col.update {username:uname}, {$set: {dashboard:dashb}}, cb

exports.reports = reports
exports.targets_for_hw = targets_for_hw
exports.types_for_hw = types_for_hw
exports.groups_for_hw = groups_for_hw
exports.latest_for_group = latest_for_group
exports.latest_reports = latest_reports

exports.widget_config = widget_config

exports.user_dashboard = user_dashboard
exports.save_dashboard = save_dashboard


