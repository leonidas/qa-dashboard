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
        $btn.data "widget-name", name
        $btn.insertBefore $close
        initialize_toolbar_draggable $btn

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

    load_widgets()

    balance_columns()

balance_columns = () ->
    $('#page_content').equalHeights()

get_widget_class = (name) -> (callback) ->
    cls = widgets[name]
    if cls?
        if callback?
            setTimeout (-> callback cls), 0
    else
        cached.get "/widgets/#{name}", (data) ->
            code = data.code
            cls = eval code
            cls.prototype.template = $(data.html)
            widgets[name] = cls
            callback? cls

create_new_widget = (name) -> (callback) ->
    dom = $("#widget-base-template").clone().removeAttr("id")
    dom.find('.widget_content').hide()
    dom.find('.content_main').show()
    init_widget_dom_events(dom)
    get_widget_class(name) (cls) ->
        wgt = new cls()
        wgt.type = name
        dom.data("widgetObj", wgt)
        wgt.dom = dom
        callback? wgt
    return dom

init_widget_dom_events = (dom) ->
    $dom = $(dom)
    $dom.find('.widget_edit').click ->
        $this = $(this)
        # TODO: toggle settings view

        $this.toggleClass 'active'
        balanceColumns()

        return false

    $m = $dom.find('.widget_move')
    $m.bind 'mouseover', -> $dom.addClass('move_mode')
    $m.bind 'mouseout',  -> $dom.removeClass('move_mode')

    $dom.find('.widget_close').click ->
        $dom.slideUp 200, ->
            $dom.remove()
            save_widgets()
            balance_columns()
        return false

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
                #console.log "save_widgets sortable stop"
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
    lc = '#left_column'
    sb = '#sidebar'
    $(lc).sortable('option', 'connectWith', sb)
    $(sb).sortable('option', 'connectWith', lc)

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
            #console.log "droppable drop"
            $this = $(this)
            ud = $(ui.draggable)
            name = ui.helper.data "widget-name"

            widget = create_new_widget(name) (wgt) ->
                if $this.attr("id") == "sidebar"
                    wgt.render_small_view balance_columns
                else
                    wgt.render_main_view balance_columns
                #console.log "save_widgets after create_new_widget"
                save_widgets()

            widget.insertBefore ud
            ud.remove()
            balance_columns()

initialize_toolbar_draggable = (elem) ->
    $(elem).draggable
        helper: () ->
            $this = $(this)
            helperSource = $this.children('img')
            helper = helperSource.clone()
            helper.css('width', helperSource.css('width'))
            helper.css('height', helperSource.css('height'))
            helper.data("widget-name", $this.data("widget-name"))
            return helper
        scroll: false
        revert: 'invalid'
        revertDuration: 100
        cursorAt:
            top:32
            left:32
        connectToSortable: '#left_column, #sidebar'
        scope: 'widget'

load_widgets = (cb) ->
    $.getJSON "/user/dashboard", (dashb) ->
        $lc = $('#left_column')
        $sb = $('#sidebar')

        $lc.empty()
        $sb.empty()

        add_widgets = (arr, $elem) ->
            _(arr).each (w) ->
                wt = create_new_widget(w.type) (obj) ->
                    obj.config = w.cfg
                    dom = obj.dom
                    $elem.append(dom)
                    if $elem == $lc
                        obj.render_main_view ->
                            balance_columns()
                    else
                        obj.render_small_view ->
                            balance_columns()

        add_widgets dashb.column, $lc
        add_widgets dashb.sidebar, $sb

        cb? dashb

save_widgets = (cb) ->
    $lc = $('#left_column')
    $sb = $('#sidebar')

    find_configs = ($elem) ->
        result = []
        $elem.find('.widget').each (idx, sub) ->
            #console.log sub
            obj = $(sub).data("widgetObj")
            if obj?
                cfg = obj.config
                result.push {type:obj.type, config:cfg}
        result

    dashboard =
        column:  find_configs $lc
        sidebar: find_configs $sb

    #console.log dashboard

    $.post "/user/dashboard/save", dashboard, cb

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

    initialize_application()
