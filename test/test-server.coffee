
require.paths.unshift __dirname + '/../node_modules'
require.paths.push(__dirname + "/../server")

async = require('async')
_     = require('underscore')

testCase = require('nodeunit').testCase

test_server = require('testutil').test_server

exports["http tests"] = test_server "test-http"
    "index page works": (test) ->
        test.expect(2)

        @get "/", (res) ->
            test.equal res.statusCode, 200
            test.notEqual res.body.indexOf("<title>Meego QA Dashboard</title>"), -1
            test.done()
