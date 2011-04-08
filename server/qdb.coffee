# Qa-Dashboard Database API

mongo   = require('mongodb')
process = require('process')
events  = require('events')
_       = require('underscore')
async   = require('async')

# TODO: read these from configuration file
server = new Server("localhost", Connection.DEFAULT_PORT, {})

example = ->
    monmon.env("production")
          .use("qadash")
          .collection("reports")
          .find(
            version:   "1.2"
            hwproduct: hw
            target:    target )
          .distinct("testtype")

conn_pool = {}

class MongoMonad
    initialize: (cfg) ->
        @cfg = cfg ? {}

    _bind: (cfg) ->
        new_cfg = _.extend(_.clone(@cfg), cfg)
        new MongoMonad(new_cfg)

    env: (env) ->
        _bind {env: env}

    use: (dbname) ->
        _bind {dbname: dbname}

    collection: (collection) ->
        _bind {collection: collection}

    find: (keys) ->
        _bind {find: keys, cmd:"find"}

    skip: (num) ->
        _bind {skip: num}

    limit: (num) ->
        _bind {limit: num}

    fields: (keys) ->
        _bind {fields: keys}

    sort: (keys) ->
        _bind {sort: keys}

    count: ->
        _bind {cmd: "count"}

    distinct: (keys) ->
        _bind {cmd: "distinct"}

    group: (rule) ->
        _bind {group: rule}

    update: (doc) ->
        _bind {update: doc, cmd:"update"}

    upsert: (flag) ->
        _bind {upsert: flag ? true}

    multi: (flag) ->
        _bind {multi: flag ? true}

    insert: (doc) ->
        _bind {insert: doc, cmd:"insert"}

    run: (callback) ->
        cfg    = cfg
        env    = cfg.env ? process.env.NODE_ENV
        dbname = cfg.dbname ? "qadash"

        commands =
            find: (err, c) ->
                callback? err if err?

            count: (err, c) ->
                callback? err if err?

            distinct: (err,c) ->
                callback? err if err?

            update: (err, c) ->
                callback? err if err?

            insert: (err, c) ->
                callback? err if err?

        connect "#{dbname}-#{env}", (err, db) ->
            callback? err if err?
            collection = cfg.collection
            if not collection?
                callback? "no collection defined for monmon operation"
            else
                db.collection collection, commands[cfg.cmd]
            

connect (env, callback) ->
    conn = conn_pool[env]
    if not conn?
        conn = new DBConnection(env)
        conn_pool[env] = conn
    conn.connect(callback)

class DBConnection
    initialize: (env) ->
        env ?= process.env.NODE_ENV
        @db = new mongo.Db "qadash-#{env}", server, {native_parser:true}
        @db_is_open    = false

    connect: (callback) ->
        callback @db if @db_is_open
        if @open_event?
            @open_event.on "connected", =>
                callback? null, @db
        else
            @open_event = new events.EventEmitter()
            @db.open (err, db) =>
                callback? err if err?
                @db_is_open = true
                @open_event.emit("connected")
                callback? null, @db

    collection: (name) ->
        new DBCollection(this, name)

    close: ->
        @db?.close()

class DBCollection
    initialize: (@conn, @name) ->

    
