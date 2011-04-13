# Utilities for testing

app      = require('app')
testCase = require('nodeunit').testCase

TEST_PORT = 3133

test_server = (dir, dbm, tests) ->
    orig_setUp    = tests.setUp
    orig_tearDown = tests.tearDown

    createApp = (callback) ->
        tests.app = app.create_app dir, dbm
        tests.app.listen TEST_PORT, callback

    closeApp = ->
        tests.app = app.close()

    tests.setUp = (callback) ->
        createApp ->
            if orig_setUp?
                orig_setUp callback
            else
                callback()

    tests.tearDown = (callback) ->
        closeApp()
        if orig_tearDown?
            orig_tearDown callback
        else
            callback()

    return testCase tests
