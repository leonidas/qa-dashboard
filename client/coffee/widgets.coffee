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

class WidgetBase
    width: 600
    side_width: 300

    height: 200
    side_height: 150


    init_new: ->
        @dom = $ @create_dom()
        @dom

    init_from: (cfg) ->
        @config = cfg
        @init_new()

    create_dom: ->
        $t = $('#widget-base-template').clone()
        $t.find(".widget_content").hide()
        $t.data("widgetObj", this)
        return $t

    reset_dom: ->
        empty = @create_dom()
        @dom.find(".widget_header").replaceWith empty.find(".widget_header")
        @dom.find(".content_main").replaceWith empty.find(".content_main")
        @dom.find(".content_small").replaceWith empty.find(".content_small")
        @dom.find(".content_settings").replaceWith empty.find(".content_settings")

    get_config: (cb) ->
        if @config == undefined
            @get_default_config (cfg) =>
                @config = cfg
                cb cfg
        else
            cb @config

    get_default_config: (cb) -> cb {}

    format_header: ($t, cb) -> cb $t
    format_main_view: ($t, cb) -> cb $t
    format_small_view: ($t, cb) -> cb $t
    format_settings_view: ($t, cb) -> cb $t

    render_header: (cb) ->
        selector = @template.find ".widget_header"
        $t = $(selector).clone(true)
        @get_config (cfg) =>
            @format_header $t, (dom) =>
                @dom.find(".widget_header").replaceWith(dom)
                if cb
                    cb()


    render_view: (cls, formatfunc, cb) ->
        @get_config (cfg) =>
            @render_header =>
                $t = $(@template).find(cls).clone(true)
                formatfunc.apply(this, [$t, (dom) =>
                    @dom.find(cls).replaceWith(dom)
                    if cb
                        cb()
                ])

    render_main_view: (cb) ->
        @dom.find(".widget_content").hide()
        @dom.find(".content_main").show()
        if @is_main_view_ready()
            if cb
                cb()
        else
            @render_view ".content_main", @format_main_view, cb

    render_small_view: (cb) ->
        @dom.find(".widget_content").hide()
        @dom.find(".content_small").show()
        if @is_small_view_ready()
            if cb
                cb()
        else
            @render_view ".content_small", @format_small_view, cb

    render_settings_view: (cb) ->
        @dom.find(".widget_content").hide()
        @dom.find(".content_settings").show()
        if @is_settings_view_ready()
            if cb
                cb()
        else
            @render_view ".content_settings", @format_settings_view, cb

    is_main_view_ready: ->
        @dom.find(".content_main .loading").length == 0

    is_small_view_ready: ->
        @dom.find(".content_small .loading").length == 0

    is_settings_view_ready: ->
        @dom.find(".content_settings .loading").length == 0

window.WidgetBase = WidgetBase
