#
# This file is part of Meego-QA-Dashboard
#
# Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#

arcPoints = (cx, cy, start, end, radius) ->
    start = start*Math.PI/180.0
    end = end*Math.PI/180.0

    sx: Math.sin(start)*radius + cx
    sy: -Math.cos(start)*radius + cy
    ex: Math.sin(end)*radius + cx
    ey: -Math.cos(end)*radius + cy

sectorPath = (cx, cy, start, end, radius) ->
    l = end - start
    large_arc = if l>180 then 1 else 0
    p = arcPoints(cx, cy, start, end, radius)
    s = "".concat "M",[cx,cy]
    s = s.concat  "L",[p.sx,p.sy]
    s = s.concat  "A",[radius,radius,0,large_arc,1,p.ex,p.ey], "Z"

arcPath = (cx, cy, start, end, radius) ->
    l = end - start
    large_arc = if l>180 then 1 else 0
    p = arcPoints(cx, cy, start, end, radius)
    s = "".concat "M",[p.sx,p.sy]
    s = s.concat  "A",[radius,radius,0,large_arc,1,p.ex,p.ey], "Z"

window.arcPoints = arcPoints

window.drawSector = (paper, cx, cy, start, end, radius) ->
    s = sectorPath(cx,cy,start,end,radius)
    paper.path(s)

window.drawArc = (paper, cx, cy, start, end, radius) ->
    s = arcPath(cx,cy,start,end,radius)
    paper.path(s)

