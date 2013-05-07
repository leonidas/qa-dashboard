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

submit_login_form = (e) ->
    e.preventDefault()

    $form = $(this)
    field = (name) -> $form.find("input[name=\"#{name}\"]").val()

    $form.find('.error').hide()

    req =
        username: field "username"
        password: field "password"

    $form.find('input').attr 'disabled', 'disabled'

    $.post("/auth/login", req)
    .done (data) ->
        load_dashboard (data) ->
            current_user = data
            init_user_dashboard(data.dashboard)
    .fail (xhr, status) ->
        $form.find('.error').show()
        balance_columns()
    .always ->
        $form.find('input').removeAttr 'disabled'

submit_user_logout = (e) ->
    e.preventDefault()
    $.post "/auth/logout", (data) ->
        window.location.pathname = ""
        window.location.hash = ""
        window.location.reload()

handle_fragment_path = () ->
    f = parse_fragment()

    if current_user? and f.user == current_user.username
        init_user_dashboard current_user.dashboard, (err) ->
            set_current_tab_by_name(f.tab)
    else
        cached.get "/shared/#{f.user}/#{f.tab}", (res) ->
            tab = res.result if res.status == 'ok'
            # TODO: handle error
            $('.share_info .user').text f.user
            $('.share_link a').text window.location.host
            $('.share_link a').attr "href","#{window.location.protocol}//#{window.location.host}"
            init_shared_dashboard tab

initialize_application = () ->
    frag = window.location.hash
    load_dashboard (data) ->
        if data.username?
            current_user = data
            data.dashboard ?= {}
            # TODO: refactor duplicate frag checking
            if frag? and frag != ''
                frag = frag.substring(1)
                handle_fragment_path frag
            else
                # render dashboard
                init_user_dashboard(data.dashboard)
        else
            if frag? and frag != ''
                frag = frag.substring(1)
                handle_fragment_path frag
            else
                # show login form
                $p.form_container.show()
                balance_columns()

initialize_toolbar = (widgets, elem) ->
    $elem  = $(elem)
    $close = $elem.find(".close_widget_bar")
    $tmpl  = $("#hidden_templates .widget_info")

    names = _.keys(widgets).sort()

    for name in names
        cfg = widgets[name]
        $btn = $tmpl.clone(true)
        $btn.find("h1").text cfg.title
        $btn.find("p").text cfg.desc
        $btn.find("img").attr("src", "/widgets/#{name}/#{cfg.thumbnail}")
        $btn.data "widget-name", name
        $btn.insertBefore $close
        initialize_toolbar_draggable $btn

    $p.add_widget_btn.click (e) ->
        e.preventDefault()
        $elem.slideDown(300)

    $close.click (e) ->
        e.preventDefault()
        $elem.slideUp(300)

load_dashboard = (callback) ->
    $.getJSON "/user", (data) ->
        callback? data

reset_dashboard = () ->
    $('#wrap').removeClass('shared').removeClass('shared-anon')
    $p.tab_list.find('li.tab').remove()

init_shared_dashboard = (tab) ->
    if current_user?
        $('#wrap').addClass 'shared'
    else
        $('#wrap').addClass 'shared-anon'
    $p.form_container.hide()
    $p.toolbar_container.hide()
    $p.upper_header.show()

    $('#tab_navi').css('visibility','visible')
    load_tab(tab) (err) ->
        set_current_tab $p.tab_list.find('li.tab')[0]

    $p.add_shared_tab.click () ->
        shared_copy = deepcopy tab
        reset_dashboard()
        init_user_dashboard current_user.dashboard, (err) ->
            shared_copy.name = make_unique_tab_name(shared_copy.name)
            load_tab(shared_copy) (err) ->
                save_widgets()
                set_current_tab_by_name(shared_copy.name)


