
class RadarChart
    constructor: (@elem, @width, @height) ->
        @paper = Raphael(@elem, @width, @height)

        @cx = @width * 0.5
        @cy = @height * 0.5
        @maxsize = @height * 0.45

    render_reports: (rs) ->
        sumtotal = (acc,x) -> acc + x.total_cases
        grand_total = _(rs).reduce sumtotal, 0

        # the sector width for a report will be 360*total_cases/grand_total
        # total_height = max_height * 50/pass_target

        a = 0

        obj = this
        maxsize = @maxsize

        titles = _(rs).map (r) ->
            arcw = 360 * r.total_cases/grand_total
            target = Math.random()*30 + 60
            arch = maxsize * 50/target #r.pass_target
            apex = obj.group_arc a, arcw, arch, r.total_pass, r.total_fail, r.total_na
            a += arcw
            title = r.target + " " + r.testtype
            #console.log "a:"+a+" w:"+arcw+" h:"+arch+" t:"+title+" m:"+(a-arcw/2)
            return {title:title, apex:apex, mid:a-arcw/2, arcw:arcw}

        @render_target_circle()

        @render_titles titles


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
        for title in titles
            if title.arcw < 1
                continue
            if title.mid > 180 && dir == 1
                x = 0
                y = @height-10
                dir = -1
            mr = title.mid*Math.PI/180.0
            [ax,ay] = title.apex
            c = Math.cos(mr)
            ex = ax+Math.sin(mr)*5
            ey = ay-c*5
            dy = -(c*Math.abs(c*c*c*c*c*c*c*c))*30
            ty = ey + dy
            if ty < 10
                ty = 10
            if ty > @height - 10
                ty = @height - 10
            
            txt = @paper.text(x, ty, title.title)
            txt.attr
                "stroke-opacity": 0.8

            w = txt.getBBox().width + 10
            tx = x-dir*w
            line = @paper.path "M".concat [[tx,ty],[ex,ty],[ex,ey]]
            line.attr
                stroke: "#a0a0a0"
                "stroke-width": 1
                "stroke-opacity": 0.5
            if dir == 1
                txt.attr("text-anchor", "end")
            else
                txt.attr("text-anchor", "begin")
            y += dir*20


    group_arc: (start, width, length, pass, fail, na) ->
        cx = @cx
        cy = @cy

        total = pass+fail+na
        na_len = length
        pass_len = pass*length/total
        fail_len = (pass+fail)*length/total

        na_arc   = drawArc(@paper, cx, cy, start, start+width, na_len)
        fail_arc = drawArc(@paper, cx, cy, start, start+width, fail_len)
        pass_arc = drawArc(@paper, cx, cy, start, start+width, pass_len)
        outline  = na_arc.clone()

        na_arc.attr
            fill: "#C7C6C6"
            "stroke-width": 0

        fail_arc.attr
            fill: "#E7A6AB"
            "stroke-width": 0

        pass_arc.attr
            fill: "#309937"
            "stroke-width": 0

        outline.attr
            fill: undefined,
            "stroke-width": 2
            stroke: "white"

        mid = (start + width/2.0)*Math.PI/180.0
        [cx+Math.sin(mid)*length, cy-Math.cos(mid)*length]


drawArc = (paper, cx, cy, start, end, radius) ->
    start = start*Math.PI/180.0
    end = end*Math.PI/180.0
    sx = Math.sin(start)*radius + cx
    sy = -Math.cos(start)*radius + cy
    ex = Math.sin(end)*radius + cx
    ey = -Math.cos(end)*radius + cy
    s = "".concat "M",[cx,cy]
    s = s.concat  "L",[sx,sy]
    #s = s.concat  "L",[ex,ey],"Z"
    s = s.concat  "A",[radius,radius,0,0,1,ex,ey], "Z"
    paper.path(s)


window.RadarChart = RadarChart
