# Asynchronous Future Value

class Future
    constructor: ->
        @event = new EventEmitter()

    callback: (err, value) ->
        @error = err
        @value = value
        @evend.emit "ready"

    get: (callback) ->
        return callback @error, @value if @error? or @value?

        @event.on "ready", ->
            callback @error, @value

exports.Future = Future
