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

# Qa-Dashboard Database API

mongo   = require('mongodb')
_       = require('underscore')
async   = require('async')

EventEmitter = require('events').EventEmitter

ObjectID = null

conn_pool = {}
connect = (dburl, callback) ->
    conn = conn_pool[dburl]
    if not conn?
        conn = new DBConnection(dburl)
        conn_pool[dburl] = conn
    conn.connect(callback)

class Action
    constructor: (@monad) ->

    set_callback: (new_callback, toArray) ->
        new_act = new Action(@monad)
        new_act.callback = new_callback
        new_act.toArray  = toArray
        return new_act

class MongoMonad
    constructor: (cfg, acts) ->
        @cfg  = cfg ? {upsert: false, multi: false}
        @acts = acts ? []

    _bind: (cfg) ->
        new_cfg = _.extend(_.clone(@cfg), cfg)
        new MongoMonad(new_cfg, @acts)

    _bind_action: (cfg) ->
        new_monad      = @_bind(cfg)
        action         = new Action(new_monad)
        acts           = _.clone(@acts)
        new_monad.acts = acts.concat [action]
        return new_monad._bind {cmd:null}

    _bind_callback: (callback, toArray) ->
        acts = _.clone(@acts)
        last = acts[acts.length-1]
        if not last? or last.callback?
            throw "do() without any actions"
        acts[acts.length-1] = last.set_callback(callback, toArray)
        new MongoMonad(@cfg, acts)

    mkID: (s) -> new ObjectID(s)

    env: (env) ->
        @_bind {env: env}

    use: (dbname) ->
        @_bind {dbname: dbname}

    connect: (dburl) ->
        @_bind {dburl: dburl}

    collection: (collection) ->
        @_bind {collection: collection}

    find: (query) ->
        @_bind {find: query, cmd:"find"}

    one: () ->
        @_bind {cmd:"findOne"}

    skip: (num) ->
        @_bind {skip: num}

    limit: (num) ->
        @_bind {limit: num}

    fields: (keys) ->
        @_bind {fields: keys}

    sort: (keys) ->
        @_bind {sort: keys}

    count: () ->
        @_bind {cmd: "count"}

    distinct: (keys) ->
        @_bind {distinct: keys, cmd: "distinct"}

    update: (doc) ->
        @_bind_action {update: doc, cmd:"update"}

    remove: () ->
        @_bind_action {cmd: "remove"}

    drop: () ->
        @_bind_action {cmd: "drop"}

    dropDatabase: ->
        @_bind_action {cmd: "dropDatabase"}

    upsert: (flag) ->
        @_bind {upsert: flag ? true}

    multi: (flag) ->
        @_bind {multi: flag ? true}

    safe: (flag) ->
        @_bind {safe: flag ? true}

    insert: (doc) ->
        @_bind_action {insert: doc, cmd:"insert"}

    ensureIndex: (key) ->
        @_bind_action {key:key, cmd:"ensureIndex"}

    unique: (flag) ->
        @_bind {unique: flag ? true}

    sparse: (flag) ->
        @_bind {sparse: flag ? true}

    dropDups: (flag) ->
        @_bind {dropDups: flag ? true}

    do: (callback) ->
        if @cfg.cmd == 'find'
            m = @_bind_action {}
        else
            m = this
        m._bind_callback callback, true

    doCursor: (callback) ->
        if @cfg.cmd == 'find' or @cfg.cmd == 'findOne'
            m = @_bind_action {}
        else
            m = this
        m._bind_callback callback, false

    run: (callback) ->
        @_run_all(callback)

    _run_all: (callback) ->
        if @cfg.cmd?
            m = @_bind_action {}
            m.acts[m.acts.length-1].toArray = true
        else
            m = this

        last_result = null
        runAct = (act, cb) ->
            act.monad._run act.toArray, (err, result, monad) ->
                last_result = result
                act.callback?(err, result, monad)
                cb err

        async.forEachSeries m.acts, runAct, (err) ->
            callback? err, last_result, this

        return

    _run: (toArray, cb) ->
        cfg    = @cfg
        env    = cfg.env ? process.env.NODE_ENV ? "development"
        dburl  = cfg.dburl ? "mongodb://localhost:27017/#{cfg.dbname}-#{env}"
        monad  = this

        callback = (err, result) ->
            cb? err, result, monad

        cursor_callback = (err, result) ->
            if cb?
                if toArray
                    result.toArray (err, arr) ->
                        cb err, arr, monad
                else
                    cb err, result, monad

        commands =
            find: (err, c) ->
                return callback? err if err?

                opts = {}
                opts.skip   = cfg.skip   if cfg.skip?
                opts.limit  = cfg.limit  if cfg.limit?
                opts.sort   = cfg.sort   if cfg.sort?
                opts.fields = cfg.fields if cfg.fields?
                if cfg.find?
                    c.find fix_id(cfg.find), opts, cursor_callback
                else
                    c.find {}, opts, cursor_callback

            findOne: (err, c) ->
                return callback? err if err?

                opts = {}
                opts.skip   = cfg.skip   if cfg.skip?
                opts.limit  = cfg.limit  if cfg.limit?
                opts.sort   = cfg.sort   if cfg.sort?
                opts.fields = cfg.fields if cfg.fields?

                if cfg.find?
                    c.findOne cfg.find, opts, callback
                else
                    c.findOne {}, opts, callback

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

                query = fix_id query
                if not key?
                    callback? "no key defined for distinct"
                else
                    c.distinct key, query, callback

            update: (err, c) ->
                return callback? err if err?

                update = cfg.update
                query  = cfg.find ? {_id:update._id}

                query  = fix_id query
                update = fix_id update

                opts   = {}
                opts.upsert = cfg.upsert if cfg.upsert?
                opts.multi  = cfg.multi  if cfg.multi?
                opts.safe   = cfg.safe   if cfg.safe?

                c.update query, update, opts, callback

            insert: (err, c) ->
                return callback? err if err?

                opts   = {}
                opts.safe   = cfg.safe   if cfg.safe?

                doc = cfg.insert
                c.insert doc, opts, callback

            ensureIndex: (err, c) ->
                return callback? err if err?

                opts = {}
                opts.sparse = cfg.sparse if cfg.sparse
                opts.unique = cfg.unique if cfg.unique
                opts.dropDups = cfg.dropDups if cfg.dropDups

                c.ensureIndex cfg.key, opts, callback

            remove: (err, c) ->
                return callback? err if err?

                query = cfg.find ? {}
                query = fix_id query

                c.remove query, callback

            drop: (err, c) ->
                return callback? err if err?

                c.drop callback


        connect dburl, (err, db) ->
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

fix_id = (obj) ->
    if obj._id? and typeof obj._id == "string"
        obj._id = new ObjectID(obj._id)
    return obj

class DBConnection
    constructor: (@dburl) ->
        # TODO: read these from configuration file
        ###
        server      = new mongo.Server("localhost",
                          mongo.Connection.DEFAULT_PORT, {} )
        @db         = new mongo.Db dbname, server, {native_parser:true}
        ###
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
            mongo.connect @dburl, {native_parser:true, journal:true}, (err, db) ->
                t.db = db
                ObjectID = db.bson_serializer.ObjectID
                t.err = err
                if not err?
                    t.db_is_open = true
                t.open_event.emit("connected")
                callback? err, db
                t.opening = false

    close: (callback) ->
        @db?.close()
        callback()

exports.monmon = new MongoMonad()
exports.closeAll = (callback) ->
    closes = []
    for k,c of conn_pool
        do (c) ->
            closes.push (cb) ->
                c.close cb

    async.parallel closes, callback
