class_name FontRes extends UsableRes

const FONT_EXTENSIONS: Array[String] = [
	".ttf",
	".otf",
	".woff",
	".woff2",
	".fnt",
	".pfb",
	".pfm",
	".otc",
	".ttc"
]

static var builtin_fonts: Dictionary[StringName, SystemFont] = {}
static var custom_fonts: Dictionary[StringName, FontFile] = {}

func _init() -> void:
	use_global_variables_as_properties = false
	
	var font:= FontVariation.new()
	font.base_font = get_builtin_font(&"")
	
	register_props({
		&"system_font_name": "",
		&"custom_font_path": "",
		&"use_custom_font": false,
		&"font": font,
	}, &"_set_font_path_and_update")
	
	register_prop(&"face_index", 0, &"_set_face_index")
	register_prop(&"embolden", .0, &"_set_embolden")
	
	register_props({
		&"xx": 1.,
		&"yx": .0,
		&"xy": .0,
		&"yy": 1.,
		&"xo": .0,
		&"yo": .0,
	}, &"_set_transform_prop")
	
	register_prop(&"glyph", 0, &"_set_glyph")
	register_prop(&"space", 0, &"_set_space")
	register_prop(&"top", 0, &"_set_top")
	register_prop(&"bottom", 0, &"_set_bottom")

func _set_font_path_and_update(prop_key: StringName, prop_val: Variant) -> void:
	_set_prop_default(prop_key, prop_val)
	_update_base_font(get_font())
	_update_viewer_label_name()

func _set_face_index(prop_key: StringName, prop_val: int) -> void: _set_prop_default(prop_key, prop_val); get_font().variation_face_index = prop_val
func _set_embolden(prop_key: StringName, prop_val: float) -> void: _set_prop_default(prop_key, prop_val); get_font().variation_embolden = prop_val

func _set_transform_prop(prop_key: StringName, prop_val: float) -> void:
	_set_prop_default(prop_key, prop_val)
	update_transform()

func _set_glyph(prop_key: StringName, prop_val: int) -> void: _set_prop_default(prop_key, prop_val); get_font().spacing_glyph = prop_val
func _set_space(prop_key: StringName, prop_val: int) -> void: _set_prop_default(prop_key, prop_val); get_font().spacing_space = prop_val
func _set_top(prop_key: StringName, prop_val: int) -> void: _set_prop_default(prop_key, prop_val); get_font().spacing_top = prop_val
func _set_bottom(prop_key: StringName, prop_val: int) -> void: _set_prop_default(prop_key, prop_val); get_font().spacing_bottom = prop_val


func update_transform() -> void:
	get_font().variation_transform = Transform2D(
		Vector2(get_prop(&"xx"), get_prop(&"xy")),
		Vector2(get_prop(&"yx"), get_prop(&"yy")),
		Vector2(get_prop(&"xo"), get_prop(&"yo"))
	)


func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	
	var custom_func: Callable = get_prop.bind(&"use_custom_font")
	
	var font_label: Label = _extract_label()
	
	return {
		&"use_custom_font": export(bool_args(custom_func.call())),
		&"custom_font_path": export(string_args(get_prop(&"custom_font_path"), IS.StringControllerType.TYPE_OPEN_FILE, FONT_EXTENSIONS), [custom_func, [true]]),
		&"Choose Font": export_method(ExportMethodType.METHOD_CALLABLE, method_callable_args(
			_on_font_button_pressed,
			IS.color_accent,
			preload("res://Asset/Icons/font-adjustment.png")
		), [custom_func, [false]]),
		&"Font Viewer": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, [font_label]),
		
		&"Variation": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"face_index": export(int_args(get_prop(&"face_index"), 0)),
		&"embolden": export(float_args(get_prop(&"embolden"), -2., 2.)),
		&"Transform": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"xx": export(float_args(get_prop(&"xx"))),
		&"xy": export(float_args(get_prop(&"xy"))),
		&"yx": export(float_args(get_prop(&"yx"))),
		&"yy": export(float_args(get_prop(&"yy"))),
		&"xo": export(float_args(get_prop(&"xo"))),
		&"yo": export(float_args(get_prop(&"yo"))),
		&"_Transform": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		&"_Variation": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Extra Spacing": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"glyph": export(int_args(get_prop(&"glyph"))),
		&"space": export(int_args(get_prop(&"space"))),
		&"top": export(int_args(get_prop(&"top"))),
		&"bottom": export(int_args(get_prop(&"bottom"))),
		&"_Extra Spacing": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	}


static func get_builtin_font(name: StringName) -> SystemFont:
	if builtin_fonts.has(name):
		return builtin_fonts[name]
	else:
		var builtin_font: SystemFont = SystemFont.new()
		builtin_font.font_names = [name]
		builtin_fonts[name] = builtin_font
		return builtin_font


static func load_custom_font(path: StringName) -> FontFile:
	if custom_fonts.has(path):
		return custom_fonts[path]
	else:
		var custom_font: FontFile = FontFile.new()
		var data: PackedByteArray = FileAccess.get_file_as_bytes(String(path))
		if data.is_empty():
			return
		custom_font.data = data
		custom_fonts[path] = custom_font
		return custom_font

func get_font_name() -> String:
	if get_font().base_font == null: return "Font"
	else: return get_font().base_font.get_font_name()


func _update_base_font(font: FontVariation) -> void:
	get_font().base_font = load_custom_font(get_prop(&"custom_font_path")) if get_prop(&"use_custom_font") else get_builtin_font(get_prop(&"system_font_name"))

func _extract_label() -> Label:
	var label_settings:= LabelSettings.new()
	label_settings.font = get_font()
	label_settings.font_size = 24
	
	var label: Label = IS.create_label(get_font_name(), label_settings)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, 0)
	label.custom_minimum_size.y = 100.
	return label

func get_font() -> FontVariation: return get_prop(&"font")


func _update_viewer_label_name() -> void:
	EditorServer.get_usable_res_property_controller(self, &"Font Viewer").text = get_font_name()

func _on_font_button_pressed(usable_ress: Array[UsableRes]) -> void:
	
	var curr_font_names: PackedStringArray = get_prop(&"font").base_font.font_names
	var curr_font_name: String
	if curr_font_names.size():
		curr_font_name = curr_font_names[0]
	
	var fonts: Array = OS.get_system_fonts()
	var options: Array
	var check_group: CheckGroup = CheckGroup.new()
	
	check_group.checked_index = fonts.find_custom(func(element: String) -> bool:
		return curr_font_name == element
	)
	
	for font_name: String in fonts:
		var menu_option: MenuOption = MenuOption.new_checked(font_name, check_group)
		menu_option.function = _on_menu_option_pressed.bind(font_name)
		options.append(menu_option)
	
	var menu: PopupedMenu = IS.popup_menu(options, EditorServer.get_usable_res_controllers(self).get(&"Choose Font"))
	if menu:
		menu.loop_options(
			func(option_box: BoxContainer) -> void:
				var button: Button = option_box.get_child(0)
				button.add_theme_font_override("font", get_builtin_font(button.text))
		)

func _on_menu_option_pressed(font_name: StringName) -> void:
	set_prop(&"system_font_name", font_name)





