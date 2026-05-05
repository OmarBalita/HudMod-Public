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
class_name AppThemeRes extends UsableRes

enum ColorPreset {
	DEFAULT,
	GRAY,
	LIGHT,
	DARK,
	CUSTOM
}
const DEFAULT_ACCENT_COLOR: Color = Color(.2, .388, .671, 1.)
const DEFAULT_ACCENT_HIGH_COLOR: Color = Color(0.362, 0.563, 0.868)

static var presets: Dictionary[ColorPreset, Array] = {
	ColorPreset.DEFAULT: [Color(.15, .15, .15), DEFAULT_ACCENT_COLOR, .15],
	ColorPreset.GRAY: [Color(.24, .24, .24, 1.), DEFAULT_ACCENT_COLOR, .25],
	ColorPreset.LIGHT: [Color(.85, .85, .85, 1.), DEFAULT_ACCENT_HIGH_COLOR, .4],
	ColorPreset.DARK: [Color(.08, .08, .08, 1.), DEFAULT_ACCENT_COLOR, .15],
}

@export var content_scale: float = 1.:
	set(val): content_scale = clampf(val, .5, 1.5)

@export var color_preset: ColorPreset = ColorPreset.DEFAULT:
	set(val):
		color_preset = val
		_update_local_colors()
		update_colors()

@export var base_color: Color:
	set(val): base_color = val; update_colors()
@export var accent_color: Color:
	set(val): accent_color = val; update_colors()
@export_range(-1., 1.) var contrast: float = .2:
	set(val): contrast = val; update_colors()

func _init() -> void:
	_update_local_colors()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var is_custom: Callable = func() -> bool: return get(&"color_preset") == ColorPreset.CUSTOM
	var is_custom_cond: Array = [is_custom, [true]]
	return {
		&"content_scale": export(float_args(content_scale, .5, 1.5, .05)),
		&"color_preset": export(options_args(color_preset, ColorPreset)),
		&"base_color": export(color_args(base_color), is_custom_cond),
		&"accent_color": export(color_args(accent_color), is_custom_cond),
		&"contrast": export(float_args(contrast, -1., 1., .05, .01, .1), is_custom_cond)
	}

func _exported_props_controllers_created(main_edit: EditContainer, props_controls: Dictionary[StringName, Control]) -> void:
	props_controls.base_color.controller.color_controller_popup_type = ColorButton.PopupType.POPUP_TYPE_WINDOWED
	props_controls.accent_color.controller.color_controller_popup_type = ColorButton.PopupType.POPUP_TYPE_WINDOWED

func _try_update_ctrlrs() -> void:
	if EditorServer and EditorServer.has_usable_res_controllers(self):
		var controllers: Dictionary[StringName, Control] = EditorServer.get_usable_res_controllers(self)
		controllers.base_color.set_curr_value(base_color)
		controllers.accent_color.set_curr_value(accent_color)
		controllers.contrast.set_curr_value(contrast)

func _update_local_colors() -> void:
	if color_preset != ColorPreset.CUSTOM:
		var preset: Array = presets[color_preset]
		base_color = preset[0]
		accent_color = preset[1]
		contrast = preset[2]
		_try_update_ctrlrs()

func update_colors() -> void:
	IS.update_colors(base_color, accent_color, contrast)



