
_cache = {}

window.cached = {}
window.cached.get = (url, cb) ->
    data = _cache[url]
    if data == undefined
        $.getJSON url, (data) ->
            _cache[url] = data
            cb data
    else
        cb data

