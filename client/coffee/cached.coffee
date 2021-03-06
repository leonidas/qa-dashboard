#
# This file is part of Meego-QA-Dashboard
#
# Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#

_cache = {}
_post_cache = {}

future = require './future.coffee'

module.exports =
    get: (url, cb) ->
        fut = _cache[url]
        if not fut?
            fut = future.call $.getJSON, url
            _cache[url] = fut
        fut.get cb

    post: (url, data, cb) ->
        json = if data? then JSON.stringify(data) else null
        key = url + "##" + json
        fut  = _cache[key]
        if not fut?
            fut = new future.Future()
            _cache[key] = fut
            f = (data) ->
                fut.callback data
            config =
                url: url
                type: "POST"
                data: json
                dataType: "json"
                contentType: "application/json; charset=utf-8"
                success: f
                error: f

            $.ajax config
        fut.get cb
