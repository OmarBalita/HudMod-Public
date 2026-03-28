class_name TimeMarker2 extends Button

static var rainbow_styles: Array[StyleBoxFlat] = get_rainbow_styles()

@export var frame: int
@export var timemarker_res: TimeMarkerRes:
	set(val):
		if timemarker_res == val:
			return
		timemarker_res = val
		update()

static func get_rainbow_styles() -> Array[StyleBoxFlat]:
	var result: Array[StyleBoxFlat]
	for color: Color in IS.RAINBOW_COLORS:
		var style:= StyleBoxFlat.new()
		style.bg_color = color
		result.append(style)
	return result

func _init() -> void:
	pressed.connect(_on_pressed)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_released():
				ProjectServer2.project_res.remove_timemarker(frame)

func update() -> void:
	tooltip_text = timemarker_res.custom_name + "\n" + timemarker_res.custom_description
	var style_idx: int = rainbow_styles.find_custom(func(element: StyleBoxFlat) -> bool: return element.bg_color == timemarker_res.custom_color)
	var style: StyleBoxFlat = rainbow_styles[style_idx]
	IS.set_button_style(self, style)

func _on_pressed() -> void:
	if not timemarker_res:
		return
	
	var color_options: Array[MenuOption]
	
	var colors: Array[Color] = IS.RAINBOW_COLORS
	for color: Color in colors:
		var option: MenuOption = MenuOption.new("", IS.TEXTURE_MARKER)
		option.set_meta("modulate", color)
		option.set_meta("icon_alignment", 1)
		color_options.append(option)
	
	var custom_color_index: int = colors.find(timemarker_res.custom_color)
	
	var name_line: LineEdit = IS.create_line_edit("Custom Name", timemarker_res.custom_name, null, {max_length = 24})
	var color_menu: Menu = IS.create_menu(color_options, false, true, {custom_minimum_size = Vector2(0, 40)})
	var description_controller: TextEdit = IS.create_text_edit_edit("Custom Description", "", timemarker_res.custom_description)[0]
	var description_edit: IS.EditBoxContainer = description_controller.get_parent()
	
	color_menu.focus_index = custom_color_index
	description_edit.keyframable = false
	
	var marker_window: BoxContainer = WindowManager.popup_accept_window(
		get_tree().get_current_scene(),
		Vector2(550, 400),
		"Create Time Marker",
		func() -> void:
			timemarker_res.custom_name = name_line.get_text()
			timemarker_res.custom_color = colors[color_menu.get_focus_index()]
			timemarker_res.custom_description = description_controller.get_text()
			update()
	)
	
	IS.add_children(marker_window, [
		name_line, color_menu, description_edit
	])
	
	IS.expand(description_edit, true, true)
	
	name_line.select()
	name_line.grab_focus()
