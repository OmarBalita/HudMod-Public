extends Node

# Modern Color Palette for Video Editor
const COLOR_NORMAL = Color(0.75, 0.75, 0.75, 0.75)
const COLOR_DARK_BG = Color(0.08, 0.08, 0.09, 1.0)        # #141417
const COLOR_DARK_PANEL = Color(0.12, 0.12, 0.14, 1.0)     # #1e1e24
const COLOR_DARK_HEADER = Color(0.059, 0.059, 0.071, 1.0)    # #0f0f12
const COLOR_ACCENT_BLUE = Color(0.201, 0.389, 0.67)       # #3399ff
const COLOR_ACCENT_ORANGE = Color(1.0, 0.4, 0.2, 1.0)     # #ff6633
const COLOR_SUCCESS_GREEN = Color(0.2, 0.8, 0.4, 1.0)     # #33cc66
const COLOR_WARNING_YELLOW = Color(1.0, 0.8, 0.2, 1.0)    # #ffcc33
const COLOR_ERROR_RED = Color(1.0, 0.3, 0.3, 1.0)         # #ff4d4d
const COLOR_TEXT_PRIMARY = Color(0.95, 0.95, 0.95, 1.0)   # #f2f2f2
const COLOR_TEXT_SECONDARY = Color(0.7, 0.7, 0.7, 1.0)    # #b3b3b3
const COLOR_TEXT_DISABLED = Color(0.4, 0.4, 0.4, 1.0)     # #666666
const COLOR_BORDER = Color(0.2, 0.2, 0.22, 1.0)           # #333338
const COLOR_SELECTION = Color(0.2, 0.6, 1.0, 0.3)         # #3399ff with alpha


const RAINBOW_COLORS: Array[Color] = [
	Color("999999"), # Gray
	Color("#B266FF"), # Violet
	Color("#6699FF"), # Blue
	Color("#66CCFF"), # Cyan
	Color("#66FFB2"), # Green
	Color("#FFFF99"), # Yellow
	Color("#FFCC66"), # Orange
	Color("#FF9999")  # Red
]

const EDIT_BOX_MIN_SIZE: Vector2 = Vector2(32, 32)


# Load resources
const LABEL_SETTINGS_HEADER = preload("res://UI&UX/LabelSettingsHeader.tres")
const LABEL_SETTINGS_BOLD = preload("res://UI&UX/LabelSettingsBold.tres")
const LABEL_SETTINGS_MAIN = preload("res://UI&UX/LabelSettingsMain.tres")

const TEXTURE_RIGHT = preload("res://Asset/Icons/right.png")
const TEXTURE_DOWN = preload("res://Asset/Icons/down.png")

const TEXTURE_TOGGLE_BUTTON_CHECKED = preload("res://Asset/Icons/toggle-button.png")
const TEXTURE_TOGGLE_BUTTON_UNCHECKED = preload("res://Asset/Icons/toggle-button2.png")

var STYLE_GRAPH_NODE_BODY: StyleBoxFlat = preload("res://UI&UX/GraphNodeStyle/BodyStyle.tres")
var STYLE_GRAPH_NODE_BASE_HEADER: StyleBoxFlat = preload("res://UI&UX/GraphNodeStyle/HeaderBaseStyle.tres")

var STYLE_ACCENT_LEFT: StyleBoxFlat = preload("res://UI&UX/StyleAccentLeft.tres")
var STYLE_CORNERLESS: StyleBoxFlat = preload("res://UI&UX/CornerlessStyle.tres")
var STYLE_CORNERLESS_HOVER: StyleBoxFlat = preload("res://UI&UX/CornerlessHoverStyle.tres")


# Create modern styles programmatically
var STYLE_BOX_EMPTY: StyleBoxEmpty
var STYLE_PANEL: StyleBoxFlat
var STYLE_HEADER: StyleBoxFlat
var STYLE_BODY: StyleBoxFlat
var STYLE_ACCENT: StyleBoxFlat
var STYLE_BUTTON: StyleBoxFlat
var STYLE_BUTTON_HOVER: StyleBoxFlat
var STYLE_BUTTON_PRESSED: StyleBoxFlat
var STYLE_BUTTON_ACCENT: StyleBoxFlat
var STYLE_LINE_EDIT: StyleBoxFlat
var STYLE_LINE_EDIT_FOCUS: StyleBoxFlat
var STYLE_H_LINE: StyleBoxLine
var STYLE_V_LINE: StyleBoxLine
var STYLE_TIMELINE: StyleBoxFlat
var STYLE_CLIP_CONTAINER: StyleBoxFlat
var STYLE_WHITE = load("res://UI&UX/StyleWhite.tres")




func _ready():
	_create_modern_styles()

