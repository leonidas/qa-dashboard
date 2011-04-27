
class PassRateChart extends WidgetBase
    height: 500
    side_height: 250

    type: "pass_rate"

    thumbnail: "img/widget_icons/qa_radar.png"
    title: "Pass Rates Summary"
    desc:  "Summary of latest pass rates in QA Reports"

    template: ".widget_pass_rate"

    init_reports: (@reports) ->

    init_config: (@config) ->

    group_key: (grp) ->
        "#{grp.target} #{grp.testtype}"

    group_title: (grp) ->
        "#{grp.target} #{grp.testtype}"

    get_default_config: (cb) ->
        hw = "N900"
        cached.get "/reports/groups/#{hw}", (data) =>
            targets = {}
            _(data).each (grp) =>
                targets[@group_key(grp)] = 90
            cb {type:"radar", hwproduct:hw, groups: data, alert:30, passtargets: targets}

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

    format_settings_view: ($t, cb) ->
        hw = @config.hwproduct
        cached.get "/reports/groups/#{hw}", (data) =>
            # set hardware
            $t.find("form .hwproduct").val(hw)

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
                $row.find(".target").text(grp.target)
                $row.find(".testtype").text(grp.testtype)
                $row.find(".passtarget").val(""+targets[@group_key(grp)])
                $row.find(".shiftcb").attr("checked", checked)
                $row.data("groupData", grp)

                $row.insertBefore $trow

            $trow.remove()
            if cb
                cb $t

    same_group: (g1, g2) ->
        g1.hwproduct == g2.hwproduct && g1.testtype == g2.testtype && g1.target == g2.target

    contains_group: (arr, grp) -> _(arr).any (g) => @same_group(g,grp)

    process_save_settings: ($form, cb) ->
        @config.hwproduct = $form.find(".hwproduct").val()
        @config.alert = $form.find(".alert").val()

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
                target = 90
            passtargets[@group_key(grp)] = parseInt(target)
        @config.groups = selected
        @config.passtargets = passtargets


        if cb
            cb()


    get_reports: (groups, cb) ->
        cached.get "/reports/latest/#{@config.hwproduct}", (data) =>
            reports  = _ data
            selected = _ groups
            cb reports.filter (r) ->
                selected.any (s) ->
                    s.hwproduct == r.hwproduct && s.testtype ==  r.testtype && s.target == r.target

    render_chart: (@chart_elem) ->
        @chart = new graphs.RadarChart @chart_elem, @width, @height
        @chart.render_reports(@reports, @config.passtargets)

    render_small_chart: (@chart_elem) ->
        @chart = new graphs.RadarChart @chart_elem, @side_width, @side_height
        @chart.render_reports(@reports, @config.passtargets, {labels:false})

return PassRateChart
