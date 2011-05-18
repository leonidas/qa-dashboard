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
tab_hack = false

deepcopy = (obj) ->
    return obj if (typeof obj) != 'object'

    cp = {}
    for k,v of obj
        cp[k] = deepcopy v
    return cp

submit_login_form = () ->
    $form = $(this)
    field = (name) -> $form.find("input[name=\"#{name}\"]").val()

    $form.find('.error').hide()

    req =
        username: field "username"
        password: field "password"

    $form.find('input').attr 'disabled', 'disabled'

    $.post "/auth/login", req, (data) ->
        $form.find('input').removeAttr 'disabled'
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
            data.dashboard ?= {}
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
        $btn.find("img").attr("src", "/widgets/#{name}/#{cfg.thumbnail}")
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
    $p.toolbar_container.show()
    $p.upper_header.show()
    $p.logged_user.text(current_user.username)

    cached.get "/widgets", (data) ->
        initialize_toolbar data, $p.widget_bar

        if not dashboard?.tabs?
            $tab = add_tab_element "Default"
            set_current_tab $tab
            $('#tab_navi').css('visibility','visible')
            if dashboard?.column?
                # backwads compatibility
                load_widgets()
        else
            load_tabs dashboard.tabs, (err) ->
                $('#tab_navi').css('visibility','visible')

    $p.add_tab_btn.click () ->
        $new = add_tab_element "New Tab"
        set_current_tab $new
        save_widgets()
        return false

    balance_columns()

balance_columns = () ->
    $('#page_content .tab_content').equalHeights()

get_widget_class = (name) -> (callback) ->
    cls = widgets[name]
    if cls?
        if callback?
            setTimeout (-> callback cls), 1
    else
        cached.get "/widgets/#{name}", (data) ->
            code = data.code
            cls = eval code
            cls.prototype.template = $(data.html)
            widgets[name] = cls
            add_custom_css(data.css)
            callback? cls

add_custom_css = (css) ->
    if css? and css != ""
        elem = document.getElementById('custom_styles')
        src = elem.innerText + '\n\n' + css
        elem.innerText = src


create_new_widget = (name) -> (callback) ->
    dom = $("#widget-base-template").clone().removeAttr("id")
    dom.find('.widget_content').hide()
    dom.find('.content_main').show()
    init_widget_dom_events(dom)
    get_widget_class(name) (cls) ->
        wgt = new cls()
        wgt.type = name
        dom.attr("class", cls.prototype.template.attr("class"))
        dom.addClass("widget")
        dom.data("widgetObj", wgt)
        wgt.dom = dom
        callback? wgt
    return dom

init_widget_dom_events = (dom) ->
    $dom = $(dom)
    $dom.find('.widget_edit').click ->
        $this = $(this)

        $settings = $dom.find('.content_settings')
        if $this.hasClass "active"
            $this.toggleClass 'active'
            updateWidgetElement $dom
        else
            $this.toggleClass 'active'
            obj = $dom.data("widgetObj")
            obj.render_settings_view ->
                balance_columns()
                $dom.find('.widget_edit_content .cancel').click ->
                    $this.removeClass 'active'
                    $widget = $(this).closest(".widget")
                    updateWidgetElement $widget
                    return false

                $dom.find('.widget_edit_content form').submit ->
                    $form   = $(this)
                    $widget = $form.closest(".widget")
                    obj     = $widget.data("widgetObj")

                    $widget.find(".action .widget_edit").toggleClass("active")

                    obj.process_save_settings $form, ->
                        obj.reset_dom()
                        save_widgets()
                        updateWidgetElement $widget
                    return false

        balance_columns()

        return false

    $m = $dom.find('.widget_move')
    $m.bind 'mouseover', -> $dom.addClass('move_mode')
    $m.bind 'mouseout',  -> $dom.removeClass('move_mode')

    $dom.find('.widget_close').click ->
        sidebar = $dom.parent().hasClass 'sidebar'
        obj = $dom.data('widgetObj')
        console.log obj
        $n = $('#notification')

        close = () ->
            $n.slideUp()
            return false

        $n.find('a.undo').unbind().click ->
            dst = if sidebar then $('.sidebar') else $('.left_column')
            obj.dom.prependTo dst
            init_widget_dom_events obj.dom
            obj.dom.data('widgetObj', obj)
            save_widgets()
            close()
        $n.find('a.close').unbind().click close

        $n.find('span').text("Widget has been deleted.")
        $n.slideDown()
        $dom.remove()
        save_widgets()

update_undo_buffer = (obj) ->
    current_user.dashboard ?= {}
    buf = current_user.dashboard.undo ?= {}
    typ = obj.type
    buf[typ] = deepcopy(obj.config)
    console.log buf

updateWidgetElement = (elem) ->
    $e = $(elem)
    obj = $e.data("widgetObj")
    $parent = $e.parent()
    if $parent.hasClass "sidebar"
        obj.render_small_view balance_columns
    else
        obj.render_main_view balance_columns