func _create_modern_styles():
	# Empty style
	STYLE_BOX_EMPTY = StyleBoxEmpty.new()
	
	# Main panel style
	STYLE_PANEL = StyleBoxFlat.new()
	STYLE_PANEL.bg_color = COLOR_DARK_PANEL
	STYLE_PANEL.border_width_left = 1
	STYLE_PANEL.border_width_right = 1
	STYLE_PANEL.border_width_top = 1
	STYLE_PANEL.border_width_bottom = 1
	STYLE_PANEL.border_color = COLOR_BORDER
	STYLE_PANEL.corner_radius_top_left = 8
	STYLE_PANEL.corner_radius_top_right = 8
	STYLE_PANEL.corner_radius_bottom_left = 8
	STYLE_PANEL.corner_radius_bottom_right = 8
	STYLE_PANEL.shadow_color = Color(0, 0, 0, 0.3)
	STYLE_PANEL.shadow_size = 4
	STYLE_PANEL.shadow_offset = Vector2(0, 2)
	
	# Header style
	STYLE_HEADER = StyleBoxFlat.new()
	STYLE_HEADER.bg_color = COLOR_DARK_HEADER
	STYLE_HEADER.border_width_bottom = 2
	STYLE_HEADER.border_color = Color(COLOR_ACCENT_BLUE, .5)
	STYLE_HEADER.corner_radius_top_left = 8
	STYLE_HEADER.corner_radius_top_right = 8
	
	# Body style
	STYLE_BODY = StyleBoxFlat.new()
	STYLE_BODY.bg_color = COLOR_DARK_BG
	STYLE_BODY.border_width_left = 1
	STYLE_BODY.border_width_right = 1
	STYLE_BODY.border_width_top = 1
	STYLE_BODY.border_width_bottom = 1
	STYLE_BODY.border_color = COLOR_BORDER
	STYLE_BODY.corner_radius_top_left = 6
	STYLE_BODY.corner_radius_top_right = 6
	STYLE_BODY.corner_radius_bottom_left = 6
	STYLE_BODY.corner_radius_bottom_right = 6
	
	# Accent style
	STYLE_ACCENT = StyleBoxFlat.new()
	STYLE_ACCENT.bg_color = COLOR_ACCENT_BLUE
	STYLE_ACCENT.corner_radius_top_left = 6
	STYLE_ACCENT.corner_radius_top_right = 6
	STYLE_ACCENT.corner_radius_bottom_left = 6
	STYLE_ACCENT.corner_radius_bottom_right = 6
	
	# Button styles
	STYLE_BUTTON = StyleBoxFlat.new()
	STYLE_BUTTON.bg_color = COLOR_DARK_PANEL
	STYLE_BUTTON.border_width_left = 1
	STYLE_BUTTON.border_width_right = 1
	STYLE_BUTTON.border_width_top = 1
	STYLE_BUTTON.border_width_bottom = 1
	STYLE_BUTTON.border_color = COLOR_BORDER
	STYLE_BUTTON.corner_radius_top_left = 6
	STYLE_BUTTON.corner_radius_top_right = 6
	STYLE_BUTTON.corner_radius_bottom_left = 6
	STYLE_BUTTON.corner_radius_bottom_right = 6
	STYLE_BUTTON.content_margin_left = 12
	STYLE_BUTTON.content_margin_right = 12
	STYLE_BUTTON.content_margin_top = 8
	STYLE_BUTTON.content_margin_bottom = 8
	
	STYLE_BUTTON_HOVER = STYLE_BUTTON.duplicate()
	STYLE_BUTTON_HOVER.bg_color = COLOR_DARK_PANEL.lightened(0.1)
	STYLE_BUTTON_HOVER.border_color = COLOR_ACCENT_BLUE
	
	STYLE_BUTTON_PRESSED = STYLE_BUTTON.duplicate()
	STYLE_BUTTON_PRESSED.bg_color = COLOR_DARK_PANEL.darkened(0.1)
	STYLE_BUTTON_PRESSED.border_color = COLOR_ACCENT_BLUE
	
	STYLE_BUTTON_ACCENT = STYLE_BUTTON.duplicate()
	STYLE_BUTTON_ACCENT.bg_color = COLOR_ACCENT_BLUE
	STYLE_BUTTON_ACCENT.border_color = COLOR_ACCENT_BLUE.lightened(0.2)
	
	# Line edit styles
	STYLE_LINE_EDIT = StyleBoxFlat.new()
	STYLE_LINE_EDIT.bg_color = COLOR_DARK_BG
	STYLE_LINE_EDIT.border_width_left = 1
	STYLE_LINE_EDIT.border_width_right = 1
	STYLE_LINE_EDIT.border_width_top = 1
	STYLE_LINE_EDIT.border_width_bottom = 1
	STYLE_LINE_EDIT.border_color = COLOR_BORDER
	STYLE_LINE_EDIT.corner_radius_top_left = 4
	STYLE_LINE_EDIT.corner_radius_top_right = 4
	STYLE_LINE_EDIT.corner_radius_bottom_left = 4
	STYLE_LINE_EDIT.corner_radius_bottom_right = 4
	STYLE_LINE_EDIT.content_margin_left = 12
	STYLE_LINE_EDIT.content_margin_right = 12
	STYLE_LINE_EDIT.content_margin_top = 8
	STYLE_LINE_EDIT.content_margin_bottom = 8
	
	STYLE_LINE_EDIT_FOCUS = STYLE_LINE_EDIT.duplicate()
	STYLE_LINE_EDIT_FOCUS.border_color = COLOR_ACCENT_BLUE
	STYLE_LINE_EDIT_FOCUS.border_width_left = 2
	STYLE_LINE_EDIT_FOCUS.border_width_right = 2
	STYLE_LINE_EDIT_FOCUS.border_width_top = 2
	STYLE_LINE_EDIT_FOCUS.border_width_bottom = 2
	
	# Line styles
	STYLE_H_LINE = StyleBoxLine.new()
	STYLE_H_LINE.color = COLOR_BORDER
	
	STYLE_V_LINE = StyleBoxLine.new()
	STYLE_V_LINE.color = COLOR_BORDER
	STYLE_V_LINE.vertical = true
	
	# Timeline specific styles
	STYLE_TIMELINE = StyleBoxFlat.new()
	STYLE_TIMELINE.bg_color = COLOR_DARK_BG.darkened(0.1)
	STYLE_TIMELINE.border_width_top = 2
	STYLE_TIMELINE.border_color = COLOR_ACCENT_BLUE
	
	# Clip container style
	STYLE_CLIP_CONTAINER = StyleBoxFlat.new()
	STYLE_CLIP_CONTAINER.bg_color = COLOR_DARK_PANEL
	STYLE_CLIP_CONTAINER.border_width_left = 1
	STYLE_CLIP_CONTAINER.border_width_right = 1
	STYLE_CLIP_CONTAINER.border_width_top = 1
	STYLE_CLIP_CONTAINER.border_width_bottom = 1
	STYLE_CLIP_CONTAINER.border_color = COLOR_BORDER
	STYLE_CLIP_CONTAINER.corner_radius_top_left = 6
	STYLE_CLIP_CONTAINER.corner_radius_top_right = 6
	STYLE_CLIP_CONTAINER.corner_radius_bottom_left = 6
	STYLE_CLIP_CONTAINER.corner_radius_bottom_right = 6

