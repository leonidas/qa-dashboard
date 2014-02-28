Raphael = require 'raphael'

class PassRateTrend extends QAReportsWidget
    use_passtargets: true

    history_width: 220
    history_width_sidebar: 80

    history_height: 35
    history_height_sidebar: 30

    history_spacing: 2

    history_num: 20
    history_num_sidebar: 8

    get_default_config: (cb) ->
        super (cfg) ->
            cfg.alert       = 30
            cfg.title       = "Pass Trends: #{cfg.release} #{cfg.profile} #{cfg.testset}"
            cfg.passtargets = {}
            cb cfg

    format_main_view: ($t, cb) ->
        self   = @
        targets = @config.passtargets

        tooltip = @template.find('.tooltip').clone()

        if @in_sidebar()
            num = @history_num_sidebar
        else
            num = @history_num

        @get_reports @config.groups, num, (reports) =>
            @reports = reports
            tr = $t.find('tbody tr')

            for rs in reports
                r = rs[0]
                row = tr.clone()

                # Remove report ID since this links to the product level
                url = r.url.replace /\/\d+$/, ''
                # Title
                row.find('.title a').attr "href", url
                self.set_row row, r

                # Pass Rate History
                container = row.find('div.trend-graph')
                @draw_trend_graph rs, tooltip, container

                row.insertBefore tr
            tr.remove()

            tooltip.appendTo $t
            tooltip.hide()

            cb? $t

    format_small_view: ($t, cb) -> @format_main_view $t, cb

    draw_trend_graph: (reports, tooltip, elem) ->
        if @dom.parent().hasClass 'sidebar'
            hw = @history_width_sidebar
            hh = @history_height_sidebar
            hn = @history_num_sidebar
        else
            hw = @history_width
            hh = @history_height
            hn = @history_num

        spacing = @history_spacing

        paper = Raphael(elem.get(0), hw, hh)

        w = hw/hn - spacing

        x = hw
        for r in reports
            total_cases = r.total_cases - r.total_measured

            if (total_cases > 0)
                h = (r.total_pass+r.total_fail)*hh/total_cases

                na = paper.rect(x-w,0,w,hh)
                na.attr
                    fill: "#F1F0F0"
                    "stroke-width": 0
                    stroke: null

                fail = paper.rect(x-w,hh-h,w,h)
                fail.attr
                    fill: "#E7A6AB"
                    "stroke-width": 0
                    stroke: null

                h = r.total_pass*hh/total_cases

                pass = paper.rect(x-w,hh-h,w,h)
                pass.attr
                    fill: "#309937"
                    "stroke-width": 0
                    stroke: null

                invisible = paper.rect(x-w,0,w,hh)
                invisible.attr
                    stroke: null
                    fill: "white"
                    opacity: 0

                @init_tooltip_events tooltip, r, $(pass.node), $(fail.node) ,$(invisible.node)

            x -= w + spacing


    init_tooltip_events: (tooltip, r, pass, fail, na) ->
        hh = @history_height
        bw = @history_width/@history_num-@history_spacing

        url  = r.url

        adjusted_total = r.total_cases - r.total_measured
        passrate = (r.total_pass*100/adjusted_total).toFixed(0)
        failrate = (r.total_fail*100/adjusted_total).toFixed(0)
        narate   = (r.total_na*100/adjusted_total).toFixed(0)

        date = (""+r.tested_at)
        date = date.slice(0,date.indexOf("T"))

        show_tip = () ->
            pass.attr fill: "#6AC526"
            fail.attr fill :"#E3D4D7"

            tooltip.find('.date').text date
            tooltip.find('.pass').text "#{passrate}%"
            tooltip.find('.fail').text "#{failrate}%"
            tooltip.find('.na').text "#{narate}%"
            tooltip.show()

            offset = na.offset()
            w = tooltip.width()
            tooltip.offset
                left: offset.left - w/2 + bw/2
                top:  offset.top  + hh

        hide_tip = () ->
            pass.attr fill: "#309937"
            fail.attr fill :"#E7A6AB"
            tooltip.hide()

        na.hover show_tip, hide_tip
        na.click ->
            window.open url, "_blank"


return PassRateTrend
