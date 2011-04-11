# Asynchroniously promised value

class Promise
    constructor: ->
        @event = new EventEmitter()

    get: (callback) ->
        return callback @error, @value if @error? or @value?

        @event.on "fulfill", ->
            callback null, @value

        @event.on "error", ->
            callback @error, null

    set: (value) ->
        throw "promise value already set" if @error? or @value?

        @value = value
        @event.emit "fullfill"

    error: (msg) ->
        throw "promise value already set" if @error? or @value?

        @error = msg
        @event.emit "error"

exports.Promise = Promise
