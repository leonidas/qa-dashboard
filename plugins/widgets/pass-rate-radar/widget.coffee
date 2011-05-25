
class PassRateChart extends WidgetBase
    width: 585
    side_width: 270

    height: 500
    side_height: 270

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
                title: "Pass rate: #{hw}"

    format_main_view: ($t, cb) ->
        @get_reports @config.groups, (reports) =>
            @reports = reports
            @render_chart $t.find(".radar-chart")
            cb? $t

    format_small_view: ($t, cb) ->
        @get_reports @config.groups, (reports) =>
            @reports = reports
            @render_small_chart $t.find(".radar-chart")
            cb? $t

    format_settings_groups: ($trow, $dst) ->

    format_settings_view: ($t, cb) ->
        cfg = @config

        init_hw  = cfg.hwproduct
        init_ver = cfg.release

        groups   = cfg.groups
        targets  = cfg.passtargets

        g_ = _(groups)
        if not g_.isArray()
            cfg.groups = groups = g_.toArray()

        selected = contains_group groups

        createRadioButtons = (parent, data, checked, func) ->
            # Generate Radio Buttons from Templates
            rel = parent
            inputTmpl = rel.find("input").first().clone().unbind().removeAttr "id"
            labelTmpl = rel.find("label").first().clone().unbind().removeAttr "for"
            inputTmpl.removeAttr "checked"
            rel.empty()
            inputTmpl.appendTo(rel).hide()
            labelTmpl.appendTo(rel).hide()

            found = false
            for k of data
                do (k) ->
                    i = inputTmpl.clone().show()
                    l = labelTmpl.clone().show()
                    if k == checked
                        i.attr('checked','checked')
                        found = true
                    i.val k
                    l.text k
                    i.appendTo rel
                    l.appendTo rel
                    l.click ->
                        i.click()
                        func?(k)
            if not found
                parent.find("input").first().click()

        updateSelectedSets = (data) ->
            parent = $t.find("table.multiple_select")
            body   = parent.find("tbody.selected-group")
            tmpl   = body.find("tr").first().clone().unbind()
            body.empty()
            tmpl.appendTo(body).hide()

            for g in data
                do (g) ->
                    return if not selected g

                    row = tmpl.clone().show()
                    key = group_key g

                    checkbox = row.find('input.shiftcb')
                    checkbox.attr("checked", "checked").val key
                    checkbox.unbind()

                    row.find('span.target').text g.profile
                    row.find('strong.testtype').text g.testtype

                    passtarget = row.find('input.passtarget')
                    pt = targets[key] ? "0"
                    passtarget.val pt
                    passtarget.data "test-group", g

                    checkbox.click ->
                        remove_group groups, g
                        updateSelectedSets(data)
                        updateSuggestions(data)

                    row.appendTo body

            balance_columns()

        $hilight = $('<span class="hilight"/>')
        hilight_span = (span, text, hilights, i) ->
            span.empty()
            cur = 0
            for h in hilights
                start = h.start - i
                end   = h.end - i
                if start < 0 or start >= text.length
                    continue
                else
                    $h = $hilight.clone()
                    if start > cur
                        span.append text.slice(cur,start)
                    span.append $h.text text.slice(start, end)
                    cur = end
            span.append text.slice(cur)


        updateSuggestions = (data) ->
            parent = $t.find("table.multiple_select")
            body   = parent.find("tbody.suggestion-group")
            tmpl   = body.find("tr").first().clone().unbind()
            body.empty()
            tmpl.appendTo(body).hide()

            normalize = (s) ->
                $.trim(s).toLowerCase().replace(/\s+/, " ")

            filter = parent.find("input.filters")
            expr  = normalize filter.val()
            words = expr.split(" ")

            pattern = words.join(".*")
            regexp  = new RegExp(pattern, "i")

            filter.unbind().keydown ->
                f = () ->
                    updateSuggestions(data) if normalize filter.val() != expr
                setTimeout f, 1

            for g in data
                do (g) ->
                    return if selected g
                    key = group_key g

                    hilights = []
                    if expr != ""
                        return if not regexp.test(key)
                        kl = key.toLowerCase()
                        for w in words
                            i = kl.search(w)
                            hilights.push
                                start: i
                                end: i + w.length

                    row = tmpl.clone().show()

                    checkbox = row.find('input.shiftcb')
                    checkbox.removeAttr("checked").val key
                    checkbox.unbind()

                    span = row.find('span.target')
                    hilight_span span, g.profile, hilights, 0

                    span = row.find('strong.testtype')
                    hilight_span span, g.testtype, hilights, g.profile.length+1

                    checkbox.click ->
                        groups.push g
                        updateSelectedSets(data)
                        updateSuggestions(data)

                    row.appendTo body

            balance_columns()



        createTestSets = (data) ->
            updateSelectedSets(data)
            updateSuggestions(data)
            balance_columns()


        cached.get "/query/qa-reports/groups", (data) ->
            currentHw  = () -> hwsel.find("input:checked").val()
            currentVer = () -> relsel.find("input:checked").val()

            selectRelease = (ver) ->
                hw = currentHw()
                createRadioButtons hwsel, data[ver], hw, selectHw
                hw = currentHw()
                createTestSets data[ver][hw]

            selectHw = (hw) ->
                ver = currentVer()
                createTestSets data[ver][hw]

            # Generate Release Radio Buttons
            relsel = $t.find("form div.release")
            createRadioButtons relsel, data, init_ver, selectRelease

            # Generate Handware Radio Buttons
            hwsel = $t.find("form div.hardware")
            createRadioButtons hwsel, data[init_ver], init_hw, selectHw

            # Generate List of Test Sets
            createTestSets data[init_ver][init_hw]

            cb? $t

    process_save_settings: ($form, cb) ->
        @config = {}

        @config.release = $form.find("div.release input:checked").val()
        @config.hwproduct = $form.find("div.hardware input:checked").val()
        @config.alert = $form.find("input.alert").val()

        selected = []
        passtargets = {}

        $rows = $form.find("table.multiple_select tbody.selected-group tr")
        for tr in $rows
            $tr = $(tr)
            $checkbox   = $tr.find('input.shiftcb')
            $passtarget = $tr.find('input.passtarget')

            grp = $passtarget.data("test-group")
            if not grp?
                continue
            selected.push(grp)

            target = parseInt($tr.find(".passtarget").val())
            if not target > 0
                target = 0

            passtargets[group_key(grp)] = parseInt(target)

        @config.groups = selected
        @config.passtargets = passtargets

        #console.log selected
        #console.log @config

        cb?()

    get_reports: (groups, cb) ->
        url = "/query/qa-reports/latest/#{@config.release}/#{@config.hwproduct}"
        groups = _(@config.groups).toArray()
        f = contains_group groups
        cached.get url, (data) ->
            cb _(data).filter f

    render_chart: (@chart_elem) ->
        @chart = new RadarChart @chart_elem, @width, @height
        @chart.render_reports(@reports, @config.passtargets)

    render_small_chart: (@chart_elem) ->
        @chart = new RadarChart @chart_elem, @side_width, @side_height
        @chart.render_reports(@reports, @config.passtargets, {labels:false})


