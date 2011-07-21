require.paths.unshift 'node_modules'
require.paths.push 'server'
require.paths.push 'server/js'

Steps    = require('cucumis').Steps
assert   = require('assert')
should   = require('should')
soda     = require('soda')
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

Steps.Given /^I have a browser session open$/, (ctx) ->
    browser
        .chain
        .session()
        .setTimeout(15000)
        .setSpeed(100)
        .end (err) ->
            throw err if err
            ctx.done()

Steps.Given /^I am on the front page$/, (ctx) ->
    browser
        .chain
        .open('/')
        .end (err) ->
            throw err if err
            ctx.done()

Steps.Given /^I am not logged in$/, (ctx) ->
    browser
        .chain
        .clickAndWait(sel.logout_btn)
        .end (err) ->
            throw err if err
            ctx.done()

Steps.When /^I login with username "([^"]*?)" and password "([^"]*?)"$/, (ctx, username, password) ->
    browser
        .chain
        .type(sel.user_login, username)
        .type(sel.user_password, password)
        .click(sel.login_btn)
        .end (err) ->
            throw err if err
            ctx.done()

Steps.Then /^I should be logged in$/, (ctx) ->
    browser
        .chain
        .assertVisible(sel.logout_btn)
        .end (err) ->
            throw err if err
            ctx.done()

Steps.Then /^I should see "([^"]*?)" as logged user$/, (ctx, username) ->
    browser
        .chain
        .getText sel.logged_user, (user) ->
            user.should.equal(username)
        .end (err) ->
            throw err if err
            ctx.done()

Steps.export(module)
