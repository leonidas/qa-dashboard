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


## Module Globals
current_user = null
$p = {}
widgets = {}


submit_login_form = () ->
    $form = $(this)
    field = (name) -> $form.find("input[name=\"#{name}\"]").val()

    $form.find('.error').hide()

    req =
        username: field "username"
        password: field "password"

    $form.attr 'disabled', 'disabled'

    $.post "/auth/login", req, (data) ->
        $form.removeAttr 'disabled'
        if data.status == "error"
            # show error message
            $form.find('.error').show()
            balance_columns()
        else
            load_dashboard (data) ->
                current_user = data
                init_user_dashboard(data.dashboard)

    return false

submit_user_logout = () ->
    $.post "/auth/logout", (data) ->
        window.location.reload()

    return false

initialize_application = () ->
    load_dashboard (data) ->
        if data.username?
            current_user = data
            # render dashboard
            init_user_dashboard(data.dashboard)
        else
            # show login form
            $p.form_container.show()
            balance_columns()

initialize_toolbar = (widgets, elem) ->
    $elem  = $(elem)
    $close = $elem.find(".close_widget_bar")
    $tmpl  = $("#hidden_templates .widget_info")

    for name,cfg of widgets
        $btn = $tmpl.clone(true)
        $btn.find("h1").text cfg.title
        $btn.find("p").text cfg.desc
        $btn.find("img").attr("src", cfg.thumbnail)
        $btn.insertBefore $close

    $p.add_widget_btn.click ->
        $elem.slideDown(300)
        return false

    $close.click ->
        $elem.slideUp(300)
        return false

load_dashboard = (callback) ->
    $.getJSON "/user", (data) ->
        callback? data

init_user_dashboard = (dashboard) ->
    $p.form_container.hide()
    $p.widget_container.show()
    $p.toolbar_container.show()

    cached.get "/widgets", (data) ->
        initialize_toolbar data, $p.widget_bar

    balance_columns()

balance_columns = () ->
    $('#page_content').equalHeights()

get_widget_class = (name) -> (callback) ->
    cls = widgets[name]
    if cls?
        callback? null, cls
    else
        cached.get "/widgets/#{name}", (data) ->
            code = data.code
            cls = eval code
            widgets[name] = cls
            callback? cls


initialize_sortable_columns = () ->
    # Dragging existing widgets from one position to another
    $('#left_column, #sidebar').sortable
        items:   '.widget'
        handle:  '.widget_move'
        opacity: 0.9
        revert:  false

        start: (event, ui) ->
            $('.ui-widget-sortable-placeholder').height($(ui.item).height());
            balance_columns()
        stop: (event, ui) ->
            $item = $(ui.item)
            $item.removeClass 'move_mode'
            obj = $item.data "widgetObj"
            if obj?
                $parent = $item.parent()
                if $parent.attr("id") == "sidebar"
                    obj.render_small_view balance_columns
                else
                    obj.render_main_view balance_columns
                save_widgets()
                balance_columns()
        over: (event, ui) ->
            $(this).sortable('refresh')
            balance_columns()
        out: (event, ui) ->
            balance_columns()

        placeholder: 'ui-widget-sortable-placeholder'
        tolerance:   'pointer'

    # Connect the sortable columns with each other
    $('#left_column').sortable('option', 'connectWith', '#sidebar')
    $('#sidebar').sortable('option', 'connectWith', '#left_column')

initialize_toolbar_draggable = () ->
    $('.widget_info').draggable
        helper : () ->
            helperSource = $(this).children('img')
            helper = helperSource.clone()
            helper.css('width', helperSource.css('width'))
            helper.css('height', helperSource.css('height'))
            return helper
        scroll: false
        revert: 'invalid'
        revertDuration: 100
        cursorAt:
            top:32
            left:32
        connectToSortable: '#left_column, #sidebar'
        scope : 'widget'
        start : (event, ui) ->
            cls = $(this).data("widgetClass")
            dom = new cls().init_new()
            newWidget = dom

    # Enable columns to receive new widgets from toolbar
    $('#left_column, #sidebar').droppable
        accept: '.widget_info'
        scope: 'widget'
        greedy: true
        tolerance: 'pointer'
        over: (event, ui) ->
            $('#left_column, #sidebar').sortable('refresh')
            balance_columns()
        drop: (event, ui) ->
            $(ui.draggable).children().remove()
            balance_columns()


$ () ->
    $(window).load   balance_columns
    $(window).resize balance_columns

    $p.login_form        = $('.login_form')

    $p.form_container    = $('.form_container')
    $p.widget_container  = $('.widget_container')
    $p.toolbar_container = $('.toolbar_container')

    $p.widget_bar        = $('#widget_bar')
    $p.add_widget_btn    = $('#add_widgets_btn')

    $p.login_form.appendTo('.form_container')
    $p.login_form.find('form').submit submit_login_form

    $('#logout_btn').click submit_user_logout

    initialize_sortable_columns()
    initialize_toolbar_draggable()

    initialize_application()