class RadarChart
    constructor: (@elem, @width, @height) ->
        @paper = Raphael(@elem.get(0), @width, @height)

        @cx = @width * 0.5
        @cy = @height * 0.5
        @maxsize = @height * 0.35

    render_reports: (rs, targets, opts) ->
        if opts == undefined
            opts = {labels:true}
        sumtotal = (acc,x) -> acc + x.total_cases
        grand_total = _(rs).reduce sumtotal, 0

        # the sector width for a report will be 360*total_cases/grand_total
        # total_height = max_height * 50/pass_target

        a = 0

        obj = this
        maxsize = @maxsize
        if not opts.labels
            maxsize = maxsize*1.3

        ###
        titles = _(rs).map (r) ->
            title = "#{r.profile} #{r.testtype}"
            arcw = 360 * r.total_cases/grand_total
            target = targets[title]
            if target == undefined || target < 50
                target = 50
            arch = maxsize * 50/target
            apex = obj.group_arc a, arcw, arch, r.total_pass, r.total_fail, r.total_na
            obj.target_arc a, arcw,
            a += arcw
            url  = "http://qa-reports.meego.com/#{r.release}/#{r.profile}/#{r.testtype}/#{r.hardware}/#{r.qa_id}"
            return {title:title, apex:apex, mid:a-arcw/2, arcw:arcw, href:url}

        @render_target_circle()
        ###
        titles = []
        target_sectors = []

        for r in rs
            title = "#{r.profile} #{r.testtype}"
            arcw = 360 * r.total_cases/grand_total
            target = targets[title]
            if not target?
                target = 0

            arch = maxsize

            target_sectors.push
                start: a
                end: a + arcw
                radius: arch*target/100

            apex = obj.group_arc a, arcw, arch, r.total_pass, r.total_fail, r.total_na
            a += arcw
            ## TODO: hardcoded url to qa-reports
            url  = "http://qa-reports.meego.com/#{r.release}/#{r.profile}/#{r.testtype}/#{r.hardware}/#{r.qa_id}"

            titles.push
                title:title
                apex:apex
                mid:a-arcw/2
                arcw:arcw
                href:url

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

    render_target_circle: ->
        size = @maxsize*0.5
        e = @paper.ellipse @cx, @cy, size, size
        e.attr
            "stroke-width": 2
            "stroke-color": "black"
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


group_key = (grp) ->
    "#{grp.profile} #{grp.testtype}".replace('.',':')

same_group = (g1, g2) -> group_key(g1) == group_key(g2)

contains_group = (arr) -> (grp) ->
    for g in arr
        return true if same_group(g,grp)
    return false

remove_group = (arr, grp) ->
    for i,g of arr
        if same_group(g,grp)
            arr.splice(i,1)
            return

return PassRateChart
