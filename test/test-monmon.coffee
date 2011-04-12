# Test monmon API

require.paths.unshift __dirname + '/../node_modules'
require.paths.push(__dirname + "/../server")

async = require('async')

testCase = require('nodeunit').testCase

mm = require('monmon').monmon
connect = require('monmon').connect

exports["environments are separate"] = (test) ->
    test.expect(7)

    db1 = mm.env("test1").use("test-monmon").collection("test")
    db2 = mm.env("test2").use("test-monmon").collection("test")

    db1.dropDatabase().run (err) ->
        db2.dropDatabase().run (err) ->
            db1.insert({foo:"bar"}).run (err) ->
                test1 = (cb) ->
                    q = db1.find({foo:"bar"}).do (err, arr) ->
                            test.equal err, null
                            if arr?
                                test.strictEqual arr.length, 1
                                test.strictEqual arr[0].foo, "bar"
                    q.run (err) ->
                        test.equal err, null
                        cb()        

                test2 = (cb) ->
                    q = db2.find({foo:"bar"}).do (err, arr) ->
                            test.equal err, null
                            if arr?
                                test.strictEqual arr.length, 0
                    q.run (err) ->
                        test.equal err, null
                        cb()        

                async.parallel [test1, test2], ->
                    console.log "async parallel finished"
                    test.done()

exports["multiple queued commands work correctly"] = (test) ->
    test.expect(3)

    db = mm.env("test").use("test-monmon").collection("test")
    
    q = db.dropDatabase()
          .insert({foo:"bar"})
          .insert({foo:"asdf"})
          .find().do (err, arr) ->
              test.equal err, null
              test.equal arr.length, 2

    q.run (err, arr) ->
        test.equal err, null
        test.done()

exports["run callback can catch the result of last action"] = (test) ->
    test.expect(2)

    db = mm.env("test").use("test-monmon").collection("test")
    
    q = db.dropDatabase()
          .insert({foo:"bar"})
          .insert({foo:"asdf"})
          .find()

    q.run (err, arr) ->
        test.equal err, null
        test.equal arr.length, 2
        test.done()
