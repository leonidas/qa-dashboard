(function() {
  var RadarChart, drawArc;
  RadarChart = (function() {
    function RadarChart(elem, width, height) {
      this.elem = elem;
      this.width = width;
      this.height = height;
      this.paper = Raphael(this.elem.get(0), this.width, this.height);
      this.cx = this.width * 0.5;
      this.cy = this.height * 0.5;
      this.maxsize = this.height * 0.45;
    }
    RadarChart.prototype.render_reports = function(rs) {
      var a, grand_total, maxsize, obj, sumtotal, titles;
      sumtotal = function(acc, x) {
        return acc + x.total_cases;
      };
      grand_total = _(rs).reduce(sumtotal, 0);
      a = 0;
      obj = this;
      maxsize = this.maxsize;
      titles = _(rs).map(function(r) {
        var apex, arch, arcw, target, title, url;
        arcw = 360 * r.total_cases / grand_total;
        target = Math.random() * 30 + 60;
        arch = maxsize * 50 / target;
        apex = obj.group_arc(a, arcw, arch, r.total_pass, r.total_fail, r.total_na);
        a += arcw;
        title = r.target + " " + r.testtype;
        url = "http://qa-reports.meego.com/" + r.version + "/" + r.target + "/" + r.testtype + "/" + r.hwproduct + "/" + r.qa_id;
        return {
          title: title,
          apex: apex,
          mid: a - arcw / 2,
          arcw: arcw,
          href: url
        };
      });
      this.render_target_circle();
      return this.render_titles(titles);
    };
    RadarChart.prototype.render_target_circle = function() {
      var e, size;
      size = this.maxsize * 0.5;
      e = this.paper.ellipse(this.cx, this.cy, size, size);
      return e.attr({
        "stroke-width": 2,
        "stroke-color": "black",
        "stroke-opacity": 0.8,
        fill: void 0
      });
    };
    RadarChart.prototype.render_titles = function(titles) {
      var ax, ay, c, dir, ex, ey, line, mr, prevy, tax, tay, title, tx, txt, ty, w, x, y, _i, _len, _ref, _results;
      y = 10;
      x = this.width;
      dir = 1;
      prevy = 0;
      _results = [];
      for (_i = 0, _len = titles.length; _i < _len; _i++) {
        title = titles[_i];
        if (title.arcw < 1) {
          continue;
        }
        if (title.mid > 180 && dir === 1) {
          x = 0;
          y = this.height - 10;
          dir = -1;
        }
        mr = title.mid * Math.PI / 180.0;
        _ref = title.apex, ax = _ref[0], ay = _ref[1], tax = _ref[2], tay = _ref[3];
        c = Math.cos(mr);
        ex = ax + Math.sin(mr) * 5;
        ey = ay - c * 5;
        ty = ey;
        if (Math.abs(ty - prevy) < 10 || (dir * ty < dir * prevy) || (Math.abs(c) > 0.5)) {
          ty = tay - c * 5;
        }
        if (ty < 10) {
          ty = 10;
        }
        if (ty > this.height - 10) {
          ty = this.height - 10;
        }
        txt = this.paper.text(x, ty, title.title);
        txt.attr({
          "stroke-opacity": 0.8,
          href: title.href
        });
        w = txt.getBBox().width + 10;
        tx = x - dir * w;
        line = this.paper.path("M".concat([[tx, ty], [ex, ty], [ex, ey]]));
        line.attr({
          stroke: "#a0a0a0",
          "stroke-width": 1,
          "stroke-opacity": 0.5
        });
        if (dir === 1) {
          txt.attr("text-anchor", "end");
        } else {
          txt.attr("text-anchor", "begin");
        }
        _results.push(prevy = ty);
      }
      return _results;
    };
    RadarChart.prototype.group_arc = function(start, width, length, pass, fail, na) {
      var cx, cy, fail_arc, fail_len, mcos, mid, msin, na_arc, na_len, outline, pass_arc, pass_len, total;
      cx = this.cx;
      cy = this.cy;
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
      outline.attr({
        fill: void 0,
        "stroke-width": 2,
        stroke: "white"
      });
      mid = (start + width / 2.0) * Math.PI / 180.0;
      msin = Math.sin(mid);
      mcos = Math.cos(mid);
      return [cx + msin * length, cy - mcos * length, cx + msin * this.maxsize, cy - mcos * this.maxsize];
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
  window.graphs = {};
  window.graphs.RadarChart = RadarChart;
}).call(this);
