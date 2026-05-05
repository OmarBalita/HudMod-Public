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
class_name TimeMarkerRes extends Resource

@export var custom_name: StringName
@export var custom_color: Color = IS.RAINBOW_COLORS[2]
@export_multiline var custom_description: String

func set_custom_name(new_val: StringName) -> void:
	custom_name = new_val

func get_custom_name() -> StringName:
	return custom_name

func set_custom_color(new_val: Color) -> void:
	custom_color = new_val

func get_custom_color() -> Color:
	return custom_color

func set_custom_description(new_val: String) -> void:
	custom_description = new_val

func get_custom_description() -> String:
	return custom_description
