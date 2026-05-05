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
class_name FlexGridContainer extends GridContainer

var control_size: Vector2:
	set(val):
		control_size = val
		queue_redraw()

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _draw() -> void:
	var h_count = int(size.x / (control_size.x + get_theme_constant("h_separation")))
	columns = h_count

func get_control_size() -> Vector2:
	return control_size

func set_control_size(new_control_size: Vector2) -> void:
	control_size = new_control_size
