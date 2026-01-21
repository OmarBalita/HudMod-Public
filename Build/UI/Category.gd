class_name Category extends SplitContainer

signal expand_changed()

@export var has_header: bool = true:
	set(val):
		has_header = val
		is_expanded = not has_header
		update_ui()
@export var category_name: StringName = &"Category":
	set(val): category_name = val; update_ui()
@export var content_control_size: Vector2 = Vector2(32, 32):
	set(val): content_control_size = val; update_ui()
@export var has_custom_color: bool = true
@export var use_flex_container: bool = true:
	set(val):
		use_flex_container = val
		if val: content_container = IS.create_grid_container(content_control_size, 12, 12)
		else: content_container = IS.create_box_container(8, true)
		content_container.clip_contents = false

var is_expanded: bool:
	set(val):
		is_expanded = val;
		update_ui()
		if is_node_ready():
			expand_changed.emit()

@onready var header_button: Button
@onready var custom_color_rect: ColorRect
@onready var content_panel_container: PanelContainer
@onready var content_margin_container: MarginContainer

var content_container: Container

@export_group("Theme")
@export_subgroup("Color")
@export var content_color: Color = Color.TRANSPARENT:
	set(val): content_color = val; update_ui()
@export var category_custom_color: Color:
	set(val): category_custom_color = val; update_ui()
@export_subgroup("Texture", "texture")
@export var texture_expand: Texture2D = IS.TEXTURE_DOWN
@export var texture_collapse: Texture2D = IS.TEXTURE_RIGHT


func _ready() -> void:
	dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
	
	header_button = Button.new()
	custom_color_rect = IS.create_color_rect(category_custom_color, {custom_minimum_size = Vector2(10.0, .0)})
	
	content_panel_container = PanelContainer.new()
	content_margin_container = IS.create_margin_container(8,8,8,8, {clip_contents = false})
	
	IS.set_font_from_label_settings(header_button, IS.LABEL_SETTINGS_BOLD)
	IS.set_button_style(header_button, IS.STYLE_CORNERLESS, IS.STYLE_CORNERLESS_HOVER)
	
	var panel_style:= StyleBoxFlat.new()
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	content_panel_container.add_theme_stylebox_override(&"panel", panel_style)
	
	if has_custom_color:
		custom_color_rect.set_anchors_and_offsets_preset(PRESET_RIGHT_WIDE)
		custom_color_rect.position.x = custom_color_rect.position.x - custom_color_rect.size.x
		header_button.add_child(custom_color_rect)
	
	content_margin_container.add_child(content_container)
	content_panel_container.add_child(content_margin_container)
	add_child(header_button)
	add_child(content_panel_container)
	
	header_button.pressed.connect(on_header_button_pressed)
	
	update_ui()

func update_ui() -> void:
	if not is_node_ready():
		return
	header_button.set_visible(has_header)
	header_button.set_text(category_name)
	header_button.icon = texture_expand if is_expanded else texture_collapse
	custom_color_rect.set_color(category_custom_color)
	
	var panel_style: StyleBoxFlat = content_panel_container.get_theme_stylebox(&"panel")
	panel_style.set_border_color(content_color.lightened(.5))
	panel_style.set_bg_color(content_color)
	if use_flex_container:
		content_container.set_control_size(content_control_size)
	content_panel_container.set_visible(is_expanded)

func get_contents() -> Array[Node]:
	return content_container.get_children()

func add_content(content: Control) -> void:
	content_container.add_child(content)

func move_content(content: Control, to_index: int) -> void:
	content_container.move_child(content, to_index)

func remove_all_contents() -> void:
	for content: Control in content_container.get_children():
		content.queue_free()

func on_header_button_pressed() -> void:
	is_expanded = not is_expanded

