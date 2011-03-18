
Mongo = require("mongodb")
Db = Mongo.Db
Connection = Mongo.Connection
Server = Mongo.Server

async = require('async')

HOST = "localhost"
PORT = Connection.DEFAULT_PORT

db = new Db('qadash-db', new Server(HOST, PORT, {}), {native_parser:true})

reports = (cb) ->
    db.open (err,db) ->
        db.collection "reports", cb

targets_for_hw = (hw, cb) ->
    reports (err,col) ->
        col.distinct "target", {"hwproduct": hw}, cb

types_for_hw = (hw, target, cb) ->
    reports (err,col) ->
        col.distinct "testtype", {hwproduct: hw, target: target}, cb

groups_for_hw = (hw, cb) ->
    map_type = (typ, cb) ->
        cb null, {hwproduct:hw, target:target, testtype:typ}

    map_target = (target, cb) -> async.waterfall [
        async.apply(types_for_hw, hw, target),
        (err, types) -> async.map(types, map_type, cb) ]

    targets_for_hw hw, (err, targets) ->
        async.concat(targets, map_target, cb)

latest_for_group = (g, cb) -> async.waterfall \
    [reports
    ,(err,col) -> col.find g,
        sort: {"tested_at":-1}
        limit: 1
    ,(err, cur) ->
        cur.toArray
    ,(err, arr) ->arr[0]
    ], cb


exports.reports = reports
exports.targets_for_hw = targets_for_hw
exports.types_for_hw = types_for_hw
exports.groups_for_hw = groups_for_hw
exports.latest_for_group = latest_for_group

