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

    init_new: ->
        @dom = $ @create_dom()
        @dom

    init_from: (cfg) ->
        @config = cfg
        @init_new()

    create_dom: ->
        $t = $('#widget-base-template').clone().removeAttr "id"
        $t.find(".widget_content").hide()
        $t.data("widgetObj", this)
        return $t

    reset_dom: ->
        empty = @create_dom()
        @dom.find(".widget_header").replaceWith empty.find(".widget_header")
        @dom.find(".content_main").replaceWith empty.find(".content_main")
        @dom.find(".content_small").replaceWith empty.find(".content_small")
        @dom.find(".content_settings").replaceWith empty.find(".content_settings")

    in_sidebar: -> @dom.parents('.sidebar').length > 0

    get_config: (cb) ->
        if not @config?
            @get_default_config (cfg) =>
                @config = cfg
                cb cfg
        else
            if not @config.release?
                # Backward compatibility hack
                @config.release = "1.2"
            cb @config

    get_default_config: (cb) -> cb {}

    format_header: ($t, cb) ->
        $t.find("h1 span.title").text @config.title
        cb? $t

    format_main_view: ($t, cb) -> cb $t
    format_small_view: ($t, cb) -> cb $t
    format_settings_view: ($t, cb) -> cb $t

    render_header: (cb) ->
        #selector = @template.find ".widget_header"
        selector = "#widget-base-template .widget_header"
        $t = $(selector).clone(true)
        @get_config (cfg) =>
            @format_header $t, (dom) =>
                @dom.find(".widget_header").replaceWith(dom)
                cb?()


    render_view: (cls, formatfunc, cb) ->
        @get_config (cfg) =>
            @render_header =>
                $t = $(@template).find(cls).clone(true)
                formatfunc.apply(this, [$t, (dom) =>
                    @dom.find(cls).replaceWith(dom)
                    cb?()
                ])

    render_main_view: (cb) ->
        @dom.find(".widget_content").hide()
        @dom.find(".content_main").show()
        @dom.find(".widget_edit").removeClass "active"
        if @is_main_view_ready()
            cb?()
        else
            @render_view ".content_main", @format_main_view, cb

    render_small_view: (cb) ->
        @dom.find(".widget_content").hide()
        @dom.find(".content_small").show()
        @dom.find(".widget_edit").removeClass "active"
        if @is_small_view_ready()
            cb?()
        else
            @render_view ".content_small", @format_small_view, cb

    render_settings_view: (cb) ->
        @dom.find(".widget_content").hide()
        @dom.find(".content_settings").show()

        if @is_settings_view_ready()
            @inputify_header()
            cb?()
        else
            @render_view ".content_settings", @format_settings_view, =>
                @inputify_header()
                cb?()

    inputify_header: () ->
        title = @dom.find(".widget_header .title")
        old = title.text()
        title.empty()
        title.append $('<input/>').addClass("title").val old

    render: (cb) ->
        if @in_sidebar()
            @render_small_view cb
        else
            @render_main_view cb

    is_main_view_ready: ->
        @dom.find(".content_main .loading").length == 0

    is_small_view_ready: ->
        @dom.find(".content_small .loading").length == 0

    is_settings_view_ready: ->
        @dom.find(".content_settings .loading").length == 0

    save_settings: ($form, cb) ->
        @process_save_settings $form, =>
            title = @dom.find(".widget_header .title")
            @config.title = t = title.find("input").val()
            cb?()


