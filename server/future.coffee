# Asynchronous Future Value

EventEmitter = require('events').EventEmitter
async = require('async')

class Future
    constructor: () ->
        @event = new EventEmitter()
        @callback = (error, value) =>
            throw "Future callback already called" if @error? or @value?
            @error = error
            @value = value
            @event.emit "ready"

    get: (callback) ->
        if @error? or @value?
            async.nextTick =>
               callback @error, @value 
            return

        @event.once "ready", =>
            callback @error, @value

call = (func) ->
    Array::unshift.call arguments, null
    callThis.apply null, arguments

callThis = (ths, func) ->
    args = Array::slice.call arguments, 2
    fut = new Future()
    args.push fut.callback
    func.apply(null, args)
    return fut

exports.Future   = Future
exports.call     = call
exports.callThis = callThis
    