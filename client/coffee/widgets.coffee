
class WidgetBase
    init_new: (cb) ->
        @dom = $ @create_dom() 
        @dom.data("widgetObj", this)
        @get_default_config (cfg) =>
            @init_from cfg, cb, @dom
        @dom
    
    init_from: (cfg, cb, dom) ->
        @config = cfg
        if dom == undefined
            @dom = $ @create_dom()
            @dom.data("widgetObj", this)
        else
            @dom = dom
        @get_reports cfg.groups, (reports) =>
            @reports = reports
            @render_chart @dom.find(".radar-chart")
            if cb
                cb @dom
        @dom
                

class PassRateChart extends WidgetBase
    width:  600
    height: 500
    type: "pass_rate"

    thumbnail: "img/widget_icons/qa_reports.png"
    title: "Pass Rates Summary"
    desc:  "Summary of latest pass rates in QA Reports"

    init_reports: (@reports) ->

    init_config: (@config) ->

    get_default_config: (cb) ->
        hw = "N900"
        cached.get "/reports/groups/#{hw}", (data) ->
            cb {type:"radar", hwproduct:hw, groups: data, alert:30}

    get_reports: (groups, cb) ->
        cached.get "/reports/latest/#{@config.hwproduct}", (data) =>
            reports  = _ data
            selected = _ @config.groups
            cb reports.filter (r) ->
                selected.any (s) ->
                    s.hwproduct == r.hwproduct && s.testtype ==  r.testtype && s.target == r.target

    create_dom: ->
        if @config
            createWidget("widget_"+@type+"_"+@config.type)
        else
            createWidget("widget_"+@type+"_radar")

    render_chart: (@chart_elem) ->
        @chart = new graphs.RadarChart @chart_elem, @width, @height
        @chart.render_reports(@reports)

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
                dom = new wt().init_from(w.config)
                initWidgetEvents(dom)
                $elem.append(dom)

        add_widgets dashb.column, $lc
        add_widgets dashb.sidebar, $sb

        if cb
            cb dashb


