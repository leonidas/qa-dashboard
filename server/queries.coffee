
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

targets_for_hw = (hw, cb) ->
    reports (err,col) ->
        col.distinct "target", {hwproduct: hw}, cb

types_for_hw = (hw, target, cb) ->
    reports (err,col) ->
        col.distinct "testtype", {hwproduct: hw, target: target}, cb

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
        total_cases:1
        total_pass:1
        total_fail:1
        total_na:1

    async.waterfall \
    [reports
    ,(col, cb) ->
        col.find g, fields, { sort: {"tested_at":-1}, limit: 1 }, cb
    ,(cur, cb) ->
        cur.toArray(cb)
    ,(arr) ->
        cb arr[0]
    ]


exports.reports = reports
exports.targets_for_hw = targets_for_hw
exports.types_for_hw = types_for_hw
exports.groups_for_hw = groups_for_hw
exports.latest_for_group = latest_for_group

