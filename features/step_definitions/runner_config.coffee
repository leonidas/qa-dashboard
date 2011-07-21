require.paths.unshift 'node_modules'
require.paths.push 'server'
require.paths.push 'server/js'

Steps    = require('cucumis').Steps
assert   = require('assert')
should   = require('should')
coffee   = require('coffee-script')
sodautil = require('sodautil')
testutil = require('testutil')

browser = sodautil.browser
sel     = sodautil.selectors

Steps.Runner.on 'beforeTest', (run) ->
    testutil.test_server_start (err) ->
        console.log "\x1b[33mServer started...\x1b[0m"
        run()

Steps.Runner.on 'afterTest', (done) ->
    sodautil.close_browser (err) ->
        throw err if err?
        testutil.test_server_close () ->
            console.log "\x1b[33mServer closed...\x1b[0m"
            testutil.test_db_drop () ->
                console.log "\x1b[33mDatabase dropped...\x1b[0m"
                testutil.test_db_closeAll () ->
                    console.log "\x1b[33mDatabase connections closed...\x1b[0m"
                    done()
                    # hack to force exit (dashboard has pending callbacks even after db and server close)
                    setTimeout () ->
                            console.log "\x1b[33mExiting...\x1b[0m"
                            process.exit()
                        ,6000
                    # TODO: remove hack when found how dashboard can be shut down more gracefully
