
require.paths.unshift __dirname + '/../node_modules'
require.paths.push(__dirname + "/../server")

vows   = require('vows')
assert = require('assert')
should = require('should')

suite = vows.describe('MongoMonad')

# basic smoke-test
suite.addBatch
    "the module": 
        topic: -> require('monmon')

        "can be imported": (monmon) ->
            should.exist monmon

        "contains the monad instance":
            topic: (monmon) -> monmon.monmon
            
            "which can be accessed": (monmon) ->
                should.exist monmon

            "which can be used to select env": (monmon) ->
                m = monmon.env 'test-monmon'
                m.should.exist
                m.should.have.property('cfg')
                    .with.property('env', 'test-monmon')

# basic insertion
suite.addBatch
    "test db 'foo'":
        topic: -> 
            foo = require('monmon').monmon.env('test-monmon').use('foo')
            foo.dropDatabase().run (err,res) =>
                this.callback err, res, foo
            return

        "returns the monad itself after drop": (err, res, m) ->
            assert.isNull err
            should.exist m
            m.should.have.property("cfg")

        "inserted item in collection 'bar'":
            topic: (res, m) ->
                m.collection('bar').insert({foo: "bar"}).run(this.callback)
                return

            "doesn't return an error": (err, m) ->
                assert.isNull err

            "can be queried back":
                topic: (err, m) ->
                    m.find({foo: "bar"}).run (err,arr) =>
                        this.callback err,arr,m
                    return

                "without errors": (err, arr, m) ->
                    assert.isNull err
                
                "result has single item": (err, arr, m) ->
                    should.exist arr
                    arr.should.have.lengthOf 1

                "result is the corrent item": (err, arr, m) ->
                    arr[0].should.have.property('foo', 'bar')

suite.export(module)