# Asynchronous Future Value

EventEmitter = require('events').EventEmitter

class Future
    constructor: () ->
        @event = new EventEmitter()
        @callback = (error, value) =>
            throw "Future callback already called" if @error? or @value?
            @error = error
            @value = value
            @event.emit "ready"

    get: (callback) ->
        return callback @error, @value if @error? or @value?

        @event.once "ready", =>
            callback @error, @value

exports.Future = Future
