Raphael = require 'raphael'

class TopBlockers extends QAReportsWidget

    get_default_config: (cb) ->
        super (cfg) ->
            cfg.title = "Top Blockers: #{cfg.release} #{cfg.profile} #{cfg.testset}"
            cfg.num   = 5
            cb cfg

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
