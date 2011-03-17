(function() {
  var RadarChart, drawArc;
  RadarChart = (function() {
    function RadarChart(elem, width, height) {
      this.elem = elem;
      this.width = width;
      this.height = height;
      this.paper = Raphael(this.elem, this.width, this.height);
      this.group_arc(0, 50, 120, 5, 10, 20);
      this.group_arc(50, 70, 140, 10, 5, 5);
      this.group_arc(120, 30, 110, 30, 3, 0);
      this.group_arc(150, 40, 100, 10, 3, 5);
      this.group_arc(190, 50, 120, 3, 5, 2);
      this.group_arc(240, 80, 130, 3, 3, 10);
      this.group_arc(320, 40, 100, 5, 4, 2);
    }
    RadarChart.prototype.group_arc = function(start, width, length, pass, fail, na) {
      var cx, cy, fail_arc, fail_len, na_arc, na_len, outline, pass_arc, pass_len, total;
      cx = this.width * 0.5;
      cy = this.height * 0.5;
      total = pass + fail + na;
      na_len = length;
      pass_len = pass * length / total;
      fail_len = (pass + fail) * length / total;
      na_arc = drawArc(this.paper, cx, cy, start, start + width, na_len);
      fail_arc = drawArc(this.paper, cx, cy, start, start + width, fail_len);
      pass_arc = drawArc(this.paper, cx, cy, start, start + width, pass_len);
      outline = na_arc.clone();
      na_arc.attr({
        fill: "#C7C6C6",
        "stroke-width": 0
      });
      fail_arc.attr({
        fill: "#E7A6AB",
        "stroke-width": 0
      });
      pass_arc.attr({
        fill: "#309937",
        "stroke-width": 0
      });
      return outline.attr({
        fill: void 0,
        "stroke-width": 2,
        stroke: "white"
      });
    };
    return RadarChart;
  })();
  drawArc = function(paper, cx, cy, start, end, radius) {
    var ex, ey, s, sx, sy;
    start = start * Math.PI / 180.0;
    end = end * Math.PI / 180.0;
    sx = Math.sin(start) * radius + cx;
    sy = -Math.cos(start) * radius + cy;
    ex = Math.sin(end) * radius + cx;
    ey = -Math.cos(end) * radius + cy;
    s = "".concat("M", [cx, cy]);
    s = s.concat("L", [sx, sy]);
    s = s.concat("A", [radius, radius, 0, 0, 1, ex, ey], "Z");
    return paper.path(s);
  };
  window.RadarChart = RadarChart;
}).call(this);
