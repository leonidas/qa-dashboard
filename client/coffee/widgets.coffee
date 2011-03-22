
class WidgetBase
    init_new: (cb) ->
        @get_default_config (cfg) =>
            @init_from cfg, cb
    
    init_from: (cfg, cb) ->
        @config = cfg
        @get_reports cfg.groups, (reports) =>
            @reports = reports
            @dom = $ @create_dom()
            @dom.data("widgetObj", this)
            @render_chart @dom.find(".radar-chart")
            db @dom
                

class PassRateChart extends WidgetBase
    width:  600
    height: 500
    type: "widget_qa_reports"

    init_reports: (@reports) ->

    init_config: (@config) ->

    get_default_config: (cb) ->
        hw = "N900"
        $.getJSON "/reports/groups/#{hw}", (data) ->
            cb {type:"radar", hwproduct:hw, groups: data, alert:30}

    get_reports: (groups, cb) ->
        $.getJSON "/reports/latest/#{@config.hwproduct}", (data) ->
            reports  = _ data
            selected = _ @config.groups
            cb reports.filter (r) ->
                selected.include
                    hwproduct: r.hwproduct
                    testtype:  r.testtype
                    target:    r.target

    create_dom: -> createWidget(@type+"_"+@config.type)

    render_chart: (@chart_elem) ->
        @chart = new RadarChart @elem, @width, @height
        @chart.render_reports(@reports)

window.widgets = {}
window.widgets.pass_rate = -> new PassRateChart()