# Base settings functions

func expand(control: Control, h: bool = true, v: bool = false) -> void:
	if h:
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if v:
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL

func set_base_settings(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	control.add_theme_stylebox_override("focus", STYLE_BOX_EMPTY)
	if not (control is LineEdit or control is TextEdit):
		control.focus_mode = Control.FOCUS_NONE

func set_base_container_settings(container: Control) -> void:
	set_base_settings(container)
	container.set_anchors_preset(Control.PRESET_FULL_RECT)

func set_base_panel_settings(panel: Control, style: StyleBox = null) -> void:
	set_base_settings(panel)
	panel.add_theme_stylebox_override("panel", style)

func set_base_label_settings(label: Label, label_settings: LabelSettings) -> void:
	set_base_settings(label)
	label.label_settings = label_settings
	label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

func set_font_from_label_settings(control: Control, label_settings: LabelSettings) -> void:
	control.add_theme_font_override("font", label_settings.font)
	control.add_theme_color_override("font_color", label_settings.font_color)
	control.add_theme_color_override("font_outline_color", label_settings.outline_color)
	control.add_theme_font_size_override("font_size", label_settings.font_size)
	control.add_theme_constant_override("outline_size", label_settings.outline_size)

func set_button_style(button: Button, style: StyleBox = STYLE_WHITE, hover: StyleBox = null, pressed: StyleBox = null) -> void:
	button.add_theme_stylebox_override("focus", STYLE_BOX_EMPTY)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover if hover else style)
	button.add_theme_stylebox_override("pressed", pressed if pressed else style)

func describe_box_container(box_container: BoxContainer, separation_scale: int, vertical: bool) -> void:
	set_base_container_settings(box_container)
	box_container.add_theme_constant_override("separation", separation_scale)
	box_container.vertical = vertical




# Enhanced creation functions
func create_empty_control(x_min_size: float = 10.0, y_min_size: int = 10.0, more: Dictionary = {}) -> Control:
	var control = Control.new()
	set_base_settings(control)
	control.custom_minimum_size.x = x_min_size
	control.custom_minimum_size.y = y_min_size
	ObjectServer.describe(control, more)
	return control

func create_color_rect(color: Color = Color(.9,.9,.9), more: Dictionary = {}) -> ColorRect:
	var color_rect = ColorRect.new()
	color_rect.color = color
	set_base_settings(color_rect)
	ObjectServer.describe(color_rect, more)
	return color_rect

func create_texture_rect(texture: Texture2D, more: Dictionary = {expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL, stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED}) -> TextureRect:
	var texture_rect = TextureRect.new()
	set_base_settings(texture_rect)
	texture_rect.texture = texture
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ObjectServer.describe(texture_rect, more)
	return texture_rect

func create_panel_container(min_size: Vector2 = Vector2.ZERO, style: StyleBox = STYLE_PANEL, more: Dictionary = {}) -> PanelContainer:
	var panel = PanelContainer.new()
	set_base_panel_settings(panel, style)
	panel.custom_minimum_size = min_size
	ObjectServer.describe(panel, more)
	return panel

func create_margin_container(left:= 12, right:= 12, up:= 12, down:= 12, more: Dictionary = {}) -> MarginContainer:
	var margin_container = MarginContainer.new()
	set_base_container_settings(margin_container)
	margin_container.add_theme_constant_override("margin_left", left)
	margin_container.add_theme_constant_override("margin_right", right)
	margin_container.add_theme_constant_override("margin_top", up)
	margin_container.add_theme_constant_override("margin_bottom", down)
	ObjectServer.describe(margin_container, more)
	return margin_container

func create_box_container(separation_scale: int = 16, vertical: bool = false, more: Dictionary = {alignment = BoxContainer.ALIGNMENT_CENTER, custom_minimum_size = Vector2(32, 32)}) -> BoxContainer:
	var box_container = BoxContainer.new()
	describe_box_container(box_container, separation_scale, vertical)
	ObjectServer.describe(box_container, more)
	return box_container

class EditBoxContainer extends BoxContainer:
	
	signal val_changed(new_val: Variant)
	
	var curr_val: Variant:
		set(val):
			curr_val = val
			val_changed.emit(val)
	
	var controller: Control
	var controller_curr_val_id: Dictionary[String, Variant] = {method = "", vari = ""} # Name of curr_val Variable in Controller
	# controller_cur_val_id has 2 keys: method and var, method is a Callable that i can Call to assign new Val
	# and the var assigned Manually
	var header: BoxContainer = IS.create_box_container()
	
	func _ready() -> void:
		add_child(header)
		move_child(header, 0)
		IS.expand(header)
	
	func get_curr_val() -> Variant:
		return curr_val
	
	func set_curr_val(new_val: Variant, edit_controller: bool = false) -> void:
		curr_val = new_val
		if edit_controller:
			var method = controller_curr_val_id.method
			var vari = controller_curr_val_id.vari
			if method:
				controller.call_deferred(method, new_val)
			elif vari: controller.set(vari, new_val)