class QAReportsWidget extends WidgetBase
    use_passtargets: false
    use_alert: false

    render_settings_view: (cb) ->
        @dom.find(".widget_content").hide()
        @dom.find(".content_settings").show()

        if @is_settings_view_ready()
            @inputify_header()
            cb?()
        else
            @get_config (cfg) =>
                @render_header =>
                    $t = $('#hidden_templates .common_edit_content').clone(true)
                    @format_settings_view $t, (dom) =>
                        @dom.find('.content_settings').replaceWith(dom)
                        @inputify_header()
                        cb?()

    format_settings_view: ($t, cb) ->
        cfg = @config
        init_hw  = cfg.hwproduct
        init_ver = cfg.release

        groups   = cfg.groups
        targets  = cfg.passtargets

        use_pass  = @use_passtargets
        use_alert = @use_alert

        g_ = _(groups)
        if not g_.isArray()
            cfg.groups = groups = g_.toArray()

        selected = contains_group groups

        createRadioButtons = (parent, data, checked, func) ->
            # Generate Radio Buttons from Templates
            rel = parent
            inputTmpl = rel.find("input").first().clone().unbind().removeAttr "id"
            labelTmpl = rel.find("label").first().clone().unbind().removeAttr "for"
            inputTmpl.removeAttr "checked"
            rel.empty()
            inputTmpl.appendTo(rel).hide()
            labelTmpl.appendTo(rel).hide()

            found = false
            for k of data
                do (k) ->
                    i = inputTmpl.clone()
                    # Don't use show, for some reason it sets style attribute
                    # of the element to block instead of what's defined in
                    # CSS. This did not happen with jQuery 1.4 but does now
                    l = labelTmpl.clone().css 'display', 'inline-block'
                    if k == checked
                        i.attr('checked','checked')
                        found = true
                    i.val k
                    l.text k
                    i.appendTo rel
                    l.appendTo rel
                    l.click ->
                        i.click()
                        func?(k)
            if not found
                parent.find("input").first().click()

        updateSelectedSets = (data) ->
            parent = $t.find("table.multiple_select")
            body   = parent.find("tbody.selected-group")
            tmpl   = body.find("tr").first().clone().unbind()
            body.empty()
            tmpl.appendTo(body).hide()

            return balance_columns() unless data?
            for g in data
                do (g) ->
                    return if not selected g

                    row = tmpl.clone().show()
                    row.data "test-group", g
                    key = group_key g

                    checkbox = row.find('input.shiftcb')
                    checkbox.attr("checked", "checked").val key
                    checkbox.unbind()

                    row.find('span.target').text g.profile
                    row.find('strong.testtype').text g.testtype

                    passtarget = row.find('input.passtarget')
                    if use_pass
                        passtarget.show()
                        pt = targets?[key] ? "0"
                        passtarget.val pt
                    else
                        passtarget.hide()

                    checkbox.click ->
                        remove_group groups, g
                        updateSelectedSets(data)
                        updateSuggestions(data)

                    row.appendTo body

            balance_columns()

        $hilight = $('<span class="hilight"/>')
        hilight_span = (span, text, hilights, i) ->
            span.empty()
            cur = 0
            for h in hilights
                start = h.start - i
                end   = h.end - i
                if start < 0 or start >= text.length
                    continue
                else
                    $h = $hilight.clone()
                    if start > cur
                        span.append text.slice(cur,start)
                    span.append $h.text text.slice(start, end)
                    cur = end
            span.append text.slice(cur)


        updateSuggestions = (data) ->
            parent = $t.find("table.multiple_select")
            body   = parent.find("tbody.suggestion-group")
            tmpl   = body.find("tr").first().clone().unbind()
            body.empty()
            tmpl.appendTo(body).hide()

            normalize = (s) ->
                $.trim(s).toLowerCase().replace(/\s+/, " ")

            filter = parent.find("input.filters")
            expr  = normalize filter.val()
            words = expr.split(" ")

            pattern = words.join(".*")
            regexp  = new RegExp(pattern, "i")

            filter.unbind().keydown ->
                f = () ->
                    updateSuggestions(data) if normalize filter.val() != expr
                setTimeout f, 1

            return balance_columns() unless data?
            for g in data
                do (g) ->
                    return if selected g
                    key = group_key g

                    hilights = []
                    if expr != ""
                        return if not regexp.test(key)
                        kl = key.toLowerCase()
                        for w in words
                            i = kl.search(w)
                            hilights.push
                                start: i
                                end: i + w.length

                    row = tmpl.clone().show()

                    checkbox = row.find('input.shiftcb')
                    checkbox.removeAttr("checked").val key
                    checkbox.unbind()

                    span = row.find('span.target')
                    hilight_span span, g.profile, hilights, 0

                    span = row.find('strong.testtype')
                    hilight_span span, g.testtype, hilights, g.profile.length+1

                    checkbox.click ->
                        groups.push g
                        updateSelectedSets(data)
                        updateSuggestions(data)

                    row.appendTo body

            balance_columns()



        createTestSets = (data) ->
            updateSelectedSets(data)
            updateSuggestions(data)
            balance_columns()


        cached.get "/query/qa-reports/groups", (data) ->
            currentHw  = () -> hwsel.find("input:checked").val()
            currentVer = () -> relsel.find("input:checked").val()
            selectRelease = (ver) ->
                hw = currentHw()
                createRadioButtons hwsel, data[ver], hw, selectHw
                hw = currentHw()
                createTestSets data[ver][hw]

            selectHw = (hw) ->
                ver = currentVer()
                createTestSets data[ver][hw]

            # Generate Release Radio Buttons
            relsel = $t.find("form div.release")
            createRadioButtons relsel, data, init_ver, selectRelease

            # Generate Handware Radio Buttons
            hwsel = $t.find("form div.hardware")
            createRadioButtons hwsel, data[init_ver], init_hw, selectHw

            # Generate List of Test Sets
            createTestSets data[init_ver]?[init_hw]

            # Set Alert Limit
            if use_alert
                $t.find("div.alert").show()
                $t.find("form input.alert").val(""+cfg.alert)
            else
                $t.find("div.alert").hide()

            cb? $t

    process_save_settings: ($form, cb) ->
        @config = {}

        @config.release = $form.find("div.release input:checked").val()
        @config.hwproduct = $form.find("div.hardware input:checked").val()
        if @use_alert
            @config.alert = $form.find("input.alert").val()

        selected = []
        passtargets = {}

        $rows = $form.find("table.multiple_select tbody.selected-group tr")
        for tr in $rows
            $tr = $(tr)
            $checkbox   = $tr.find('input.shiftcb')
            $passtarget = $tr.find('input.passtarget')

            grp = $tr.data("test-group")
            continue if not grp?

            selected.push(grp)

            if @use_passtargets
                target = parseInt($tr.find(".passtarget").val())
                if not target > 0
                    target = 0

                passtargets[group_key(grp)] = parseInt(target)

        @config.groups = selected
        if @use_passtargets
            @config.passtargets = passtargets

        #console.log selected
        #console.log @config

        cb?()

    get_reports: (groups, num, cb) ->
        url = "/query/qa-reports/latest/#{@config.release}/#{@config.hwproduct}?num=#{num}"
        groups = _(@config.groups).toArray()
        f = contains_group groups
        cached.get url, (data) ->
            if num == 1
                cb _(data).filter f
            else
                cb _(data).filter (rs) ->
                    f rs[0]

group_key = (grp) ->
    "#{grp.profile} #{grp.testtype}".replace('.',':')

same_group = (g1, g2) -> group_key(g1) == group_key(g2)

contains_group = (arr) -> (grp) ->
    for g in arr
        return true if same_group(g,grp)
    return false

remove_group = (arr, grp) ->
    for i,g of arr
        if same_group(g,grp)
            arr.splice(i,1)
            return

window.QAReportsWidget = QAReportsWidget
window.WidgetBase      = WidgetBase
