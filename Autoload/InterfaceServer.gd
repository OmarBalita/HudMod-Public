extends Node

const LABEL_SETTINGS_HEADER = preload("res://UI&UX/LabelSettingsHeader.tres")
const LABEL_SETTINGS_BOLD = preload("res://UI&UX/LabelSettingsBold.tres")
const LABEL_SETTINGS_MAIN = preload("res://UI&UX/LabelSettingsMain.tres")

const STYLE_BOX_EMPTY = preload("res://UI&UX/StyleBoxEmpty.tres")

const STYLE_PANEL = preload("res://UI&UX/StylePanel.tres")
const STYLE_HEADER = preload("res://UI&UX/StyleHeader.tres")
const STYLE_BODY = preload("res://UI&UX/StyleBody.tres")
const STYLE_ACCENT = preload("res://UI&UX/StyleAccent.tres")

const STYLE_BUTTON = preload("res://UI&UX/StyleButton.tres")
const STYLE_LINE_EDIT = preload("res://UI&UX/StyleLineEdit.tres")

const STYLE_H_LINE = preload("res://UI&UX/StyleHLine.tres")
const STYLE_V_LINE = preload("res://UI&UX/StyleVLine.tres")







func set_base_settings(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	control.add_theme_stylebox_override("focus", STYLE_BOX_EMPTY)

func set_base_container_settings(container: Control) -> void:
	set_base_settings(container)
	container.set_anchors_preset(Control.PRESET_FULL_RECT)

func set_base_panel_settings(panel: Control, style: StyleBox = STYLE_BODY) -> void:
	set_base_settings(panel)
	panel.add_theme_stylebox_override("panel", style)

func set_base_label_settings(label: Label, label_settings: LabelSettings) -> void:
	set_base_settings(label)
	label.label_settings = label_settings

func set_font_from_label_settings(control: Control, label_settings: LabelSettings) -> void:
	control.add_theme_font_override("font", label_settings.font)
	control.add_theme_color_override("font_color", label_settings.font_color)
	control.add_theme_color_override("font_outline_color", label_settings.outline_color)
	control.add_theme_font_size_override("font_size", label_settings.font_size)
	control.add_theme_constant_override("outline_size", label_settings.outline_size)






func create_empty_control(x_min_size: float = 10.0, y_min_size: int = 10.0, more: Dictionary = {}) -> Control:
	var control = Control.new()
	set_base_settings(control)
	control.custom_minimum_size.x = x_min_size
	control.custom_minimum_size.y = y_min_size
	ObjectServer.describe(control, more)
	return control



func create_texture_rect(texture: Texture2D, more: Dictionary = {expand_mode = TextureRect.EXPAND_IGNORE_SIZE, stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED}) -> TextureRect:
	var texture_rect = TextureRect.new()
	set_base_settings(texture_rect)
	texture_rect.texture = texture
	ObjectServer.describe(texture_rect, more)
	return texture_rect



func create_panel_container(min_size: Vector2 = Vector2.ZERO, style: StyleBox = STYLE_PANEL, more: Dictionary = {}) -> PanelContainer:
	var panel = PanelContainer.new()
	set_base_panel_settings(panel, style)
	panel.custom_minimum_size = min_size
	ObjectServer.describe(panel, more)
	return panel

func create_margin_container(left:= 8, right:= 8, up:= 8, down:= 8, more: Dictionary = {}) -> MarginContainer:
	var margin_container = MarginContainer.new()
	set_base_container_settings(margin_container)
	margin_container.add_theme_constant_override("margin_left", left)
	margin_container.add_theme_constant_override("margin_right", right)
	margin_container.add_theme_constant_override("margin_top", up)
	margin_container.add_theme_constant_override("margin_bottom", down)
	ObjectServer.describe(margin_container, more)
	return margin_container

func create_box_container(separation_scale: int = 10, vertical: bool = false, more: Dictionary = {alignment = BoxContainer.ALIGNMENT_CENTER, custom_minimum_size = Vector2(32, 32)}) -> BoxContainer:
	# Create New One
	var box_container = BoxContainer.new()
	# Describe Basics
	set_base_container_settings(box_container)
	box_container.add_theme_constant_override("separation", separation_scale)
	box_container.vertical = vertical
	# Describe More
	ObjectServer.describe(box_container, more)
	# Return Interface Node
	return box_container

func create_grid_container(control_size: Vector2, h_separation:= 10.0, v_separation:= 10.0, more: Dictionary = {}) -> FlexGridContainer:
	var grid_container = FlexGridContainer.new()
	set_base_container_settings(grid_container)
	grid_container.add_theme_constant_override("h_separation", h_separation)
	grid_container.add_theme_constant_override("v_separation", v_separation)
	grid_container.control_size = control_size
	ObjectServer.describe(grid_container, more)
	return grid_container

func create_split_container(separation_scale: int = 1, vertical: bool = false, more: Dictionary = {dragging_enabled = false}) -> SplitContainer:
	var split_container = SplitContainer.new()
	set_base_container_settings(split_container)
	split_container.add_theme_constant_override("separation", separation_scale)
	split_container.vertical = vertical
	ObjectServer.describe(split_container, more)
	return split_container

func create_scroll_container(h_scroll_mode: int = 1, v_scroll_mode: int = 1, more: Dictionary = {}) -> ScrollContainer:
	var scroll_container = ScrollContainer.new()
	set_base_container_settings(scroll_container)
	scroll_container.horizontal_scroll_mode = h_scroll_mode
	scroll_container.vertical_scroll_mode = v_scroll_mode
	ObjectServer.describe(scroll_container, more)
	return scroll_container

func create_viewport_container(more: Dictionary = {}) -> SubViewportContainer:
	var viewport_container = SubViewportContainer.new()
	set_base_container_settings(viewport_container)
	ObjectServer.describe(viewport_container, more)
	return viewport_container





func create_button(text: String, icon: Texture2D = null, more: Dictionary = {}) -> Button:
	# Create New One
	var button = Button.new()
	# Describe Basics
	set_base_settings(button)
	button.add_theme_stylebox_override("normal", STYLE_BUTTON)
	button.add_theme_stylebox_override("hover", STYLE_BUTTON)
	button.add_theme_stylebox_override("pressed", STYLE_BUTTON)
	button.text = text
	button.icon = icon
	# Describe More
	ObjectServer.describe(button, more)
	# Return Interface Node
	return button

func create_texture_button(normal: Texture2D, hover: Texture2D = null, pressed: Texture2D = null, more: Dictionary = {}) -> TextureButton:
	# Create New One
	var texture_button = TextureButton.new()
	# Describe Basics
	set_base_settings(texture_button)
	texture_button.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	texture_button.texture_normal = normal
	texture_button.texture_hover = hover
	texture_button.texture_pressed = pressed
	# Describe More
	ObjectServer.describe(texture_button, more)
	# Return Interface Node
	return texture_button




func create_line_edit(placeholder: String = "", text: String = "", right_icon: Texture2D = null, more: Dictionary = {size_flags_horizontal = Control.SIZE_EXPAND_FILL}) -> LineEdit:
	var line_edit = LineEdit.new()
	set_base_settings(line_edit)
	line_edit.add_theme_color_override("selection_color", STYLE_ACCENT.bg_color)
	line_edit.add_theme_stylebox_override("normal", STYLE_LINE_EDIT)
	line_edit.caret_blink = true
	line_edit.placeholder_text = placeholder
	line_edit.text = text
	line_edit.right_icon = right_icon
	ObjectServer.describe(line_edit, more)
	return line_edit




func create_panel(style: StyleBox = STYLE_PANEL, more: Dictionary = {}) -> Panel:
	var panel = Panel.new()
	set_base_panel_settings(panel, style)
	ObjectServer.describe(panel, more)
	return panel

func create_v_line_panel(min_size: float = 1, color: Color = Color(0,0,0, .25), more: Dictionary = {size_flags_horizontal = Control.SIZE_SHRINK_CENTER}) -> Panel:
	var panel = create_panel(STYLE_V_LINE.duplicate())
	panel.get_theme_stylebox("panel").color = color
	panel.custom_minimum_size.y = min_size
	ObjectServer.describe(panel, more)
	return panel

func create_h_line_panel(min_size: float = 1, color: Color = Color(0,0,0, .25), more: Dictionary = {size_flags_vertical = Control.SIZE_SHRINK_CENTER}) -> Panel:
	var panel = create_panel(STYLE_H_LINE.duplicate())
	panel.get_theme_stylebox("panel").color = color
	panel.custom_minimum_size.x = min_size
	ObjectServer.describe(panel, more)
	return panel





func create_label(text: String, label_settings: LabelSettings = LABEL_SETTINGS_MAIN, more: Dictionary = {horizontal_alignment = 1, vertical_alignment = 1}) -> Label:
	# Create New One
	var label = Label.new()
	# Describe Basics
	set_base_label_settings(label, label_settings)
	label.text = text
	# Describe More
	ObjectServer.describe(label, more)
	# Return Interface Node
	return label


func create_menu(options: Array[MenuOption], more: Dictionary = {}) -> Menu:
	var menu = Menu.new()
	menu.options = options
	ObjectServer.describe(menu, more)
	return menu




func create_layer(id: int, min_size: Vector2, color: Color, more: Dictionary = {}) -> Layer:
	# Create New One
	var layer = Layer.new(id)
	# Describe Basics
	layer.custom_minimum_size = min_size
	layer.color = color
	# Describe More
	ObjectServer.describe(layer, more)
	# Return Interface Node
	return layer










func create_clip_image_control(clip_res: MediaClipRes, texture: Texture2D = null) -> Control:
	var image_path = clip_res.media_resource_path
	
	var margin_container = create_margin_container(4,4,4,4)
	var control = create_empty_control(10, 10, {clip_contents = true})
	var box_container = create_box_container(10, false, {})
	var image_texture_rect = create_texture_rect(texture if texture else MediaServer.get_image_texture_from_path(image_path))
	
	margin_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_texture_rect.custom_minimum_size = Vector2(100, 0)
	
	box_container.add_child(image_texture_rect)
	box_container.add_child(create_name_label(image_path.get_file()))
	control.add_child(box_container)
	margin_container.add_child(control)
	
	return margin_container


func create_clip_video_control(clip_res: MediaClipRes) -> Control:
	var video_path = clip_res.media_resource_path
	
	var box_container = create_box_container(10, true)
	var image_control = create_clip_image_control(clip_res, MediaServer.get_video_display_texture_from_path(video_path, ProjectServer.thumbnails_path))
	box_container.add_child(image_control)
	
	if await MediaServer.is_stream_has_audio(video_path):
		var audio_control = create_clip_audio_control(clip_res, false, "224d29")
		box_container.add_child(audio_control)
	
	return box_container


func create_clip_audio_control(clip_res: MediaClipRes, create_name_label: bool = true, color_key: String = "20394d") -> Control:
	var audio_path = clip_res.media_resource_path
	var waves_texture = MediaServer.get_audio_display_texture_from_path(audio_path, ProjectServer.fortimeline_path, color_key, false)
	
	var wave_texture_rect = create_texture_rect(waves_texture, {})
	
	wave_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	wave_texture_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wave_texture_rect.expand_mode = 1
	wave_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	if create_name_label:
		wave_texture_rect.add_child(create_name_label(audio_path.get_file()))
	
	return wave_texture_rect


func create_name_label(name: String) -> Label:
	var label = create_label(name, LABEL_SETTINGS_BOLD)
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.custom_minimum_size.y = 30
	return label