add_tab_element = (title) ->
    $dom = $('#hidden_templates .tab').clone()
    $dom.find('.tab_title').text(title)
    $dom.data('tab-content', $('#hidden_templates .tab_content').clone())
    $dom.appendTo $p.tab_list
    init_tab_events $dom
    return $dom

init_tab_events = ($dom) ->
    $dom.unbind()
    $actions = $dom.find('.tab_actions')

    $dom.droppable
        accept: ".widget"
        tolerance: "pointer"
        greedy: true

        over: (event, ui) ->
            return false if $dom.hasClass 'current'
            ui.draggable.addClass "tab-drop"
            $('.ui-widget-sortable-placeholder').css 'visibility', 'hidden'
            $dom.addClass "accepting-widget"
            tab_hack = true

        out: (event, ui) ->
            return false if $dom.hasClass 'current'
            ui.draggable.removeClass "tab-drop"
            $('.ui-widget-sortable-placeholder').css 'visibility', 'visible'
            $dom.removeClass "accepting-widget"
            tab_hack = false

        drop: (event, ui) ->
            ui.draggable.removeClass "tab-drop"
            $dom.removeClass "accepting-widget"
            if $dom.hasClass 'current'
                tab_hack = false
                return false
            $ud = $(ui.draggable)

            f = () ->
                $con = $dom.data('tab-content')
                $ud.prependTo $con.find('.left_column')
                #set_current_tab $dom
                balance_columns()
                save_widgets()
                tab_hack = false

            event.stopImmediatePropagation()
            setTimeout f, 0


    $dom.click ->
        if $dom.hasClass 'current'
            $actions.toggle().width($dom.width())
        else
            set_current_tab $dom
        return false

    def_action = (name, f) -> $actions.find(".#{name}").unbind().click ->
        f()
        $actions.hide()
        return false

    def_action 'rename', ->
        old = $dom.find('.tab_title').text()
        $dom.empty()
        $dom.append $('#hidden_templates .new_tab').clone().children()
        $form  = $dom.find('form')
        $input = $form.find('input')
        $input.val(old)
        $input.focus()
        $input.select()

        end_edit = () ->
            title = $input.val()
            $dom.empty()
            $dom.append $('#hidden_templates .tab').clone().children()
            $dom.find('.tab_title').text(title)

            init_tab_events $dom

            if title != old
                save_widgets()

        $input.blur  -> end_edit(); false
        $form.submit -> end_edit(); false


    def_action 'copy', ->
        conf = deepcopy serialize_tab $dom
        conf.name = "Copy of #{conf.name}"
        load_tab(conf) save_widgets

    def_action 'delete', ->
        $tabs = $p.tab_list.find('li.tab')
        len   = $tabs.length
        idx   = $tabs.index $dom

        if len == 1
            $new = add_tab_element "Default"
            set_current_tab $new
        else if idx == 0
            set_current_tab $tabs[1]
        else
            set_current_tab $tabs[idx-1]

        conf = serialize_tab $dom
        $n = $('#notification')

        close = () ->
            current_user.dashboard.tab_undo = null
            $n.slideUp()
            return false

        $n.find('a.undo').unbind().click ->
            load_tab(conf) save_widgets
            close()
        $n.find('a.close').unbind().click close

        $n.find('span').text("The tab has been deleted.")
        $n.slideDown()
        $dom.remove()
        save_widgets()


set_current_tab = (dom) ->
    $dom = $(dom)
    $p.tab_list.find('li').removeClass('current')
    $p.tab_list.find('.tab_actions').hide()
    $dom.addClass('current')
    $('#page_content .tab_content').detach()
    $('#page_content').prepend $dom.data 'tab-content'

    initialize_sortable_columns()
    balance_columns()

