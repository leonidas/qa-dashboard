# Asynchroniously promised value

EventEmitter = require('events').EventEmitter

class Promise
    constructor: ->
        @event = new EventEmitter()

    get: (callback) ->
        return callback @error, @value if @error? or @value?

        @event.once "fulfill", ->
            callback null, @value

        @event.once "error", ->
            callback @error, null

    set: (value) ->
        throw "promise value already set" if @error? or @value?

        @value = value
        @event.emit "fulfill"

    error: (msg) ->
        throw "promise value already set" if @error? or @value?

        @error = msg
        @event.emit "error"

exports.Promise = Promise