func create_edit_box_container(separation_scale: int = 16, vertical: bool = false, more: Dictionary = {alignment = BoxContainer.ALIGNMENT_CENTER, custom_minimum_size = Vector2(32, 32)}) -> EditBoxContainer:
	var box_container = EditBoxContainer.new()
	describe_box_container(box_container, separation_scale, vertical)
	ObjectServer.describe(box_container, more)
	return box_container

func create_grid_container(control_size: Vector2, h_separation: int = 12, v_separation: int = 12, more: Dictionary = {}) -> FlexGridContainer:
	var grid_container = FlexGridContainer.new()
	set_base_container_settings(grid_container)
	grid_container.add_theme_constant_override("h_separation", h_separation)
	grid_container.add_theme_constant_override("v_separation", v_separation)
	grid_container.control_size = control_size
	ObjectServer.describe(grid_container, more)
	return grid_container

func create_split_container(separation_scale: int = 2, vertical: bool = false, more: Dictionary = {dragging_enabled = false}) -> SplitContainer:
	var split_container = SplitContainer.new()
	set_base_container_settings(split_container)
	split_container.add_theme_constant_override("separation", separation_scale)
	split_container.add_theme_stylebox_override("bg", STYLE_BODY)
	split_container.vertical = vertical
	ObjectServer.describe(split_container, more)
	return split_container

func create_scroll_container(h_scroll_mode: int = 1, v_scroll_mode: int = 1, more: Dictionary = {}) -> ScrollContainer:
	var scroll_container = ScrollContainer.new()
	set_base_container_settings(scroll_container)
	scroll_container.horizontal_scroll_mode = h_scroll_mode
	scroll_container.vertical_scroll_mode = v_scroll_mode
	# Style scrollbars
	scroll_container.add_theme_stylebox_override("bg", STYLE_BODY)
	ObjectServer.describe(scroll_container, more)
	return scroll_container

func create_viewport_container(more: Dictionary = {}) -> SubViewportContainer:
	var viewport_container = SubViewportContainer.new()
	set_base_container_settings(viewport_container)
	ObjectServer.describe(viewport_container, more)
	return viewport_container

# Enhanced button creation
func create_button(text: String, icon: Texture2D = null, accent: bool = false, flat: bool = false, more: Dictionary = {}) -> Button:
	var button = Button.new()
	set_base_settings(button)
	
	if accent:
		set_button_style(button, STYLE_BOX_EMPTY if flat else STYLE_BUTTON_ACCENT, STYLE_BUTTON_ACCENT, STYLE_BUTTON_ACCENT)
	else:
		set_button_style(button, STYLE_BOX_EMPTY if flat else STYLE_BUTTON, STYLE_BUTTON_HOVER, STYLE_BUTTON_PRESSED)
	
	set_font_from_label_settings(button, LABEL_SETTINGS_MAIN)
	
	button.text = text
	button.icon = icon
	
	ObjectServer.describe(button, more)
	return button


class CustomTextureButton extends TextureButton:
	
	var normal_color: Color = COLOR_NORMAL
	var accent_color: Color = COLOR_ACCENT_BLUE
	
	func _ready() -> void:
		# Connections
		button_down.connect(set_self_modulate.bind(accent_color))
		button_up.connect(update_button)
		update_button()
	
	func change_button_pressed(to: bool) -> void:
		button_pressed = to
		update_button()
	
	func update_button() -> void:
		var toggle_color = accent_color if button_pressed else normal_color
		set_self_modulate(toggle_color if toggle_mode else normal_color)

func create_texture_button(normal: Texture2D, hover: Texture2D = null, pressed: Texture2D = null, toggle_mode: bool = false, more: Dictionary = {}) -> CustomTextureButton:
	var texture_button = CustomTextureButton.new()
	set_base_settings(texture_button)
	texture_button.toggle_mode = toggle_mode
	texture_button.stretch_mode = CustomTextureButton.STRETCH_KEEP_CENTERED
	texture_button.texture_normal = normal
	texture_button.texture_hover = hover if hover else normal
	texture_button.texture_pressed = pressed if pressed else normal
	
	# Add subtle background
	texture_button.add_theme_stylebox_override("normal", STYLE_BUTTON)
	texture_button.add_theme_stylebox_override("hover", STYLE_BUTTON_HOVER)
	texture_button.add_theme_stylebox_override("pressed", STYLE_BUTTON_PRESSED)
	
	ObjectServer.describe(texture_button, more)
	return texture_button


func create_panel(style: StyleBox = STYLE_PANEL, more: Dictionary = {}) -> Panel:
	var panel = Panel.new()
	set_base_panel_settings(panel, style)
	ObjectServer.describe(panel, more)
	return panel

func create_v_line_panel(min_size: float = 1, color: Color = Color(1,1,1, .3), more: Dictionary = {size_flags_horizontal = Control.SIZE_SHRINK_CENTER}) -> Panel:
	var panel = create_panel(STYLE_V_LINE.duplicate())
	panel.get_theme_stylebox("panel").color = color
	panel.custom_minimum_size.x = min_size
	ObjectServer.describe(panel, more)
	return panel

func create_h_line_panel(min_size: float = 1, color: Color = Color(1,1,1, .3), more: Dictionary = {size_flags_vertical = Control.SIZE_SHRINK_CENTER}) -> Panel:
	var panel = create_panel(STYLE_H_LINE.duplicate())
	panel.get_theme_stylebox("panel").color = color
	panel.custom_minimum_size.y = min_size
	ObjectServer.describe(panel, more)
	return panel

func create_selection_box(select_from: Array[Control] = [], request_selection_func: Callable = Callable(), more: Dictionary = {}) -> SelectionBox:
	var selection_box = SelectionBox.new()
	set_base_container_settings(selection_box)
	selection_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_box.select_from = select_from
	selection_box.request_selection_func = request_selection_func
	ObjectServer.describe(selection_box, more)
	return selection_box

