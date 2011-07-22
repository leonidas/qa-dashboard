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

Steps.Given /^I have a browser session open$/, (ctx) ->
    browser
        .chain
        # TODO: only open browser session once in 'before test' after timeout issue in cucumis module has been solved
        .session()
        .setTimeout(15000)
        .setSpeed(50)
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

Steps.Then /^I should not be logged in$/, (ctx) ->
    browser
        .chain
        .assertNotVisible(sel.logout_btn)
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

Steps.Then /^I should see login error "([^"]*?)"$/ , (ctx, errormsg) ->
    browser
        .chain
        .assertVisible(sel.login_error)
        .getText sel.login_error, (msg) ->
            msg.should.equal(errormsg)
        .end (err) ->
            throw err if err
            ctx.done()


Steps.export(module)
