require.paths.unshift 'node_modules'
require.paths.push 'server'
require.paths.push 'server/js'

Steps    = require('cucumis').Steps
assert   = require('assert')
should   = require('should')
coffee   = require('coffee-script')
sodautil = require('sodautil')

browser = sodautil.browser
sel     = sodautil.selectors

Steps.When /^I open the widget menu$/, (ctx) ->
    browser
        .chain
        .click(sel.add_widgets)
        .waitForVisible(sel.widget_bar)
        .end (err) ->
            ctx.done()

Steps.When /^I drag-n-drop a new "([^"]*?)" widget to the "([^"]*?)"$/, (ctx, widget, area) ->
    browser
        .chain
        .dragAndDropToObject(sel.widget_bar_select(widget), sel[area])
        .end (err) ->
            throw err if err
            ctx.done()

Steps.Then /^I should see a "([^"]*?)" widget in the "([^"]*?)"$/, (ctx, widget, area) ->
    widget_loc = sel[area] + " .#{widget}"
    browser
        .chain
        .waitForElementPresent(widget_loc)
        .end (err) ->
            throw err if err
            ctx.done()

Steps.export(module)
