class TopBlockers extends QAReportsWidget

    get_default_config: (cb) ->
        hw = "N900"
        cached.get "/query/qa-reports/groups", (data) =>
            targets = {}
            ver = _.last _(data).keys()
            if not data[ver][hw]?
                hw  = _.first _(data[ver]).keys()

            groups = []
            for grp in data[ver][hw]
                groups.push grp
            cb
                groups: groups
                release: ver
                product: hw
                title: "Top Blockers: #{hw}"
                num: 5

    format_main_view: ($t, cb) ->
        @format_bug_table $t, cb

    format_small_view: ($t, cb) ->
        @format_bug_table $t, cb

    format_bug_table: ($t, cb) ->
        @get_top_bugs (bugs) ->
            $table = $t.find("table")
            $trow = $table.find("tr.row-template")
            _(bugs).each (bug) ->
                [count, id, url, obj] = bug
                title = if obj? then obj.short_desc else ""
                $row = $trow.clone()
                $row.find("td.bug_id a").attr("href", url).text(id)
                $row.find("td.bug_description a").attr("href", url).text(title)
                $row.find("td.bug_blocker_count").text(count)
                $row.insertBefore $trow
            $trow.remove()
            cb $t

    get_top_bugs: (cb) ->
        hw = @config.product or "N900"
        num = @config.num or 5
        data =
            num: @config.num or 5
            groups: @config.groups
        cached.post "/query/bugzilla/top_for_groups", data, cb

return TopBlockers
