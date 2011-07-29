require.paths.unshift 'node_modules'
require.paths.push 'server'
require.paths.push 'server/js'

Steps      = require('cucumis').Steps
assert     = require('assert')
should     = require('should')
coffee     = require('coffee-script')
sodautil   = require('sodautil')
testserver = require('testserver').createServer

browser = sodautil.browser
sel     = sodautil.selectors

Steps.Runner.on 'beforeTest', (run) ->
    testserver.start (err) ->
        #console.log "\x1b[33mServer started...\x1b[0m"
        browser
            .chain
            .session()
            .setTimeout(15000)
            .setSpeed(50)
            .end (err) ->
                throw err if err
                #console.log "\x1b[33mBrowser session opened...\x1b[0m"
                run()

Steps.Runner.on 'afterTest', (done) ->
    sodautil.close_browser (err) ->
        throw err if err?
        #console.log "\x1b[33mBrowser closed...\x1b[0m"
        testserver.close () ->
            #console.log "\x1b[33mServer closed...\x1b[0m"
            testserver.db_drop () ->
                #console.log "\x1b[33mDatabase dropped...\x1b[0m"
                testserver.db_closeAll () ->
                    #console.log "\x1b[33mDatabase connections closed...\x1b[0m"
                    done()
                    console.log "\x1b[33mExiting...\x1b[0m"
                    # hack to force exit (dashboard has pending callbacks even after db and server close)
                    # TODO: remove hack when found how dashboard can be shut down more gracefully
                    setTimeout () ->
                            process.exit()
                        ,6000

Steps.Runner.on 'afterScenario', (next) ->
    testserver.db_drop () ->
        #console.log "\x1b[33mDatabase dropped...\x1b[0m"
        next()
