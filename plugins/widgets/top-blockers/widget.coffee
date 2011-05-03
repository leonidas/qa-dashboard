class TopBlockers extends WidgetBase

    get_default_config: (cb) ->
        hw = "N900"
        cached.get "/query/qa-reports/groups/#{hw}", (data) =>
            cb
                groups: data
                hwproduct: "N900"
                title: "Top Blockers: N900"
                num: 5

    same_group: (g1, g2) ->
        g1.hwproduct == g2.hwproduct && g1.testtype == g2.testtype && g1.target == g2.target

    contains_group: (arr, grp) -> _(arr).any (g) => @same_group(g,grp)

    format_main_view: ($t, cb) ->
        $t.find("h1 .hwproduct").text(@config.hwproduct)
        @format_bug_table $t, cb

    format_small_view: ($t, cb) ->
        $t.find("h2 .hwproduct").text(@config.hwproduct)
        @format_bug_table $t, cb

    format_settings_view: ($t, cb) ->
        hw = @config.hwproduct
        cached.get "/query/qa-reports/groups/#{hw}", (data) =>
            # set hardware
            $t.find("form .hwproduct").val(hw)

            # set title
            $t.find("form .title").val @config.title

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
                $row.find(".shiftcb").attr("checked", checked)
                $row.data("groupData", grp)

                $row.insertBefore $trow

            $trow.remove()
            if cb
                cb $t

    process_save_settings: ($form, cb) ->
        @config.hwproduct = $form.find(".hwproduct").val()
        @config.title = $form.find(".title").val()

        selected = []

        $rows = $form.find("table.multiple_select").find(".graph-target")
        $rows.each (idx, tr) =>
            $tr = $(tr)
            grp = $tr.data("groupData")
            checked = $tr.find(".shiftcb").attr("checked")
            if checked
                selected.push(grp)
        @config.groups = selected

        cb?()

    format_bug_table: ($t, cb) ->
        @get_top_bugs (bugs) ->
            $table = $t.find("table")
            $trow = $table.find("tr.row-template")
            _(bugs).each (bug) ->
                [count,bug_id,obj] = bug
                url = "https://bugs.meego.com/show_bug.cgi?id=" + bug_id
                title = if obj? then obj.short_desc else ""
                $row = $trow.clone()
                $row.find("td.bug_id a").attr("href", url).text(bug_id)
                $row.find("td.bug_description a").attr("href", url).text(title)
                $row.find("td.bug_blocker_count").text(count)
                $row.insertBefore $trow
            $trow.remove()
            cb $t


    get_top_bugs: (cb) ->
        hw = @config.hwproduct or "N900"
        num = @config.num or 5
        data =
            num: @config.num or 5
            groups: @config.groups
        cached.post "/query/bugzilla/top_for_groups", data, cb

return TopBlockers
