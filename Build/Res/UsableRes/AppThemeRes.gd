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
		&"color_preset": export(options_args(color_preset, ColorPreset)),
		&"base_color": export(color_args(base_color), is_custom_cond),
		&"accent_color": export(color_args(accent_color), is_custom_cond),
		&"contrast": export(float_args(contrast, -1., 1., .05, .01, .1), is_custom_cond)
	}

func _exported_props_controllers_created(main_edit: EditBoxContainer, props_controllers: Dictionary[StringName, Control]) -> void:
	props_controllers.base_color.controller.color_controller_popup_type = ColorButton.PopupType.POPUP_TYPE_WINDOWED
	props_controllers.accent_color.controller.color_controller_popup_type = ColorButton.PopupType.POPUP_TYPE_WINDOWED

func _try_update_ctrlrs() -> void:
	if EditorServer and EditorServer.has_usable_res_controllers(self):
		var controllers: Dictionary[StringName, Control] = EditorServer.get_usable_res_controllers(self)
		controllers.base_color.set_curr_val(base_color, true, false)
		controllers.accent_color.set_curr_val(accent_color, true, false)
		controllers.contrast.set_curr_val(contrast, true, false)

func _update_local_colors() -> void:
	if color_preset != ColorPreset.CUSTOM:
		var preset: Array = presets[color_preset]
		base_color = preset[0]
		accent_color = preset[1]
		contrast = preset[2]
		_try_update_ctrlrs()

func update_colors() -> void:
	IS.update_colors(base_color, accent_color, contrast)



