
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
        cached.get "/query/qa-reports/groups", (data) ->
            targets = {}
            ver = _.last _(data).keys()
            hw  = _.first _(data[ver]).keys()

            groups = []
            for grp in data[ver][hw]
                groups.push grp
            cb
                hwproduct: hw
                release: ver
                groups: groups
                alert:30
                passtargets: targets
                title: "Pass Trends: #{hw}"

    format_main_view: ($t, cb) ->
        targets = @config.passtargets

        tooltip = @template.find('.tooltip').clone()

        if @in_sidebar()
            num = @history_num_sidebar
        else
            num = @history_num

        @get_reports @config.groups, num, (reports) =>
            @reports = reports
            tr = $t.find('tbody tr')

            max_total = _.max(rs[0].total_cases for rs in reports)

            for rs in reports
                r = rs[0]
                row = tr.clone()
                # Title

                ## TODO: hardcoded url to qa-reports
                url  = "http://qa-reports.meego.com/#{r.release}/#{r.profile}/#{r.testtype}/#{r.hardware}"
                row.find('.title a').attr "href", url
                row.find('.title .profile').text r.profile
                row.find('.title .testtype').text r.testtype


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
            if (r.total_cases > 0)
                h = (r.total_pass+r.total_fail)*hh/r.total_cases

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

                h = r.total_pass*hh/r.total_cases

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

        url  = "http://qa-reports.meego.com/#{r.release}/#{r.profile}/#{r.testtype}/#{r.hardware}/#{r.qa_id}"

        passrate = parseInt(r.total_pass*100/r.total_cases)
        failrate = parseInt(r.total_fail*100/r.total_cases)
        narate   = parseInt(r.total_na  *100/r.total_cases)

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