initialize_sortable_columns = () ->
    # Enable sorting tabs
    $p.tab_list.sortable
        items:  'li.tab'
        helper: 'clone'
        axis: 'x'
        distance: 5
        tolerance: 'pointer'

        start: (event, ui) ->
            $p.tab_list.find('.tab_actions').hide()
            $p.tab_list.find('.ui-sortable-placeholder').width(ui.helper.width())

        stop: (event, ui) ->
            $p.tab_list.find('.tab_actions').hide()
            save_widgets()

    $s = $sortables()

    # Dragging existing widgets from one position to another
    $s.sortable
        items:   '.widget'
        handle:  '.widget_move'
        appendTo: 'body'
        opacity: 0.9
        revert:  false

        start: (event, ui) ->
            $('.ui-widget-sortable-placeholder').height($(ui.item).height())
            balance_columns()
        stop: (event, ui) ->
            return if tab_hack
            $item = $(ui.item)

            if $item.hasClass "widget_info"
                $item.hide()
            else
                $item.removeClass 'move_mode'
                obj = $item.data "widgetObj"
                if obj?
                    $parent = $item.parent()
                    obj.render balance_columns
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
    lc = '#page_content .left_column'
    sb = '#page_content .sidebar'
    $(lc).sortable('option', 'connectWith', sb)
    $(sb).sortable('option', 'connectWith', lc)

    # Enable columns to receive new widgets from toolbar
    $s.droppable
        accept: '.widget_info'
        scope: 'widget'
        greedy: true
        tolerance: 'pointer'
        over: (event, ui) ->
            $s.sortable('refresh')
            balance_columns()
        drop: (event, ui) ->
            $this = $(this)
            #ud = $(ui.draggable)
            ud = $('#page_content .ui-draggable')
            name = ui.helper.data "widget-name"

            widget = create_new_widget(name) (wgt) ->
                undo = current_user.dashboard?.undo
                if undo?
                    wgt.config = undo[name]
                    delete undo[name]
                g = () ->
                    if widget.parent()?
                        wgt.render balance_columns
                        save_widgets()
                    else
                        setTimeout g, 0
                setTimeout g, 0

            #widget.insertBefore ud
            #ud.remove()
            ud.hide()
            f = () ->
                widget.insertBefore ud
                ud.remove()
                balance_columns()
            setTimeout f, 0

    $p.widget_bar.find('.widget_info').draggable 'option', 'connectToSortable', $s

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
        scope: 'widget'

$sortables   = () -> $('#page_content').find('.left_column, .sidebar')
$left_column = () -> $('#page_content .left_column')
$sidebar     = () -> $('#page_content .sidebar')

load_widget = ($elem) -> (w) -> (cb) ->
    create_new_widget(w.type) (obj) ->
        obj.config = w.config
        dom = obj.dom
        $elem.append(dom)
        balance_columns()
        obj.render balance_columns
        cb?()

load_tab = (tab) -> (cb) ->
    $tab = add_tab_element tab.name
    $con = $tab.data('tab-content')

    $lc = $con.find('.left_column')
    $sb = $con.find('.sidebar')

    $lc.empty()
    $sb.empty()

    add_widgets = (arr, $elem) -> (cb) ->
        arr = _(arr).map (load_widget $elem)
        async.series arr, cb

    async.parallel [
        add_widgets(tab.column, $lc),
        add_widgets(tab.sidebar, $sb)], cb

load_tabs = (tabs, cb) ->
    loaders = _(tabs).map load_tab
    async.parallel loaders, (err) ->
        return cb? err if err?
        set_current_tab $p.tab_list.find('li.tab')[0]
        cb?()


serialize_tab = (tab) ->
    find_configs = ($elem) ->
        result = []
        $elem.find('.widget').each (idx, sub) ->
            obj = $(sub).data("widgetObj")
            if obj?
                cfg = obj.config
                result.push {type:obj.type, config:cfg}
        result

    $tab = $(tab)
    $content = $tab.data('tab-content')
    $lc = $content.find '.left_column'
    $sb = $content.find '.sidebar'

    name: $tab.find('.tab_title').text()
    column:  find_configs $lc
    sidebar: find_configs $sb

load_widgets = (cb) ->
    $.getJSON "/user/dashboard", (dashb) ->

        $lc = $left_column()
        $sb = $sidebar()

        $lc.empty()
        $sb.empty()

        add_widgets = (arr, $elem) ->
            arr = _(arr).map (w) -> (callback) ->
                wt = create_new_widget(w.type) (obj) ->
                    obj.config = w.config
                    dom = obj.dom
                    $elem.append(dom)
                    balance_columns()
                    if $elem == $lc
                        obj.render_main_view ->
                            balance_columns()
                    else
                        obj.render_small_view ->
                            balance_columns()
                    callback?()
            async.series arr

        add_widgets dashb.column, $lc
        add_widgets dashb.sidebar, $sb

        cb? dashb

save_widgets = (cb) ->
    ## TODO: save requests need to be synchronized via a queued so that we
    ##       don't accidentally overwrite newer state with older state if
    ##       asynchronious save requests get processed in different order

    $tabs = $p.tab_list.find('li.tab')

    old = current_user.dashboard

    dashboard =
        tabs: _($tabs).map serialize_tab
        undo: old.undo

    #console.log dashboard

    $.post "/user/dashboard/save", dashboard, cb

$ () ->
    CFInstall?.check()

    $(window).load   balance_columns
    $(window).resize balance_columns

    $p.login_form        = $('.login_form')

    $p.form_container    = $('.form_container')
    $p.toolbar_container = $('.toolbar_container')
    $p.upper_header      = $('#upper_header')
    $p.logged_user       = $('#logged_user')

    $p.widget_bar        = $('#widget_bar')
    $p.add_widget_btn    = $('#add_widgets_btn')

    $p.tab_list          = $('#tab_navi ul')
    $p.add_tab_btn       = $('#tab_navi .add')

    $p.custom_styles     = $('#custom_styles')

    $p.login_form.appendTo('.form_container')
    $p.login_form.find('form').submit submit_login_form

    $('#logout_btn').click submit_user_logout

    initialize_application()
