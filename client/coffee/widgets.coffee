
class WidgetBase
    width: 600
    side_width: 300
    
    height: 200
    side_height: 150


    init_new: ->
        @dom = $ @create_dom()
        @dom.data("widgetObj", this)
        @dom
    
    init_from: (cfg) ->
        @config = cfg
        @init_new()

    create_dom:  ->
        $t = $("#widget-base-template").clone().removeAttr "id"
        $t.find(".widget_content").hide()
        return $t
    
    get_config: (cb) ->
        if @config == undefined
            @get_default_config (cfg) =>
                @config = cfg
                cb cfg
        else
            cb @config

    render_header: (cb) ->
        selector = "#hidden_widget_container "+@template+" .widget_header"
        $t = $(selector).clone()
        @get_config (cfg) =>
            @format_header $t, (dom) =>
                @dom.find(".widget_header").replaceWith(dom)
                if cb
                    cb()


    render_main_view: (cb) ->
        @dom.find(".widget_content").hide()
        @dom.find(".content_main").show()
        if @is_main_view_ready()
            if cb
                cb()
        else
            @get_config (cfg) =>
                @render_header =>
                    selector = "#hidden_widget_container "+@template+" .content_main"
                    $t = $(selector).clone()
                    @format_main_view $t, (dom) =>
                        @dom.find(".content_main").replaceWith(dom)
                        if cb
                            cb()

    render_small_view: (cb) ->
        @dom.find(".widget_content").hide()
        @dom.find(".content_small").show()
        if @is_small_view_ready()
            if cb
                cb()
        else
            @get_config (cfg) =>
                @render_header =>
                    selector = "#hidden_widget_container "+@template+" .content_small"
                    $t = $(selector).clone()
                    @format_small_view $t, (dom) =>
                        @dom.find(".content_small").replaceWith(dom)
                        if cb
                            cb()


    is_main_view_ready: ->
        @dom.find(".content_main .loading").length == 0

    is_small_view_ready: ->
        @dom.find(".content_small .loading").length == 0

    is_settings_view_ready: ->
        @dom.find(".content_settings .loading").length == 0


class PassRateChart extends WidgetBase
    height: 500
    side_height: 250

    type: "pass_rate"

    thumbnail: "img/widget_icons/qa_reports.png"
    title: "Pass Rates Summary"
    desc:  "Summary of latest pass rates in QA Reports"

    template: ".widget_pass_rate"

    init_reports: (@reports) ->

    init_config: (@config) ->

    get_default_config: (cb) ->
        hw = "N900"
        cached.get "/reports/groups/#{hw}", (data) ->
            cb {type:"radar", hwproduct:hw, groups: data, alert:30}

    format_header: ($t, cb) ->
        $t.find(".hwproduct").text @config.hwproduct
        if cb
            cb $t

    format_main_view: ($t, cb) ->
        @get_reports @config.groups, (reports) =>
            @reports = reports
            @render_chart $t.find(".radar-chart")
            if cb
                cb $t

    format_small_view: ($t, cb) ->
        @get_reports @config.groups, (reports) =>
            @reports = reports
            @render_small_chart $t.find(".radar-chart")
            if cb
                cb $t

    get_reports: (groups, cb) ->
        cached.get "/reports/latest/#{@config.hwproduct}", (data) =>
            reports  = _ data
            selected = _ groups
            cb reports.filter (r) ->
                selected.any (s) ->
                    s.hwproduct == r.hwproduct && s.testtype ==  r.testtype && s.target == r.target

    render_chart: (@chart_elem) ->
        @chart = new graphs.RadarChart @chart_elem, @width, @height
        @chart.render_reports(@reports)

    render_small_chart: (@chart_elem) ->
        @chart = new graphs.RadarChart @chart_elem, @side_width, @side_height
        @chart.render_reports(@reports, {labels:false})


window.widgets = {}
window.widgets.pass_rate = PassRateChart

window.init_widget_bar = (elem) ->
    $elem = $(elem)
    $close = $("#close_widget_bar")
    $tmpl = $("#hidden_widget_container .widget_info")

    _(window.widgets).each (value, key) ->
        $btn = $tmpl.clone()
        $btn.find("h1").text value.prototype.title
        $btn.find("p").text value.prototype.desc
        $btn.find("img").attr("src", value.prototype.thumbnail)
        $btn.data("widgetClass", value)
        $btn.insertBefore $close


window.save_widgets = (cb) ->
    $lc = $('#left_column')
    $sb = $('#sidebar')

    find_configs = ($elem) ->
        result = []
        $elem.find('.widget').each (idx, sub) ->
            obj = $(sub).data("widgetObj")
            if obj != undefined
                cfg = obj.config
                result.push {type:obj.type, config:cfg}
        result

    dashboard =
        column:  find_configs $lc
        sidebar: find_configs $sb

    $.post "/user/dashboard/save", dashboard, cb
    
window.load_widgets = (cb) ->
    $.getJSON "/user/dashboard", (dashb) ->
        $lc = $('#left_column')
        $sb = $('#sidebar')

        $lc.empty()
        $sb.empty()

        add_widgets = (arr, $elem) ->
            _(arr).each (w) ->
                wt = window.widgets[w.type]
                obj = new wt()
                dom = obj.init_from(w.config)
                initWidgetEvents(dom)
                $elem.append(dom)
                if $elem == $lc
                    obj.render_main_view ->
                        equals()
                else
                    obj.render_small_view ->
                        equals()

        add_widgets dashb.column, $lc
        add_widgets dashb.sidebar, $sb

        if cb
            cb dashb


