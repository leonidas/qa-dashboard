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

window.cached = {}
window.cached.get = (url, cb) ->
    data = _cache[url]
    if data == undefined
        $.getJSON url, (data) ->
            _cache[url] = data
            cb data
    else
        cb data

window.cached.post = (url, data, cb) ->
    key = url + "##" + data
    cached = _cache[key]
    if cached?
        cb? cached
    else
        config =
            url: url
            type: "POST"
            data: if data? then JSON.stringify(data) else null
            dataType: "json"
            contentType: "application/json; charset=utf-8"
            success: (response) ->
                _cache[key] = response
                cb? response

        $.ajax config
