class TopBlockers extends WidgetBase

    get_default_config: (cb) -> cb {hwproduct:"N900", num:5}

    format_main_view: ($t, cb) ->
        $t.find("h1 .hwproduct").text(@config.hwproduct)
        @format_bug_table $t, cb

    format_small_view: ($t, cb) ->
        $t.find("h2 .hwproduct").text(@config.hwproduct)
        @format_bug_table $t, cb

    format_bug_table: ($t, cb) ->
        @get_top_bugs (bugs) ->
            $table = $t.find("table")
            $trow = $table.find("tr.row-template")
            _(bugs).each (bug) ->
                [count,bug_id,obj] = bug
                url = "https://bugs.meego.com/show_bug.cgi?id=" + bug_id
                title = obj.short_desc
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
        cached.get "/bugs/#{hw}/top/#{num}", cb