func create_label(text: String, label_settings: LabelSettings = LABEL_SETTINGS_MAIN, more: Dictionary = {horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER, vertical_alignment = VERTICAL_ALIGNMENT_CENTER}) -> Label:
	var label = Label.new()
	set_base_label_settings(label, label_settings)
	label.text = text
	ObjectServer.describe(label, more)
	return label


func create_progress_bar(curr_val: float, min_val: float, max_val: float, step: float, more:= {}) -> ProgressBar:
	var bar = ProgressBar.new()
	set_base_settings(bar)
	bar.add_theme_stylebox_override("fill", STYLE_ACCENT)
	
	bar.min_value = min_val
	bar.max_value = max_val
	bar.step = step
	bar.value = curr_val
	ObjectServer.describe(bar, more)
	return bar


func create_category(has_header: bool, category_name: StringName, custom_color: Color = Color.BLACK, content_size: Vector2 = Vector2(32, 32), more: Dictionary = {}) -> Category:
	var category = Category.new()
	set_base_settings(category)
	category.add_theme_stylebox_override("bg", STYLE_BODY)
	category.collapsed = true
	category.vertical = true
	category.has_header = has_header
	category.category_name = category_name
	category.category_custom_color = custom_color
	category.content_control_size = content_size
	ObjectServer.describe(category, more)
	return category







func create_menu(options: Array, is_vertical: bool = false, more: Dictionary = {}) -> Menu:
	var menu = Menu.new()
	menu.options = options
	menu.is_vertical = is_vertical
	ObjectServer.describe(menu, more)
	return menu

func create_popuped_text(text: String = "", more: Dictionary = {}) -> PopupedText:
	var pop_text = PopupedText.new()
	set_base_panel_settings(pop_text, IS.STYLE_BODY)
	pop_text.text = text
	ObjectServer.describe(pop_text, more)
	return pop_text

func create_popuped_menu(options: Array, more: Dictionary = {}) -> PopupedMenu:
	var pop_menu = PopupedMenu.new()
	set_base_panel_settings(pop_menu, IS.STYLE_BODY)
	pop_menu.options = options
	ObjectServer.describe(pop_menu, more)
	return pop_menu

func create_popuped_categories_menu(options: Dictionary[MenuOption, Array], more: Dictionary = {}) -> PopupedCategoriesMenu:
	var pop_categories_menu:= PopupedCategoriesMenu.new(options)
	set_base_panel_settings(pop_categories_menu, IS.STYLE_BODY)
	ObjectServer.describe(pop_categories_menu, more)
	return pop_categories_menu

func create_popuped_color_controller(main_color: Color, more: Dictionary = {}) -> PopupedColorController:
	var pop_color_controller = PopupedColorController.new()
	set_base_panel_settings(pop_color_controller, IS.STYLE_BODY)
	pop_color_controller.curr_color = main_color
	ObjectServer.describe(pop_color_controller, more)
	return pop_color_controller

func create_popuped_box(elements: Array, more: Dictionary = {}) -> PopupedBox:
	var pop_box = PopupedBox.new()
	set_base_panel_settings(pop_box, IS.STYLE_BODY)
	pop_box.elements = elements
	ObjectServer.describe(pop_box, more)
	return pop_box


func popup(popuped: PopupedControl, pop_from = null, pop_in = null, min_size: Vector2 = Vector2.ZERO) -> void:
	var pop_pos
	if pop_from:
		pop_pos = pop_from.global_position + Vector2(0, pop_from.size.y)
	if not pop_in:
		pop_in = get_tree().get_current_scene()
	pop_in.add_child(popuped)
	popuped.custom_minimum_size = min_size
	popuped.popup(pop_pos)

func popup_menu(options: Array, pop_from = null, pop_in = null, min_size: Vector2 = Vector2.ZERO) -> PopupedMenu:
	var pop_menu = create_popuped_menu(options)
	popup(pop_menu, pop_from, pop_in, min_size)
	return pop_menu

func popup_categories_menu(options: Dictionary[MenuOption, Array], pop_from = null, pop_in = null, min_size: Vector2 = Vector2.ZERO) -> PopupedCategoriesMenu:
	var pop_cat_menu = create_popuped_categories_menu(options)
	popup(pop_cat_menu, pop_from, pop_in, min_size)
	return pop_cat_menu

func popup_color_controller(main_color: Color, pop_from = null, pop_in = null, min_size: Vector2 = Vector2.ZERO) -> PopupedColorController:
	var pop_color_controller = create_popuped_color_controller(main_color)
	popup(pop_color_controller, pop_from, pop_in, min_size)
	return pop_color_controller

func popup_box(elements: Array, pop_from = null, pop_in = null, min_size: Vector2 = Vector2.ZERO) -> PopupedBox:
	var pop_box = create_popuped_box(elements)
	popup(pop_box, pop_from, pop_in, min_size)
	return pop_box



# Values Controllers for Modern Video Editor

func create_option_controller(options_info: Array[Dictionary], save_path: String = "", default_id: int = 0, accent: bool = false, more: Dictionary = {}) -> OptionController:
	var option_controller:= OptionController.new()
	set_base_settings(option_controller)
	
	if accent: set_button_style(option_controller, STYLE_BUTTON_ACCENT, STYLE_BUTTON_ACCENT, STYLE_BUTTON_ACCENT)
	else: set_button_style(option_controller, STYLE_BUTTON, STYLE_BUTTON_HOVER, STYLE_BUTTON_PRESSED)
	
	option_controller.icon = TEXTURE_DOWN
	option_controller.options_info = options_info
	option_controller.save_path = save_path
	option_controller.default_index = default_id
	
	ObjectServer.describe(option_controller, more)
	return option_controller

