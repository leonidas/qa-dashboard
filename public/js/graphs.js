(function() {
  var RadarChart;
  RadarChart = (function() {
    function RadarChart(selector, width, height) {
      var bg;
      this.width = width;
      this.height = height;
      this.elem = $(selector);
      this.paper = Raphael(this.elem, this.width, this.height);
      bg = paper.rect(0, 0, this.width, this.height);
      bg.attr({
        fill: "#ababcc"
      });
    }
    return RadarChart;
  })();
  window.RadarChart = RadarChart;
}).call(this);
