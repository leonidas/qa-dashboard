
class WidgetBase
    init_new: (cb) ->
        @get_default_config (cfg) =>
            @init_from cfg, cb
    
    init_from: (cfg, cb) ->
        @config = cfg
        @get_reports cfg.groups, (reports) =>
            console.log "init_from: entered callback"
            @reports = reports
            @dom = $ @create_dom()
            @dom.data("widgetObj", this)
            console.log "rendering chart"
            @render_chart @dom.find(".radar-chart")
            console.log "triggering callback"
            cb @dom
                

class PassRateChart extends WidgetBase
    width:  600
    height: 500
    type: "pass_rate"

    init_reports: (@reports) ->

    init_config: (@config) ->

    get_default_config: (cb) ->
        hw = "N900"
        $.getJSON "/reports/groups/#{hw}", (data) ->
            cb {type:"radar", hwproduct:hw, groups: data, alert:30}

    get_reports: (groups, cb) ->
        $.getJSON "/reports/latest/#{@config.hwproduct}", (data) =>
            reports  = _ data
            selected = _ @config.groups
            console.log "get_reports"
            console.log selected
            cb reports.filter (r) ->
                console.log r
                selected.any (s) ->
                    s.hwproduct == r.hwproduct && s.testtype ==  r.testtype && s.target == r.target

    create_dom: -> createWidget("widget_"+@type+"_"+@config.type)

    render_chart: (@chart_elem) ->
        console.log "entered render_chart"
        @chart = new graphs.RadarChart @chart_elem, @width, @height
        console.log "render_chart: new RadarChart"
        @chart.render_reports(@reports)
        console.log "render_chart: render_reports finished"

window.widgets = {}
window.widgets.pass_rate = -> new PassRateChart()

window.widgets.save_widgets = (cb) ->
    $lc = $('#left_column')
    $sb = $('#sidebar')

    find_configs = ($elem) ->
        result = []
        $elem.each (idx, sub) ->
            obj = $(sub).data("widgetObj")
            cfg = obj.config
            result.append {type:obj.type, config:cfg}
        result

    dashboard =
        column:  find_configs $lc
        sidebar: find_configs $sb

    $.post "/user/dashboard/save", dashboard, cb
    
window.widgets.load_widgets = (cb) ->
    $.getJSON "/user/dashboard", (dashb) ->
        $lc = $('#left_column')
        $sb = $('#sidebar')

        $lc.empty()
        $sb.empty()

        _(dashb.column).each (w) ->
            wt = window.widgets[w.type]
            dom = wt().init_from(w.config)
            $lc.append(dom)

        _(dashb.sidebar).each (w) ->
            wt = window.widgets[w.type]
            dom = wt().init_from(w.config)
            $sb.append(dom)