func create_check_button(is_checked: bool = false, more: Dictionary = {}) -> CheckButton:
	var check_button:= CheckButton.new()
	set_base_settings(check_button)
	set_button_style(check_button, STYLE_BOX_EMPTY)
	check_button.add_theme_icon_override("checked", TEXTURE_TOGGLE_BUTTON_CHECKED)
	check_button.add_theme_icon_override("unchecked", TEXTURE_TOGGLE_BUTTON_UNCHECKED)
	check_button.button_pressed = is_checked
	ObjectServer.describe(check_button, more)
	return check_button

func create_line_edit(placeholder: String = "", text: String = "", right_icon: Texture2D = null, more: Dictionary = {size_flags_horizontal = Control.SIZE_EXPAND_FILL}) -> LineEdit:
	var line_edit:= LineEdit.new()
	set_base_settings(line_edit)
	line_edit.add_theme_color_override("selection_color", COLOR_SELECTION)
	line_edit.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	line_edit.add_theme_color_override("font_placeholder_color", COLOR_TEXT_SECONDARY)
	line_edit.add_theme_stylebox_override("normal", STYLE_LINE_EDIT)
	line_edit.add_theme_stylebox_override("focus", STYLE_LINE_EDIT_FOCUS)
	line_edit.caret_blink = true
	line_edit.placeholder_text = placeholder
	line_edit.text = text
	line_edit.right_icon = right_icon
	ObjectServer.describe(line_edit, more)
	return line_edit

func create_text_edit(placeholder: String = "", text: String = "", more: Dictionary = {}) -> TextEdit:
	var text_edit:= TextEdit.new()
	set_base_settings(text_edit)
	text_edit.add_theme_stylebox_override("normal", STYLE_LINE_EDIT)
	text_edit.add_theme_stylebox_override("focus", STYLE_LINE_EDIT_FOCUS)
	text_edit.caret_blink = true
	text_edit.placeholder_text = placeholder
	text_edit.text = text
	expand(text_edit)
	ObjectServer.describe(text_edit, more)
	return text_edit

func create_slider_control(curr_val: float, min_val: float, max_val: float, step: float, left_texture: Texture2D = null, right_texture: Texture2D = null, more: Dictionary = {}) -> SliderControl:
	var slider_control:= SliderControl.new()
	var slider_controller = slider_control.slider_controller
	set_base_settings(slider_control)
	slider_control.custom_minimum_size.x = 200.0
	slider_controller.min_val = min_val
	slider_controller.max_val = max_val
	slider_controller.step = step
	slider_controller.curr_val = curr_val
	slider_control.texture_left = left_texture
	slider_control.texture_right = right_texture
	ObjectServer.describe(slider_control, more)
	return slider_control

func create_float_controller(curr_val: float, min_val: float, max_val: float, step: float, spin_scale: float = .01, spin_magnet_step: float = 10.0, is_int: bool = false, more: Dictionary = {}) -> FloatController:
	var float_controller:= FloatController.new()
	set_base_settings(float_controller)
	IS.set_button_style(float_controller, STYLE_BUTTON)
	float_controller.texture_right = TEXTURE_RIGHT
	float_controller.min_val = min_val
	float_controller.max_val = max_val
	float_controller.step = step
	float_controller.spin_scale = spin_scale
	float_controller.spin_magnet_step = spin_magnet_step
	float_controller.curr_val = curr_val
	float_controller.is_int = is_int
	ObjectServer.describe(float_controller, more)
	return float_controller

func create_vec2_controller(curr_val: Vector2, more: Dictionary = {}) -> Vector2Controller:
	var vec2_controller:= Vector2Controller.new()
	vec2_controller.curr_val = curr_val
	ObjectServer.describe(vec2_controller, more)
	return vec2_controller

func create_color_button(color: Color, more: Dictionary = {}) -> ColorButton:
	var color_button:= ColorButton.new()
	set_base_settings(color_button)
	set_button_style(color_button, STYLE_BUTTON, STYLE_BUTTON_HOVER, STYLE_BUTTON_PRESSED)
	color_button.curr_color = color
	ObjectServer.describe(color_button, more)
	return color_button

func create_list_controller(list: Array, list_types: Array[String] = [], connections: Array[Signal] = [], can_add_element: bool = true, can_remove_element: bool = true, can_duplicate_element: bool = true, can_change_element_priority: bool = true, more: Dictionary = {}) -> ListController:
	var list_controller:= ListController.new()
	set_base_panel_settings(list_controller, STYLE_BODY)
	set_base_settings(list_controller)
	list_controller.list = list
	list_controller.types = list_types
	list_controller.can_add_element = can_add_element
	list_controller.can_remove_element = can_remove_element
	list_controller.can_duplicate_element = can_duplicate_element
	list_controller.can_change_element_priority = can_change_element_priority
	for _signal: Signal in connections:
		if not _signal.is_null():
			list_controller.list_changed.connect(_signal.emit)
	ObjectServer.describe(list_controller, more)
	return list_controller

func create_color_range_control(color_range_res: ColorRangeRes, more: Dictionary = {}) -> ColorRangeControl:
	var color_range_control = ColorRangeControl.new()
	set_base_panel_settings(color_range_control, STYLE_BODY)
	color_range_control.color_range_controller.color_range_res = color_range_res
	ObjectServer.describe(color_range_control, more)
	return color_range_control



func create_edit_box(name: String, min_size: Vector2, vertical: bool = false, name_alignment: int = 0) -> EditBoxContainer:
	var box = create_edit_box_container(16, vertical, {custom_minimum_size = min_size})
	var name_label = create_name_label(name, name_alignment)
	expand(name_label)
	box.header.add_child(name_label)
	return box

