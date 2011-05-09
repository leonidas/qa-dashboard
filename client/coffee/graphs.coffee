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


window.drawArc = (paper, cx, cy, start, end, radius) ->
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
