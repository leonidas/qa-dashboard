
class PassRateBarChart extends WidgetBase
    width: 585
    side_width: 318

    height: 500
    side_height: 318

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
                alert:30
                passtargets: targets
                title: "Pass rate: #{hw}"

    format_header: ($t, cb) ->
        $t.find("h1 span.title").text @config.title
        cb? $t

    format_main_view: ($t, cb) ->
        @get_reports @config.groups, (reports) =>
            @reports = reports
            tr = $t.find('tbody tr')
            for r in reports
                row = tr.clone()
                passrate = r.total_pass*100/r.total_cases
                if passrate >= @config.alert
                    row.find('.alert img').hide()
                row.find('.title').text "#{r.profile} #{r.testtype}"
                row.find('.change').text " "
                container = row.find('div.pass-rate-bar')
                @draw_graph r, container
                row.insertBefore tr
            tr.remove()
            cb? $t

    format_small_view: ($t, cb) ->
        @get_reports @config.groups, (reports) =>
            @reports = reports
            cb?

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
        @config.alert = $form.find(".alert").val()
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
        cached.get "/query/qa-reports/latest/#{@config.hwproduct}", (data) =>
            reports  = _ data
            selected = _ groups
            cb reports.filter (r) ->
                selected.any (s) ->
                    s.hardware == r.hardware && s.testtype ==  r.testtype && s.profile == r.profile


    draw_graph: (report, elem) ->
        paper = Raphael(elem.get(0), 200,10)
        x = 0
        w = report.total_pass*200/report.total_cases
        pass = paper.rect(x,0,w,10)
        x += w
        w = report.total_fail*200/report.total_cases
        fail = paper.rect(x,0,w,10)
        x += w
        w = report.total_na*200/report.total_cases
        na = paper.rect(x,0,w,10)

        na.attr
            fill: "#C7C6C6"
            "stroke-width": 0
            stroke: null

        fail.attr
            fill: "#E7A6AB"
            "stroke-width": 0
            stroke: null

        pass.attr
            fill: "#309937"
            "stroke-width": 0
            stroke: null


return PassRateBarChart
