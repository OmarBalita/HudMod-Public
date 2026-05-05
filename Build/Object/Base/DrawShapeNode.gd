#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
##  This program is free software: you can redistribute it and/or modify   ##
##  it under the terms of the GNU General Public License as published by   ##
##  the Free Software Foundation, either version 3 of the License, or      ##
##  (at your option) any later version.                                    ##
##                                                                         ##
##  This program is distributed in the hope that it will be useful,        ##
##  but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           ##
##  GNU General Public License for more details.                           ##
##                                                                         ##
##  You should have received a copy of the GNU General Public License      ##
##  along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
@abstract class_name DrawShapeNode extends Node2D

func draw_shape(draw_shape_comp: DrawShapeComponentRes) -> void:
	if draw_shape_comp.just_store:
		return
	
	var all_points: Array[PackedVector2Array] = draw_shape_comp.all_points
	var color: Color = draw_shape_comp.color
	
	if draw_shape_comp.stroke_size:
		var stroke_width: float = draw_shape_comp.stroke_size
		var stroke_color: Color = draw_shape_comp.stroke_color
		for points: PackedVector2Array in all_points:
			draw_polyline(points, stroke_color, stroke_width, true)
	
	var colors:= PackedColorArray([color])
	for points: PackedVector2Array in all_points:
		draw_polygon(points, colors)

