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
class_name ColorPaletteRes extends UsableRes

@export var palette_name: String
@export var colors: Array
@export var built_in: bool = false

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"palette_name": export(string_args(palette_name)),
		&"colors": export(list_args(colors, &"Color"))
	}

func get_palette_name() -> String:
	return palette_name

func set_palette_name(new_val: String) -> void:
	palette_name = new_val

func get_colors() -> Array:
	return colors

func set_colors(new_val: Array) -> void:
	colors = new_val

func get_built_in() -> bool:
	return built_in

func set_built_in(new_val: bool) -> void:
	built_in = new_val


static func new_res(_palette_name: String, _colors: Array, _built_in: bool = true) -> ColorPaletteRes:
	var res:= ColorPaletteRes.new()
	res.palette_name = _palette_name
	res.colors = _colors
	res.built_in = _built_in
	return res
