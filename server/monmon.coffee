# Qa-Dashboard Database API

mongo   = require('mongodb')
_       = require('underscore')
async   = require('async')

EventEmitter = require('events').EventEmitter

# TODO: read these from configuration file
server = new mongo.Server("localhost", mongo.Connection.DEFAULT_PORT, {})

conn_pool = {}
connect = (dbname, callback) ->
    conn = conn_pool[dbname]
    if not conn?
        conn = new DBConnection(dbname)
        conn_pool[dbname] = conn
    conn.connect(callback)

class MongoMonad
    constructor: (cfg) ->
        @cfg = cfg ? {upsert: false, multi: false}

    _bind: (cfg) ->
        new_cfg = _.extend(_.clone(@cfg), cfg)
        new MongoMonad(new_cfg)

    env: (env) ->
        @_bind {env: env}

    use: (dbname) ->
        @_bind {dbname: dbname}

    collection: (collection) ->
        @_bind {collection: collection}

    find: (query) ->
        @_bind {find: query, cmd:"find"}

    skip: (num) ->
        @_bind {skip: num}

    limit: (num) ->
        @_bind {limit: num}

    fields: (keys) ->
        @_bind {fields: keys}

    sort: (keys) ->
        @_bind {sort: keys}

    count: ->
        @_bind {cmd: "count"}

    distinct: (keys) ->
        @_bind {distinct: keys, cmd: "distinct"}

    update: (doc) ->
        @_bind {update: doc, cmd:"update"}

    remove: (query) ->
        @_bind {remove: query, cmd: "remove"}

    drop: ->
        @_bind {cmd: "drop"}

    dropDatabase: ->
        @_bind {cmd: "dropDatabase"}

    upsert: (flag) ->
        @_bind {upsert: flag ? true}

    multi: (flag) ->
        @_bind {multi: flag ? true}

    insert: (doc) ->
        @_bind {insert: doc, cmd:"insert"}

    run: (callback) ->
        toArray = (err, cur) ->
            return callback? err if err?

            cur.toArray callback           

        @_run callback, toArray

    runCursor: (callback) ->
        @_run callback, callback

    _run: (cb, hc) ->
        cfg    = @cfg
        env    = cfg.env ? process.env.NODE_ENV
        dbname = cfg.dbname ? "qadash"
        monad  = this

        callback = (err, result) ->
            cb err, result, monad

        handle_cursor = (err, cur) ->
            console.log "handle_cursor"
            hc err, cur, monad

        commands =
            find: (err, c) ->
                return callback? err if err?

                opts = {}
                opts.skip   = cfg.skip   if cfg.skip?
                opts.limit  = cfg.limit  if cfg.limit?
                opts.sort   = cfg.sort   if cfg.sort?
                opts.fields = cfg.fields if cfg.fields?
                if cfg.find?
                    console.log "first #{handle_cursor}"
                    c.find cfg.find, opts, handle_cursor
                else
                    console.log "second"
                    c.find {}, opts, handle_cursor

            count: (err, c) ->
                return callback? err if err?

                if cfg.find?
                    c.count cfg.find, callback
                else
                    c.count callback

            distinct: (err, c) ->
                return callback? err if err?

                query = cfg.find ? {}
                key   = cfg.distinct
                if not key?
                    callback? "no key defined for distinct"
                else
                    c.distinct key, query, callback

            update: (err, c) ->
                return callback? err if err?

                query  = cfg.find
                sort   = cfg.sort ? []
                update = cfg.update ? null
                opts   = {}
                opts.upsert = cfg.upsert if cfg.upsert?
                c.update query, sort, update, opts, callback

            insert: (err, c) ->
                return callback? err if err?

                doc = cfg.insert
                c.insert doc, callback

            remove: (err, c) ->
                return callback? err if err?

                query = cfg.query ? {}

                c.remove query, callback

            drop: (err, c) ->
                return callback? err if err?

                c.drop callback


        connect "#{dbname}-#{env}", (err, db) ->
            return callback? err if err?

            cmd = cfg.cmd

            if cmd == "dropDatabase"
                return db.dropDatabase(callback)

            collection = cfg.collection
            if not collection?
                callback? "no collection defined for monmon operation"
            else
                db.collection collection, commands[cmd]
        
        return this    

class DBConnection
    constructor: (dbname) ->
        console.log "new dbconnection #{dbname}"
        @db         = new mongo.Db dbname, server, {native_parser:true}
        @db_is_open = false
        @open_event = new EventEmitter()
        @opening    = false

    connect: (callback) ->
        t = this
        if @db_is_open
            process.nextTick () ->
                callback? null, t.db
            return

        if @opening
            @open_event.once "connected", () ->
                callback? t.err, t.db
        else
            @opening = true
            @db.open (err, db) ->
                t.err = err
                if not err?
                    t.db_is_open = true
                t.open_event.emit("connected")
                callback? err, db
                t.opening = false

    close: ->
        @db?.close(->)


exports.monmon = new MongoMonad()
exports.connect = connect
