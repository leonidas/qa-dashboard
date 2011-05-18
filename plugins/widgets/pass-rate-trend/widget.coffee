
class PassRateTrend extends WidgetBase

    history_width: 220
    history_height: 35
    history_spacing: 2

    history_num: 20

    group_key: (grp) ->
        "#{grp.profile} #{grp.testtype}"

    get_default_config: (cb) ->
        hw = "N900"
        cached.get "/query/qa-reports/groups/#{hw}", (data) =>
            targets = {}
            _(data).each (grp) =>
                targets[@group_key(grp)] = 90
            cb
                type:"radar"
                hwproduct:hw
                groups: data
                passtargets: targets
                title: "Pass trends: #{hw}"

    format_header: ($t, cb) ->
        $t.find("h1 span.title").text @config.title
        cb? $t

    format_main_view: ($t, cb) ->
        targets = @config.passtargets

        tooltip = @template.find('.tooltip').clone()

        @get_reports @config.groups, (reports) =>
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

    format_small_view: ($t, cb) ->
        targets = @config.passtargets
        @get_reports @config.groups, (reports) =>
            @reports = reports
            tr = $t.find('tbody tr')

            max_total = _.max(rs[0].total_cases for rs in reports)

            for rs in reports
                r = rs[0]
                row = tr.clone()
                if r.total_cases == 0
                    passrate = 0
                else
                    passrate = r.total_pass*100/r.total_cases

                # Title
                row.find('.title .profile').text r.profile
                row.find('.title .testtype').text r.testtype

                # Pass Rate Bar
                container = row.find('div.pass-rate-bar')
                key = "#{r.profile} #{r.testtype}"
                @draw_graph r, targets[key], max_total, container

                row.insertBefore tr
            tr.remove()
            cb? $t

    format_settings_view: ($t, cb) ->
        hw = @config.hwproduct
        cached.get "/query/qa-reports/groups/#{hw}", (data) =>
            # set hardware
            $t.find("form .hwproduct").val(hw)

            # set title
            $t.find("form .title").val @config.title

            # set alert limit
            $t.find("form .alert").val(""+@config.alert)

            targets = @config.passtargets
            # set selected groups
            # generate a new row for each item in "data"
            #   select example row as template
            #   set check box according to selected groups in config
            #   set pass rate target
            $table = $t.find("table.multiple_select")
            $trow = $table.find("tr.row-template").removeClass("row-template").addClass("graph-target")

            #$trow.detach()
            _(data).each (grp) =>
                checked = @contains_group(@config.groups, grp)

                $row = $trow.clone()
                $row.find(".target").text(grp.profile)
                $row.find(".testtype").text(grp.testtype)
                $row.find(".passtarget").val(""+targets[@group_key(grp)])
                $row.find(".shiftcb").attr("checked", checked)
                $row.data("groupData", grp)

                $row.insertBefore $trow

            $trow.remove()
            if cb
                cb $t

    same_group: (g1, g2) ->
        g1.hardware == g2.hardware && g1.testtype == g2.testtype && g1.profile == g2.profile

    contains_group: (arr, grp) -> _(arr).any (g) => @same_group(g,grp)

    process_save_settings: ($form, cb) ->
        @config = {}

        @config.hwproduct = $form.find(".hwproduct").val()
        @config.title = $form.find(".title").val()

        selected = []
        passtargets = {}

        $rows = $form.find("table.multiple_select").find(".graph-target")
        $rows.each (idx, tr) =>
            $tr = $(tr)
            grp = $tr.data("groupData")
            checked = $tr.find(".shiftcb").attr("checked")
            if checked
                selected.push(grp)
            target = parseInt($tr.find(".passtarget").val())
            if not target > 0
                target = 0
            passtargets[@group_key(grp)] = parseInt(target)
        @config.groups = selected
        @config.passtargets = passtargets

        #console.log selected

        cb?()

    get_reports: (groups, cb) ->
        url = "/query/qa-reports/latest/#{@config.hwproduct}?num=#{@history_num}"
        cached.get url, (data) ->
            reports  = _ data
            selected = _ groups
            cb reports.filter (rs) ->
                r = rs[0]
                selected.any (s) ->
                    s.hardware == r.hardware && s.testtype ==  r.testtype && s.profile == r.profile

    draw_trend_graph: (reports, tooltip, elem) ->
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
