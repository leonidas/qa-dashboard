# Asynchroniously promised value

EventEmitter = require('events').EventEmitter
async = require('async')

class Promise
    constructor: ->
        @event = new EventEmitter()

    get: (callback) ->
        if @err? or @value?
            process.nextTick =>
                callback @err, @value
            return

        @event.once "fulfil", =>
            callback null, @value

        @event.once "error", =>
            callback @err, null

    fulfil: (value) ->
        throw "promise value already set" if @err? or @value?

        @value = value
        @event.emit "fulfil"

    error: (msg) ->
        throw "promise value already set" if @err? or @value?

        @err = msg
        @event.emit "error"

exports.Promise = Promise
