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
class_name ColorButton extends Button

signal color_changed(color: Color)

enum PopupType {
	POPUP_TYPE_EMBEDED,
	POPUP_TYPE_WINDOWED
}

@export var color_controller_popup_type: PopupType

var curr_color: Color

func _ready() -> void:
	pressed.connect(on_pressed)

func _draw() -> void:
	var rect_margin_size:= Vector2(5, 5)
	var rect:= Rect2(rect_margin_size, size - rect_margin_size * 2.)
	
	if curr_color.a != 1.:
		var grid_rect_size: Vector2 = Vector2(10., 10.)
		var grid_count:= rect.size / grid_rect_size / 2.
		
		draw_rect(rect, Color.WHITE)
		for y: int in grid_count.y + 1:
			var x_offset: float = (y % 2) * grid_rect_size.x
			for x: int in grid_count.x:
				var grid_rect_pos:= Vector2(x * 2., y) * grid_rect_size + Vector2(x_offset, .0)
				draw_rect(
					Rect2(
						rect_margin_size + grid_rect_pos,
						grid_rect_size
					).intersection(rect), Color.DIM_GRAY
				)
	
	draw_rect(rect, curr_color)

func get_curr_color() -> Color:
	return curr_color

func set_curr_color(new_color: Color, emit_change: bool = true) -> void:
	curr_color = new_color
	if emit_change:
		color_changed.emit(curr_color)
	queue_redraw()

func set_curr_color_manually(new_color: Color) -> void:
	set_curr_color(new_color, false)

func on_pressed() -> void:
	var color_controller: PopupedColorController
	if color_controller_popup_type: color_controller = WindowManager.popup_color_controller_window(get_window(), curr_color)
	else: color_controller = IS.popup_color_controller(curr_color, self, get_window())
	color_controller.color_changed.connect(set_curr_color)






