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

fs     = require('fs')
path   = require('path')
async  = require('async')
coffee = require('coffee-script')
_      = require('underscore')


load_widget = (widgetpath) -> (callback) ->
    load_widget_file = (filename) -> (callback) ->
        filename = widgetpath+"/"+filename
        path.exists filename, (exists) ->
            if exists
                fs.readFile filename, "utf-8", callback
            else
                callback? null, ""

    load_widget_source = (callback) ->
        filename    = widgetpath+"/widget"
        filename_js = filename+".js"
        filename_cf = filename+".coffee"

        console.log filename_cf

        path.exists filename_js, (exists) ->
            if exists
                fs.readFile filename_js, "utf-8", callback
            else
                path.exists filename_cf, (exists) ->
                    if exists
                        fs.readFile filename_cf, "utf-8", (err, src) ->
                            return callback? err if err?
                            callback? null, coffee.compile(src)
                    else
                        callback? "widget sourcefile #{filename_cf} not found"

    tasks =
        html: load_widget_file "widget.html"
        css:  load_widget_file "widget.css"
        code: load_widget_source

    async.parallel tasks, (err, result) ->
        return callback? err if err?
        if result.html == ""
            callback? "no valid widget template file found"
        else
            callback? null, result

exports.load_all_widgets = (widgetroot, callback) ->
    fs.readdir widgetroot, (err, files) ->
        return callback? err if err?

        widgets = {}
        for fn in files
            widgets[fn] = load_widget widgetroot+"/"+fn

        async.parallel widgets, callback
