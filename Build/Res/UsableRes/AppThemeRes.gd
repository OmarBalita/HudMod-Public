#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
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
	PINK,
	CUSTOM
}

enum FontPreset {
	OPEN_SANS,
	ROBOTO,
	NOTO_SANS,
	SOURCE_SANS_3,
	IBM_PLEX_SANS,
	CUSTOM
}

const DEFAULT_ACCENT_COLOR: Color = Color(.2, .388, .671, 1.)
const DEFAULT_ACCENT_HIGH_COLOR: Color = Color(0.362, 0.563, 0.868)

const MAX_UI_SCALE: float = 3.
const FONT_EXTENSIONS: Array[String] = [".ttf", ".otf", ".woff", ".woff2", ".ttc", ".otc"]

const FONT_PATHS: Dictionary[FontPreset, String] = {
	FontPreset.OPEN_SANS: "res://Asset/Fonts/OpenSans-Medium.ttf",
	FontPreset.ROBOTO: "res://Asset/Fonts/Roboto-Medium.ttf",
	FontPreset.NOTO_SANS: "res://Asset/Fonts/NotoSans-Medium.ttf",
	FontPreset.SOURCE_SANS_3: "res://Asset/Fonts/SourceSans3-Medium.ttf",
	FontPreset.IBM_PLEX_SANS: "res://Asset/Fonts/IBMPlexSans-Medium.ttf",
}

static var presets: Dictionary[ColorPreset, Array] = {
	ColorPreset.DEFAULT: [Color(.15, .15, .15), DEFAULT_ACCENT_COLOR, .15],
	ColorPreset.GRAY: [Color(.24, .24, .24, 1.), DEFAULT_ACCENT_COLOR, .25],
	ColorPreset.LIGHT: [Color(.85, .85, .85, 1.), DEFAULT_ACCENT_HIGH_COLOR, .4],
	ColorPreset.DARK: [Color(.08, .08, .08, 1.), DEFAULT_ACCENT_COLOR, .15],
	ColorPreset.PINK: [Color(0.239, 0.165, 0.208), Color(0.91, 0.365, 0.62), .15],
}

@export var content_scale: float = 1.:
	set(val): content_scale = clampf(val, .5, 1.5)

@export var auto_scale: bool = false
@export var auto_scale_reference_width: float = 1920.
@export var auto_scale_reference_height: float = 1080.
@export var auto_scale_min: float = .5
@export var auto_scale_max: float = 2.

@export var font_preset: FontPreset = FontPreset.IBM_PLEX_SANS:
	set(val):
		font_preset = val
		update_font.call_deferred()
 
@export var custom_font_path: String = "":
	set(val):
		custom_font_path = val
		if font_preset == FontPreset.CUSTOM:
			update_font.call_deferred()
 
@export_range(0., 1.) var font_embolden: float = 0.:
	set(val):
		font_embolden = clampf(val, 0., 1.)
		update_font.call_deferred()

@export var color_preset: ColorPreset = ColorPreset.DEFAULT:
	set(val):
		color_preset = val
		_update_local_colors()
		update_colors.call_deferred()

@export var base_color: Color:
	set(val): base_color = val; update_colors.call_deferred()
@export var accent_color: Color:
	set(val): accent_color = val; update_colors.call_deferred()
@export_range(-1., 1.) var contrast: float = .2:
	set(val): contrast = val; update_colors.call_deferred()

var _ui_font: FontVariation = FontVariation.new()

func _init() -> void:
	_update_local_colors()

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	var is_auto: Callable = func() -> bool: return get(&"auto_scale")
	var is_auto_cond: Array = [is_auto, [true]]
	var is_custom_font: Callable = func() -> bool: return get(&"font_preset") == FontPreset.CUSTOM
	var is_custom_font_cond: Array = [is_custom_font, [true]]
	var is_custom_color: Callable = func() -> bool: return get(&"color_preset") == ColorPreset.CUSTOM
	var is_custom_color_cond: Array = [is_custom_color, [true]]
	return {
		&"content_scale": export(float_args(content_scale, .5, 1.5, .05)),
		&"auto_scale": export(bool_args(auto_scale)),
		&"auto_scale_reference_width": export(float_args(auto_scale_reference_width, 640., 7680., 10.), is_auto_cond),
		&"auto_scale_reference_height": export(float_args(auto_scale_reference_height, 360., 4320., 10.), is_auto_cond),
		&"auto_scale_min": export(float_args(auto_scale_min, .25, 1., .05), is_auto_cond),
		&"auto_scale_max": export(float_args(auto_scale_max, 1., 3., .05), is_auto_cond),
		&"font_preset": export(options_args(font_preset, FontPreset)),
		&"custom_font_path": export(string_args(custom_font_path, IS.StringControllerType.TYPE_OPEN_FILE, FONT_EXTENSIONS), is_custom_font_cond),
		&"font_embolden": export(float_args(font_embolden, 0., 1., .05, .01, .1)),
		&"color_preset": export(options_args(color_preset, ColorPreset)),
		&"base_color": export(color_args(base_color), is_custom_color_cond),
		&"accent_color": export(color_args(accent_color), is_custom_color_cond),
		&"contrast": export(float_args(contrast, -1., 1., .05, .01, .1), is_custom_color_cond)
	}

func _custom_editor_spawned(edit_cont: EditContainer, props_editors: Dictionary[StringName, Control]) -> void:
	props_editors.base_color.controller.color_controller_popup_type = ColorButton.PopupType.POPUP_TYPE_WINDOWED
	props_editors.accent_color.controller.color_controller_popup_type = ColorButton.PopupType.POPUP_TYPE_WINDOWED

func _try_update_ctrlrs() -> void:
	if EditorServer and EditorServer.usable_ress_editors_has_editor_with_idx(self, 0):
		var controllers: Dictionary[StringName, Control] = EditorServer.usable_ress_editors_get_props_edits_conts(self, 0)
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


func get_ui_font() -> Font:
	var path: String = custom_font_path if font_preset == FontPreset.CUSTOM else FONT_PATHS[font_preset]
	if path.is_empty(): return null
	
	var base_font: FontFile = FontRes.load_custom_font(path)
	if base_font == null: return null
	
	# Reused so controls already holding it (theme overrides, draw code) follow font changes.
	_ui_font.base_font = base_font
	_ui_font.variation_embolden = font_embolden
	return _ui_font

func update_font() -> void:
	var font: Font = get_ui_font()
	if font == null: return

	for label_settings: LabelSettings in [IS.label_settings_main, IS.label_settings_header, IS.label_settings_bold]:
		label_settings.font = font

	ThemeDB.fallback_font = font
	ThemeDB.get_default_theme().default_font = font
	
	var project_theme: Theme = ThemeDB.get_project_theme()
	if project_theme: project_theme.default_font = font
	
	var tree := Engine.get_main_loop() as SceneTree 
	if tree == null: return
	var root: Window = tree.root
	if root.theme == null: root.theme = Theme.new()
	root.theme.default_font = font


func get_window_factor(window_size: Vector2i) -> float:
	if not auto_scale:
		return 1.
	var ratio: float = minf(
		window_size.x / maxf(auto_scale_reference_width, 1.),
		window_size.y / maxf(auto_scale_reference_height, 1.)
	)
	return clampf(ratio, auto_scale_min, maxf(auto_scale_max, auto_scale_min))

func get_ui_scale(window_size: Vector2i) -> float:
	return clampf(content_scale * get_window_factor(window_size), .25, MAX_UI_SCALE)