init_user_dashboard = (dashboard, cb) ->
    $p.form_container.hide()
    $p.toolbar_container.show()
    $p.upper_header.show()
    $p.logged_user.text(current_user.username)

    $p.logged_user.on 'click', (e) ->
        e.preventDefault()
        cached.get "/user/token", (data) ->
            $p.token.text(data.token)
            $('#user_info').slideToggle(300)

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
                cb?(err)

    $p.add_tab_btn.click (e) ->
        e.preventDefault()
        $new = add_tab_element make_unique_tab_name("New Tab")
        set_current_tab $new
        save_widgets()

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
            return callback? null unless data?

            code = data.code
            cls = eval code
            cls.prototype.template = $(data.html)
            widgets[name] = cls
            add_custom_css(data.css)
            callback? cls

add_custom_css = (css) ->
    if css? and css != ""
        elem = document.getElementById('custom_styles')
        src  = elem.innerText + '\n\n' + css
        if elem.styleSheet
            elem.styleSheet.cssText = src
        else
            while elem.firstChild
                elem.removeChild elem.firstChild
            elem.appendChild document.createTextNode src

create_new_widget = (name) -> (callback) ->
    dom = $("#widget-base-template").clone().removeAttr("id")
    dom.find('.widget_content').hide()
    dom.find('.content_main').show()
    init_widget_dom_events(dom)
    get_widget_class(name) (cls) ->
        return callback? null unless cls?

        wgt = new cls()
        # Get default config to get some configuration saved, otherwise
        # the widget will show different data on page refresh
        wgt.get_config ->
            wgt.type = name
            dom.attr("class", cls.prototype.template.attr("class"))
            dom.addClass("widget")
            dom.data("widgetObj", wgt)
            wgt.dom = dom
            callback? wgt
    return dom

init_widget_dom_events = (dom) ->
    $dom = $(dom)
    $dom.find('.widget_edit').click (e) ->
        e.preventDefault()
        $this = $(this)

        $settings = $dom.find('.content_settings')
        if $this.hasClass "active"
            $this.removeClass 'active'

            $form   = $dom.find(".widget_edit_content form")
            $widget = $this.closest(".widget")
            obj     = $widget.data("widgetObj")

            $widget.find(".action .widget_edit").toggleClass("active")
            $widget.removeClass("edit_mode_active")

            obj.save_settings $form, ->
                obj.reset_dom()
                save_widgets()
                updateWidgetElement $widget
        else
            $this.addClass 'active'
            $this.closest(".widget").addClass("edit_mode_active")
            obj = $dom.data("widgetObj")
            obj.render_settings_view ->
                balance_columns()
                $dom.find('.widget_edit_content form').submit (e) -> e.preventDefault()

        balance_columns()

    $m = $dom.find('.widget_move')
    $m.bind 'mouseover', -> $dom.addClass('move_mode')
    $m.bind 'mouseout',  -> $dom.removeClass('move_mode')

    $dom.find('.widget_close').click ->
        sidebar = $dom.parent().hasClass 'sidebar'
        obj = $dom.data('widgetObj')
        #console.log obj
        $n = $('#notification')

        close = (e) ->
            e.preventDefault()
            $n.slideUp()

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
        balance_columns()
        save_widgets()

update_undo_buffer = (obj) ->
    current_user.dashboard ?= {}
    buf = current_user.dashboard.undo ?= {}
    typ = obj.type
    buf[typ] = deepcopy(obj.config)
    #console.log buf

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
    $dom.insertBefore $p.tab_list.find('.share_info')
    if not is_shared()
        init_tab_events $dom
    return $dom

is_shared = () ->
    w = $('#wrap')
    w.hasClass('shared') or w.hasClass('shared-anon')

unique_tab_name = (tabname) ->
    $tabs = $p.tab_list.find('li.tab').find('.tab_title')
    not _.any $tabs, ($tab) -> $tab.text == tabname

