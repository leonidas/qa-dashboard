# Test monmon API

require.paths.unshift __dirname + '/../node_modules'
require.paths.push(__dirname + "/../server")

async = require('async')

testCase = require('nodeunit').testCase

mm = require('monmon').monmon
connect = require('monmon').connect

exports["environments are separate"] = (test) ->
    #test.expect(3)

    db1 = mm.env("test1").use("test-monmon").collection("test")
    db2 = mm.env("test2").use("test-monmon").collection("test")

    db1.dropDatabase().run (err) ->
        db2.dropDatabase().run (err) ->
            db1.insert({foo:"bar"}).run (err, arr) ->
                connect "test-monmon-test1", (err, db) ->
                    db.collection "test", (err, coll) -> 
                        coll.find {foo:"bar"}, (err, cur) ->
                            cur.toArray (err, arr) ->
                                console.log arr

                    connect "test-monmon-test1", (err, db) ->
                        db.collection "test", (err, coll) -> 
                            coll.find {foo:"bar"}, (err, cur) ->
                                cur.toArray (err, arr) ->
                                    console.log arr
                                    test.done()


###
    db1.dropDatabase().run (err) ->
        db2.dropDatabase().run (err) ->

            db1.insert({foo:"bar"}).run (err, arr) ->

                connect "test-monmon-test1", (err, db) ->
                    db.collection "test", (err, coll) -> 
                        coll.find {foo:"bar"}, (err, cur) ->
                            cur.toArray (err, arr) ->
                                console.log arr
                                test.done()
###
###
                db1.find({foo:"bar"}).runCursor (err, cur) ->
                    cur.toArray (err, arr) ->
                        console.log "db1.find"
                        console.log err
                        test.done()
###
###                
            db1.insert({foo:"bar"}).run ->
                test1 = (cb) -> 
                    db1.find({foo:"bar"}).run (err, arr) ->
                        test.equal err, null
                        test.strictEqual arr.length, 1
                        test.strictEqual arr[0].foo, "bar"
                        cb()

                test1 ->
                    test.done()
###
###
                test2 = (cb) ->
                    db2.find({foo:"bar"}).run (err, arr) ->
                        test.equal err, null
                        test.strictEqual arr.length, 0
                        console.log "test2"
                        cb()

                async.parallel [test1, test2], ->
                    test.done()
###