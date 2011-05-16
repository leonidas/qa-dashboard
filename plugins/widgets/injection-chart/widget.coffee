class InjectionChart extends WidgetBase
    width: 585
    side_width: 318

    height: 318
    side_height: 318

    get_default_config: (cb) ->
        hw = "N900"
        cached.get "/query/qa-reports/groups/#{hw}", (data) =>
            cb
                groups: data
                hwproduct: hw
                title: "Open Bugs: " + hw
    
    format_header: ($t, cb) ->
        $t.find("h1 span.title").text @config.title
        cb? $t        

    format_main_view: ($t, cb) ->
        @chart = new BarChart $t.find(".injection-chart"), @width, @height        
        @chart.render()
        cb? $t

class BarChart
    constructor: (@elem, @width, @height) ->

    render: () ->
        values = [[10,20,30,40,10,20,30,40,0,0,0,0]]
        labels = ["wk05", "wk06", "wk07", "wk08", "wk09", "wk10", "wk11", "wk12", "wk13", "wk14", "wk15", "wk16"]
        opts =  gutter: "75%"

        @paper = Raphael(@elem.get(0), @width, @height)

        #  (x, y, width, height, values, opts)
        @new_bugs = @paper.g.barchart(25, 20, @width, 140, values, opts)            
            .attr fill: "#cbcbcb"
        
        @paper.path("M".concat [[45, 140], [@width, 140]]).attr(stroke: '#eaeaea', 'stroke-width': 1)
        @paper.path("M".concat [[45, 141], [@width, 141]]).attr(stroke: '#d5d5d5', 'stroke-width': 1)

        @total_cases = @paper.g.barchart(24, 180, @width, 100, values, opts)            
            .attr fill: "#eaddcd"

        @paper.path("M".concat [[45, 260], [@width, 260]]).attr(stroke: '#eaeaea', 'stroke-width': 1)
        @paper.path("M".concat [[45, 261], [@width, 261]]).attr(stroke: '#d5d5d5', 'stroke-width': 1)

        @new_bugs.hover(@hoverIn("#d22323"), @hoverOut("#cbcbcb"))
        @total_cases.hover(@hoverIn("#eca451"), @hoverOut("#eaddcd"))
        
        @labels()
        _(@total_cases.bars[0]).each (bar, index) =>
            label = @paper.text(bar.x, @height-30, labels[index])
            label.attr font: "14px Arial", fill: "#adadad"
            if bar.value > 0
                label.attr fill: "#666666"


    hoverIn: (color) ->
        () ->
            @bar.attr fill: color
            @label = null
            if @bar.value > 0
                @label = @paper.text(@bar.x, @bar.y - 10, @bar.value || "0").insertBefore(this)
                @label.attr font:"14px Arial", "font-weight": "bold", "fill": "#000"

    hoverOut: (color) ->
        () ->
            @bar.attr fill: color
            if @label?
                @label.animate({opacity: 0}, 200, () -> @remove())

    labels: () ->
        attrs = font: '11px Arial', fill: "#a7a7a7"        
        @paper.text(15, 125, "New").attr(attrs)
        @paper.text(15, 137, "bugs").attr(attrs)
        @paper.text(15, @height - 60, "Total").attr(attrs)
        @paper.text(15, @height - 48, "test").attr(attrs)
        @paper.text(15, @height - 36, "cases").attr(attrs)

return InjectionChart
