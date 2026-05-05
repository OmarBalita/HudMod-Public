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
class_name ProcessingControl extends ColorRect

@export var radius: float = 30.0
@export var width: float = 5.0
@export var speed: float = .01
@export var back_offset: float = 1.0
@export_range(3, 100) var subdivision: int = 24

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var time = Time.get_ticks_msec() * speed
	var pos = size/2
	var tail = 3.15 + time
	draw_arc(pos, radius, time - back_offset, tail - back_offset, subdivision, Color(IS.color_accent, .5), width, true)
	draw_arc(pos, radius, time, tail, subdivision, IS.color_accent, width, true)
