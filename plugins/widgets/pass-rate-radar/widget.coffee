
class PassRateChart extends QAReportsWidget
    use_passtargets: true

    width: 585
    side_width: 270

    height: 500
    side_height: 270

    get_default_config: (cb) ->
        hw = "N900"
        cached.get "/query/qa-reports/groups", (data) ->
            targets = {}
            ver = _.last _(data).keys()
            if not data[ver][hw]?
                hw  = _.first _(data[ver]).keys()

            groups = []
            for grp in data[ver][hw]
                groups.push grp
            cb
                product: hw
                release: ver
                groups: groups
                alert:30
                passtargets: targets
                title: "Pass Rates: #{hw}"

    format_main_view: ($t, cb) ->
        @get_reports @config.groups, 1, (reports) =>
            @reports = reports
            @render_chart $t.find(".radar-chart")
            cb? $t

    format_small_view: ($t, cb) ->
        @get_reports @config.groups, 1, (reports) =>
            @reports = reports
            @render_small_chart $t.find(".radar-chart")
            cb? $t

    render_chart: (@chart_elem) ->
        @chart = new RadarChart @chart_elem, @width, @height
        @chart.render_reports(@reports, @config.passtargets)

    render_small_chart: (@chart_elem) ->
        @chart = new RadarChart @chart_elem, @side_width, @side_height
        @chart.render_reports(@reports, @config.passtargets, {labels:false})


class RadarChart extends QAReportsWidget
    constructor: (@elem, @width, @height) ->
        @paper = Raphael(@elem.get(0), @width, @height)

        @cx = @width * 0.5
        @cy = @height * 0.5
        @maxsize = @height * 0.35

    render_reports: (rs, targets, opts) ->
        self   = @
        opts ||= labels: true

        sumtotal    = (acc,x) -> acc + x.total_cases
        grand_total = _(rs).reduce sumtotal, 0

        # the sector width for a report will be 360*total_cases/grand_total
        # total_height = max_height * 50/pass_target

        a = 0

        obj = this
        maxsize = @maxsize
        if not opts.labels
            maxsize = maxsize*1.3

        titles = []
        target_sectors = []

        for r in rs
            title = self.group_key r
            arcw = 360 * r.total_cases/grand_total
            target = targets?[title]
            if not target?
                target = 0

            arch = maxsize

            target_sectors.push
                start: a
                end: a + arcw
                radius: arch*target/100

            apex = obj.group_arc a, arcw, arch, r.total_pass, r.total_fail, r.total_na
            a += arcw

            titles.push
                title:title
                apex:apex
                mid:a-arcw/2
                arcw:arcw
                href:r.url

        obj.render_alternative_target_circle target_sectors

        if opts.labels
            @render_titles titles


    render_alternative_target_circle: (sectors) ->
        p = drawSectorPath @paper, @cx, @cy, sectors
        p.attr
            "stroke-width": 2.5
            "stroke": "#004000"
            "stroke-opacity": 0.8
            fill: undefined

    render_titles: (titles) ->
        y = 10
        x = @width
        dir = 1
        prevy = 0
        for title in titles
            if title.arcw < 1
                continue
            if title.mid > 180 && dir == 1
                x = 0
                y = @height-10
                dir = -1
            mr = title.mid*Math.PI/180.0
            [ax,ay,tax,tay] = title.apex
            c = Math.cos(mr)
            ex = ax+Math.sin(mr)*5
            ey = ay-c*5

            ty = ey

            if Math.abs(ty-prevy) < 10 || (dir*ty < dir*prevy) || (Math.abs(c) > 0.5)
                ty = tay-c*5

            if ty < 10
                ty = 10
            if ty > @height - 10
                ty = @height - 10

            txt = @paper.text(x, ty-2, title.title)
            txt.attr
                #"stroke-opacity": 0.8
                "font-size": 10
                "font-family": "verdana"
                "stroke-width": 0.5
                "stroke": "#909090"
                href: title.href

            if dir == 1
                txt.attr("text-anchor", "end")
            else
                txt.attr("text-anchor", "start")

            line = @paper.path "M".concat [[x,ty],[ex,ty],[ex,ey]]
            line.attr
                stroke: "#a0a0a0"
                "stroke-width": 1
                "stroke-opacity": 0.5

            prevy = ty

    target_arc: (start, width, radius) ->
        cx = @cx
        cy = @cy

        a = drawArc @paper, cx, cy, start, start+width, radius
        a.attr
            "stroke-width": 3
            "stroke-color": "black"
            "stroke-opacity": 0.8
            fill: undefined
        return a


    group_arc: (start, width, length, pass, fail, na) ->
        cx = @cx
        cy = @cy

        total = pass+fail+na
        na_len = length
        pass_len = pass*length/total
        fail_len = (pass+fail)*length/total

        na_arc   = drawSector(@paper, cx, cy, start, start+width, na_len)
        fail_arc = drawSector(@paper, cx, cy, start, start+width, fail_len)
        pass_arc = drawSector(@paper, cx, cy, start, start+width, pass_len)
        outline  = na_arc.clone()

        na_arc.attr
            fill: "#C7C6C6"
            "stroke-width": 0
            stoke: undefined

        fail_arc.attr
            fill: "#E7A6AB"
            "stroke-width": 0
            stroke: undefined

        pass_arc.attr
            fill: "#309937"
            "stroke-width": 0
            stroke: undefined

        outline.attr
            fill: undefined,
            "stroke-width": 2
            stroke: "white"

        mid = (start + width/2.0)*Math.PI/180.0
        msin = Math.sin(mid)
        mcos = Math.cos(mid)
        [cx+msin*length,cy-mcos*length,cx+msin*@maxsize,cy-mcos*@maxsize]



return PassRateChart