make_unique_tab_name = (tabname) ->
        i = 1
        while not unique_tab_name(tabname)
            tabname = tabname.replace(/\(\d+\)$/,'') + "(#{i++})"
        tabname

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
                $ud.data('widgetObj').render()
                #set_current_tab $dom
                balance_columns()
                save_widgets()
                tab_hack = false

            event.stopImmediatePropagation()
            setTimeout f, 0


    $dom.click (e) ->
        e.preventDefault()
        if $dom.hasClass 'current'
            $actions.toggle().width($dom.width())
        else
            set_current_tab $dom

    def_action = (name, f) -> $actions.find(".#{name}").unbind().click (e) ->
        e.preventDefault()
        f()
        $actions.hide()

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
            if unique_tab_name(title) && title != ""
                $dom.find('.tab_title').text(title)
            else
                $dom.find('.tab_title').text(old)

            init_tab_events $dom
            set_current_tab $dom

            if title != old
                save_widgets()

        $input.blur  -> end_edit(); false
        $form.submit -> end_edit() if unique_tab_name($input.val()); false


    def_action 'copy', ->
        conf = deepcopy serialize_tab $dom
        conf.name = make_unique_tab_name("Copy of #{conf.name}")
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

        close = (e) ->
            e.preventDefault()
            current_user.dashboard.tab_undo = null
            $n.slideUp()

        $n.find('a.undo').unbind().click ->
            load_tab(conf) save_widgets
            close()
        $n.find('a.close').unbind().click close

        $n.find('span').text("The tab has been deleted.")
        $n.slideDown()
        $dom.remove()
        save_widgets()

parse_fragment = () ->
    frag = window.location.hash
    if frag?
        frag = frag.substring(1)
        return null if frag == ""

        sep  = frag.indexOf '/'

        user: decodeURIComponent frag.substring(0,sep)
        tab:  decodeURIComponent frag.substring(sep+1)

set_current_tab = (dom) ->
    $dom = $(dom)
    $p.tab_list.find('li').removeClass('current')
    $p.tab_list.find('.tab_actions').hide()
    $dom.addClass('current')
    $('#page_content .tab_content').detach()
    $('#page_content').prepend $dom.data 'tab-content'

    fu = parse_fragment()?.user

    username = fu ? current_user.username
    user    = encodeURIComponent username
    tabname = encodeURIComponent $dom.find('.tab_title').text()
    window.location.hash = "#{user}/#{tabname}"

    initialize_sortable_columns()
    balance_columns()

set_current_tab_by_name = (name) ->
    for tab in $p.tab_list.find('li')
        $tab = $(tab)
        tabname = $tab.find('.tab_title').text()
        if tabname == name
            return set_current_tab $tab

initialize_sortable_columns = () ->
    return if is_shared()

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
        return cb?() unless obj?

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
    $.getJSON "/user/dashboard", (res) ->

        dashb = {}
        dashb = res.result if res.status == "ok"

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

_save_queue = []
save_widgets = (cb) ->

    $tabs = $p.tab_list.find('li.tab')

    dashboard =
        tabs: _($tabs).map serialize_tab

    #console.log dashboard

    empty = _save_queue.length == 0

    _save_queue.push dashboard

    f = ->
        l = _save_queue.length
        return if l == 0
        db = _save_queue[l-1] # save only the latest version
        _save_queue = []
        $.post "/user/dashboard/save", db, ->
            f()
            cb?()

    f() if empty


$ () ->
    CFInstall?.check mode: 'overlay'

    $(window).load   balance_columns
    $(window).resize balance_columns

    $p.login_form        = $('.login_form')

    $p.form_container    = $('.form_container')
    $p.toolbar_container = $('.toolbar_container')
    $p.upper_header      = $('#upper_header')
    $p.logged_user       = $('#logged_user')

    $p.token             = $p.logged_user.siblings('#user_info').find('.token')

    $p.widget_bar        = $('#widget_bar')
    $p.add_widget_btn    = $('#add_widgets_btn')

    $p.tab_list          = $('#tab_navi ul')
    $p.add_tab_btn       = $('#tab_navi .add')

    $p.custom_styles     = $('#custom_styles')

    $p.add_shared_tab    = $('.add_shared_tab')

    $p.login_form.appendTo('.form_container')
    $p.login_form.find('form').submit submit_login_form

    $('#logout_btn').click submit_user_logout

    initialize_application()

window.balance_columns = balance_columns
