
require.paths.unshift __dirname + '/../node_modules'
require.paths.push(__dirname + "/../server")

vows   = require('vows')
assert = require('assert')
should = require('should')

suite = vows.describe('The MongoMonad').addBatch
    "module": 
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
                
suite.export(module)