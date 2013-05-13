
class PassRateBarChart extends QAReportsWidget
    use_alert: true
    use_passtargets: true

    bar_width: 130
    bar_height: 14

    small_bar_width: 90
    small_bar_height: 12

    history_width: 80
    history_height: 20

    history_num: 10

    get_default_config: (cb) ->
        super (cfg) ->
            cfg.alert       = 30
            cfg.title       = "Pass Rate: #{cfg.release} #{cfg.profile} #{cfg.testset}"
            cfg.passtargets = {}
            cb cfg

    format_main_view: ($t, cb) ->
        self    = @
        targets = @config.passtargets
        @get_reports @config.groups, @history_num, (reports) =>
            @reports = reports
            tr = $t.find('tbody tr')

            for rs in reports
                r = rs[0]
                row = tr.clone()
                if r.total_cases == 0
                    passrate = 0
                else
                    passrate = r.total_pass*100/(r.total_cases - r.total_measured)

                # Alert
                if passrate >= @config.alert
                    row.find('.alert img').hide()

                # Title
                row.find('.title a').attr("href", r.url).attr("title", r.title)

                self.set_row row, r

                # Age
                ms_in_day  = 1000 * 60 * 60 * 24
                report_age = "" + Math.floor(((new Date() - new Date(r.tested_at)) / ms_in_day))
                row.find('.age span').text "" + report_age

                # Change%
                ce = row.find('.change span')
                if rs.length > 1
                    prev = rs[1]
                    if prev.total_cases == 0
                        c = " "
                    else
                        ppr = prev.total_pass*100/(prev.total_cases - prev.total_measured)
                        delta = parseInt(passrate - ppr)
                        if delta > 0
                            c = "+#{delta}%"
                            ce.addClass "up"
                        else
                            if delta < 0
                                ce.addClass "down"
                            c = "#{delta}%"
                else
                    c = " "
                ce.text c

                # Pass Rate Bar
                container = row.find('div.pass-rate-bar')
                key = self.group_key r
                @draw_graph r, targets?[key], container

                # Pass Rate History
                container = row.find('div.pass-rate-history')
                @draw_history_graph rs, container

                row.insertBefore tr
            tr.remove()
            cb? $t

    format_small_view: ($t, cb) ->
        self    = @
        targets = @config.passtargets
        @get_reports @config.groups, @history_num, (reports) =>
            @reports = reports
            tr = $t.find('tbody tr')

            for rs in reports
                r = rs[0]
                row = tr.clone()
                if r.total_cases == 0
                    passrate = 0
                else
                    passrate = r.total_pass*100/(r.total_cases - r.total_measured)

                # Title
                row.find('.title a').attr("href", r.url).attr("title", r.title)

                self.set_row row, r

                # Pass Rate Bar
                container = row.find('div.pass-rate-bar')
                key = self.group_key r
                @draw_graph r, targets?[key], container

                row.insertBefore tr
            tr.remove()
            cb? $t


    draw_graph: (report, target, elem) ->
        if @dom.parent().hasClass 'sidebar'
            bw = @small_bar_width
            bh = @small_bar_height
        else
            bw = @bar_width
            bh = @bar_height

        m = 3
        m2 = m*2

        # Comment out for absolute
        max_total = report.total_cases - report.total_measured

        paper = Raphael(elem.get(0), bw,bh)
        x = 0
        w = report.total_pass*bw/max_total
        pass = paper.rect(x,m,w,bh-m2)
        x += w
        w = report.total_fail*bw/max_total
        fail = paper.rect(x,m,w,bh-m2)
        x += w
        w = report.total_na*bw/max_total
        na = paper.rect(x,m,w,bh-m2)

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

        if target > 0
            x = target*report.total_cases*bw/(max_total*100)
            paper.path("M#{x} 0L#{x} #{bh})").attr
                fill: null
                stroke: "#004000"
                "stroke-width": 1
                "stroke-opacity": 0.8

    draw_history_graph: (reports, elem) ->
        hw = @history_width
        hh = @history_height
        hn = @history_num

        paper = Raphael(elem.get(0), hw, hh)

        spacing = 2
        w = hw/hn - spacing

        x = hw
        for r in reports
            paper.rect(x-w,0,w,hh).attr
                fill: "#F1F0F0"
                "stroke-width": 0
                stroke: null

            if (r.total_cases > 0) and (r.total_pass > 0)
                h = r.total_pass*hh/r.total_cases

                paper.rect(x-w,hh-h,w,h).attr
                    fill: "#C7C6C6"
                    "stroke-width": 0
                    stroke: null

            x -= w + spacing



return PassRateBarChart