func create_custom_edit_box(name: String, edits_box_container: BoxContainer, min_size: Vector2 = EDIT_BOX_MIN_SIZE) -> EditBoxContainer:
	var box = create_edit_box(name, min_size, true)
	var panel_container = create_panel_container()
	var margin_container = create_margin_container()
	margin_container.add_child(edits_box_container)
	panel_container.add_child(margin_container)
	box.add_child(panel_container)
	return box

func connect_controller_to_edit_box(box: EditBoxContainer, controller: Control, connect_signal_func: Callable, set_func_id: StringName = "", vari_id: StringName = "") -> void:
	connect_signal_func.call()
	box.controller = controller
	box.controller_curr_val_id.method = set_func_id
	box.controller_curr_val_id.vari = vari_id

func create_option_edit(name: String, options_info: Array[Dictionary], save_path: String = "", default_id: int = 0, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box = create_edit_box(name, min_size, false, name_alignment)
	var option_controller = create_option_controller(options_info, save_path, default_id)
	expand(option_controller)
	box.add_child(option_controller)
	
	connect_controller_to_edit_box(box, option_controller, func(): option_controller.selected_option_changed.connect(func(id: int, option: MenuOption) -> void: box.set_curr_val(id)), "set_selected_id")
	return [option_controller]

func create_bool_edit(name: String, is_checked: bool, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box = create_edit_box(name, min_size, false, name_alignment)
	var check_button = create_check_button(is_checked)
	box.add_child(check_button)
	
	connect_controller_to_edit_box(box, check_button, func(): check_button.pressed.connect(func() -> void: box.set_curr_val(check_button.button_pressed)), "", "button_pressed")
	return [check_button]

func create_line_edit_edit(name: String, placeholder: String = "", text: String = "", min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box = create_edit_box(name, min_size, false, name_alignment)
	var line_edit = create_line_edit(placeholder, text)
	expand(line_edit)
	box.add_child(line_edit)
	
	connect_controller_to_edit_box(box, line_edit, func(): line_edit.text_submitted.connect(box.set_curr_val), "set_text")
	return [line_edit]

func create_text_edit_edit(name: String, placeholder: String = "", text: String = "", min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box = create_edit_box(name, min_size, true, name_alignment)
	var text_edit = create_text_edit(placeholder, text)
	expand(text_edit, false, true)
	box.add_child(text_edit)
	
	connect_controller_to_edit_box(box, text_edit, func(): text_edit.text_changed.connect(func(): box.set_curr_val(text_edit.get_text())), "set_text")
	return [text_edit]

func create_float_edit(name: String, use_slider: bool, use_spinbox: bool, curr_val: float, min_val: float, max_val: float, step: float, spin_scale: float = .01, spin_magnet_step: float = 10.0, is_int: bool = false, left_texture: Texture2D = null, right_texture: Texture2D = null, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box = create_edit_box(name, min_size, false, name_alignment)
	
	var slider_control: SliderControl
	var float_control: FloatController
	
	if use_slider:
		slider_control = create_slider_control(curr_val, min_val, max_val, step, left_texture, right_texture)
		expand(slider_control)
		box.add_child(slider_control)
		connect_controller_to_edit_box(box, slider_control, func(): slider_control.slider_controller.val_changed.connect(box.set_curr_val), "set_curr_val")
	
	elif use_spinbox:
		float_control = create_float_controller(curr_val, min_val, max_val, step, spin_scale, spin_magnet_step, is_int)
		expand(float_control)
		box.add_child(float_control)
		connect_controller_to_edit_box(box, float_control, func(): float_control.val_changed.connect(box.set_curr_val), "set_curr_val")
	
	return [slider_control, float_control]

func create_vec2_edit(name: String, curr_val: Vector2, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box:= create_edit_box(name, min_size, false, name_alignment)
	var vec2_controller:= create_vec2_controller(curr_val)
	expand(vec2_controller)
	box.add_child(vec2_controller)
	connect_controller_to_edit_box(box, vec2_controller, func() -> void: vec2_controller.val_changed.connect(box.set_curr_val), "set_curr_val")
	return [vec2_controller]

func create_color_edit(name: String, color: Color = Color.BLACK, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box = create_edit_box(name, min_size, false, name_alignment)
	var color_button = create_color_button(color)
	expand(color_button)
	box.add_child(color_button)
	
	connect_controller_to_edit_box(box, color_button, func(): color_button.color_changed.connect(box.set_curr_val), "set_curr_color")
	return [color_button]

func create_list_edit(name: String, list: Array, list_types: Array[String] = [], connections: Array[Signal] = [], can_add_element: bool = true, can_remove_element: bool = true, can_duplicate_element: bool = true, can_change_element_priority: bool = true, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box = create_edit_box(name, min_size, true, name_alignment)
	var list_controller = create_list_controller(list, list_types, connections, can_add_element, can_remove_element, can_duplicate_element, can_change_element_priority)
	expand(list_controller, true, true)
	box.add_child(list_controller)
	
	connect_controller_to_edit_box(box, list_controller,
	func():
		var callable = box.set_curr_val.bind(list)
		list_controller.list_changed.connect(callable)
		list_controller.list_val_changed.connect(func(index: int, val: Variant) -> void: callable.call()),
	"set_list")
	return [list_controller]

func create_color_range_edit(name: String, color_range_res: ColorRangeRes, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box = create_edit_box(name, min_size, true, name_alignment)
	var color_range_control = create_color_range_control(color_range_res)
	expand(color_range_control, true, true)
	box.add_child(color_range_control)
	
	connect_controller_to_edit_box(box, color_range_control, func(): color_range_control.val_changed.connect(box.set_curr_val.bind(color_range_res)), "set_color_range_res")
	return [color_range_control]


func get_main_controller_from(controllers: Array[Control]) -> Control:
	var controller: Control
	for ctrlr in controllers:
		if ctrlr != null:
			controller = ctrlr
			break
	return controller

func get_edit_box_from(controllers: Array[Control]) -> EditBoxContainer:
	var main_controller = get_main_controller_from(controllers)
	var edit_box: Node = main_controller
	while edit_box is not EditBoxContainer:
		edit_box = edit_box.get_parent()
	return edit_box





func create_graph_node(title: String, min_size: Vector2 = Vector2(150.0, 150.0)) -> GraphNode:
	var graph_node:= GraphNode.new()
	graph_node.title = title
	graph_node.add_theme_stylebox_override("panel", STYLE_GRAPH_NODE_BODY)
	graph_node.add_theme_stylebox_override("panel_selected", STYLE_GRAPH_NODE_BODY)
	graph_node.add_theme_stylebox_override("titlebar", STYLE_GRAPH_NODE_BASE_HEADER)
	graph_node.add_theme_stylebox_override("titlebar_selected", STYLE_GRAPH_NODE_BASE_HEADER)
	graph_node.add_theme_stylebox_override("panel_focus", StyleBoxFlat.new())
	return graph_node




# Enhanced media clip controls for Modern Video Editor

func create_layer(id: int, min_size: Vector2, color: Color, more: Dictionary = {}) -> Layer:
	var layer = Layer.new(id)
	layer.custom_minimum_size = min_size
	layer.color = color
	ObjectServer.describe(layer, more)
	return layer


func create_clip_base_control(style: StyleBox, child_control: Control = null) -> Control:
	var bg_panel = create_panel_container(Vector2.ZERO, style)
	var margin_container = create_margin_container(4,4,4,4)
	var control = create_empty_control(.0, .0, {clip_contents = true})
	if child_control:
		control.add_child(child_control)
	margin_container.add_child(control)
	bg_panel.add_child(margin_container)
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return bg_panel

func create_clip_basic_control(name: String, style: StyleBox) -> Control:
	var name_label = create_name_label(name)
	name_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return create_clip_base_control(style, name_label)


func create_clip_image_control(clip_res: MediaClipRes, style: StyleBox) -> Control:
	var image_path = clip_res.media_resource_path
	
	var box_container = create_box_container(5, false, {})
	var image_texture_rect = create_texture_rect(MediaServer.get_image_texture_from_path(image_path))
	var name_label = create_name_label(image_path.get_file())
	box_container.add_child(image_texture_rect)
	box_container.add_child(name_label)
	
	expand(name_label, true, true)
	image_texture_rect.set_custom_minimum_size(Vector2(100, 0))
	
	return create_clip_base_control(style, box_container)


func create_clip_video_control(clip_res: MediaClipRes, style: StyleBox) -> Control:
	var video_path = clip_res.media_resource_path
	
	var vsplit_container = create_split_container(5, true, {})
	var hbox_container = create_box_container(5, false, {})
	
	var name_label = create_name_label(video_path.get_file())
	var video_texture_rect = create_texture_rect(MediaServer.get_video_display_texture_from_path(video_path, ProjectServer.explorer_thumbnails_path))
	
	hbox_container.add_child(video_texture_rect)
	hbox_container.add_child(name_label)
	vsplit_container.add_child(hbox_container)
	
	if await MediaServer.is_stream_has_audio(video_path):
		var wave_texture_rect = create_texture_rect(MediaServer.get_audio_display_texture_from_path(video_path, ProjectServer.timeline_thumbnails_path, "224d29", false), {})
		
		wave_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		ObjectServer.describe(wave_texture_rect, {size_flags_vertical = Control.SIZE_EXPAND_FILL, expand_mode = 1})
		vsplit_container.add_child(wave_texture_rect)
	
	expand(name_label, true, true)
	video_texture_rect.set_custom_minimum_size(Vector2(100, 0))
	
	return create_clip_base_control(style, vsplit_container)


func create_clip_audio_control(clip_res: MediaClipRes, style: StyleBox) -> Control:
	var audio_path = clip_res.media_resource_path
	
	var name_label = create_name_label(audio_path.get_file())
	var wave_texture_rect = create_texture_rect(MediaServer.get_audio_display_texture_from_path(audio_path, ProjectServer.timeline_thumbnails_path, "20394d", false), {})
	
	expand(name_label, true)
	wave_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	ObjectServer.describe(wave_texture_rect, {size_flags_vertical = Control.SIZE_EXPAND_FILL, expand_mode = 1})
	
	wave_texture_rect.add_child(name_label)
	
	return create_clip_base_control(style, wave_texture_rect)


func create_name_label(name: String, h_alignment: int = 0) -> Label:
	var label = create_label(name, LABEL_SETTINGS_BOLD, {horizontal_alignment = h_alignment, vertical_alignment = 1, text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS})
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.custom_minimum_size.y = 30
	return label





# Additional helper functions for video editor

func create_timeline_panel(more: Dictionary = {}) -> PanelContainer:
	var panel = create_panel_container(Vector2.ZERO, STYLE_TIMELINE, more)
	return panel

func create_toolbar_button(icon: Texture2D, tooltip: String = "", more: Dictionary = {}) -> Button:
	var button = create_button("", icon, false, false, more)
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(32, 32)
	return button

func create_status_label(text: String, status_type: String = "normal") -> Label:
	var label = create_label(text, LABEL_SETTINGS_MAIN)
	match status_type:
		"success":
			label.add_theme_color_override("font_color", COLOR_SUCCESS_GREEN)
		"warning":
			label.add_theme_color_override("font_color", COLOR_WARNING_YELLOW)
		"error":
			label.add_theme_color_override("font_color", COLOR_ERROR_RED)
		_:
			label.add_theme_color_override("font_color", COLOR_TEXT_PRIMARY)
	return label






func add_childs(parent: Node, childs: Array[Node]) -> void:
	for node: Node in childs:
		parent.add_child(node)

func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()
