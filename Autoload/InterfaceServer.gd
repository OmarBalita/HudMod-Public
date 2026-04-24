extends Node

signal colors_updated()

var color_base_dark: Color
var color_base_min: Color
var color_base_mid: Color
var color_base_max: Color
var color_accent: Color
var color_label: Color
var color_label_transp: Color

var color_accent_highlight: Color
var color_accent_selection: Color
var color_border: Color

const RAINBOW_COLORS: Array[Color] = [
	Color(.6, .6, .6), # Gray
	Color(.672, .384, .96), # Violet
	Color(.4, .6, 1.), # Blue
	Color(.384, .769, .961), # Cyan
	Color(.478, .902, .361), # Green
	Color(.98, .97, .392), # Yellow
	Color(1., .796, .349), # Orange
	Color(1., .32, .388)  # Red
]

# Load resources
var label_settings_main: LabelSettings = preload("res://UI&UX/LabelSettingsMain.tres")
var label_settings_header: LabelSettings = preload("res://UI&UX/LabelSettingsHeader.tres")
var label_settings_bold: LabelSettings = preload("res://UI&UX/LabelSettingsBold.tres")

const TEXTURE_ADD: CompressedTexture2D = preload("res://Asset/Icons/add.png")
const TEXTURE_TRASH: CompressedTexture2D = preload("res://Asset/Icons/trash-can.png")

const TEXTURE_RIGHT: CompressedTexture2D = preload("res://Asset/Icons/right.png")
const TEXTURE_DOWN: CompressedTexture2D = preload("res://Asset/Icons/down.png")
const TEXTURE_TOGGLE_BUTTON_CHECKED: CompressedTexture2D = preload("res://Asset/Icons/toggle-button.png")
const TEXTURE_TOGGLE_BUTTON_UNCHECKED: CompressedTexture2D = preload("res://Asset/Icons/toggle-button2.png")
const TEXTURE_MEGAPHONE: CompressedTexture2D = preload("res://Asset/Icons/megaphone.png")
const TEXTURE_FILE: CompressedTexture2D = preload("res://Asset/Icons/document.png")
const TEXTURE_FOLDER: CompressedTexture2D = preload("res://Asset/Icons/open-file.png")
const TEXTURE_CHECK: CompressedTexture2D = preload("res://Asset/Icons/check.png")
const TEXTURE_X_MARK: CompressedTexture2D = preload("res://Asset/Icons/x-mark.png")
const TEXTURE_SEARCH: CompressedTexture2D = preload("res://Asset/Icons/magnifying-glass.png")
const TEXTURE_MARKER: CompressedTexture2D = preload("res://Asset/Icons/location-marker.png")
const TEXTURE_KEYFRAME: CompressedTexture2D = preload("res://Asset/Icons/keyframe.png")

const style_accent_LEFT: StyleBoxFlat = preload("res://UI&UX/StyleAccentLeft.tres")
const STYLE_CORNERLESS: StyleBoxFlat = preload("res://UI&UX/CornerlessStyle.tres")
const STYLE_CORNERLESS_HOVER: StyleBoxFlat = preload("res://UI&UX/CornerlessHoverStyle.tres")
const STYLE_CORNERLESS_DARK: StyleBoxFlat = preload("res://UI&UX/CornerlessDarkStyle.tres")
const STYLE_CORNERLESS_BLACK: StyleBoxFlat = preload("res://UI&UX/CornerlessBlackStyle.tres")
const STYLE_CORNERLESS_WHITE: StyleBoxFlat = preload("res://UI&UX/StyleWhite.tres")

var style_box_empty: StyleBoxEmpty
var style_transparent: StyleBoxFlat
var style_dark: StyleBoxFlat
var style_panel: StyleBoxFlat
var style_header: StyleBoxFlat
var style_body: StyleBoxFlat
var style_accent: StyleBoxFlat
var style_button: StyleBoxFlat
var style_button_hover: StyleBoxFlat
var style_button_pressed: StyleBoxFlat
var style_button_accent: StyleBoxFlat
var style_line_edit: StyleBoxFlat
var style_line_edit_focus: StyleBoxFlat
var style_h_line: StyleBoxLine
var style_v_line: StyleBoxLine

var style_cornerless_transparent: StyleBoxFlat
var style_cornerless_dark: StyleBoxFlat
var style_cornerless_panel: StyleBoxFlat
var style_cornerless_header: StyleBoxFlat
var style_cornerless_body: StyleBoxFlat

const EDIT_BOX_MIN_SIZE: Vector2 = Vector2(32, 32)


func _ready() -> void:
	_init_styles()
	_update_styles()

func update_colors(_color_base: Color, _color_accent: Color, _contrast: float) -> void:
	color_base_dark = _color_base.darkened(_contrast / 2.)
	color_base_min = _color_base.darkened(_contrast / 4.)
	color_base_mid = _color_base
	color_base_max = _color_base.lightened(_contrast / 2.)
	color_accent = _color_accent
	color_accent_highlight = _color_accent.lightened(.4)
	color_accent_selection = Color(color_accent_highlight, .5)
	color_border = _color_base.lightened(.1)
	
	color_label = Color.LIGHT_GRAY if _color_base.get_luminance() < .5 else Color.BLACK
	color_label_transp = Color(color_label, .7)
	label_settings_main.font_color = color_label
	label_settings_main.outline_color = color_label
	label_settings_bold.font_color = color_label
	label_settings_bold.outline_color = color_label
	label_settings_header.font_color = color_label
	label_settings_header.outline_color = color_label
	
	if is_node_ready():
		_update_styles()
	
	colors_updated.emit()

func _init_styles() -> void:
	style_box_empty = StyleBoxEmpty.new()
	
	style_transparent = StyleBoxFlat.new()
	style_transparent.bg_color = Color(.2, .2, .2, .2)
	style_transparent.set_corner_radius_all(6)
	
	style_dark = StyleBoxFlat.new()
	style_dark.set_border_width_all(1)
	style_dark.set_corner_radius_all(6)
	
	style_panel = StyleBoxFlat.new()
	style_panel.set_border_width_all(1)
	style_panel.set_corner_radius_all(6)
	
	style_header = StyleBoxFlat.new()
	style_header.border_width_bottom = 2
	style_header.corner_radius_top_left = 6
	style_header.corner_radius_top_right = 6
	
	style_body = StyleBoxFlat.new()
	style_body.set_border_width_all(1)
	style_body.set_corner_radius_all(6)
	
	style_accent = StyleBoxFlat.new()
	style_accent.set_corner_radius_all(6)
	
	style_button = StyleBoxFlat.new()
	style_button.set_border_width_all(1)
	style_button.set_corner_radius_all(6)
	style_button.set_content_margin_all(12)
	style_button.content_margin_top = 8
	style_button.content_margin_bottom = 8
	
	style_button_hover = style_button.duplicate()
	style_button_pressed = style_button.duplicate()
	style_button_accent = style_button.duplicate()
	
	style_line_edit = StyleBoxFlat.new()
	style_line_edit.set_border_width_all(1)
	style_line_edit.set_corner_radius_all(4)
	style_line_edit.set_content_margin_all(12)
	style_line_edit.content_margin_top = 8
	style_line_edit.content_margin_bottom = 8
	
	style_line_edit_focus = style_line_edit.duplicate()
	style_line_edit_focus.set_border_width_all(2)
	
	style_h_line = StyleBoxLine.new()
	
	style_v_line = StyleBoxLine.new()
	style_v_line.vertical = true
	
	style_cornerless_transparent = StyleBoxFlat.new()
	style_cornerless_transparent.bg_color = Color(.2, .2, .2, .2)
	style_cornerless_dark = StyleBoxFlat.new()
	style_cornerless_panel = StyleBoxFlat.new()
	style_cornerless_header = StyleBoxFlat.new()
	style_cornerless_body = StyleBoxFlat.new()


func _update_styles():
	
	style_dark.bg_color = color_base_dark
	style_dark.border_color = color_border
	
	style_panel.bg_color = color_base_mid
	style_panel.border_color = color_border
	
	style_header.bg_color = color_base_min
	style_header.border_color = Color(color_accent, .8)
	
	style_body.bg_color = color_base_max
	style_body.border_color = color_border
	
	style_accent.bg_color = color_accent
	
	style_button.bg_color = color_base_mid
	style_button.border_color = color_border
	
	style_button_hover.bg_color = color_base_mid
	style_button_hover.border_color = color_accent
	
	style_button_pressed.bg_color = color_base_mid.darkened(.1)
	style_button_pressed.border_color = color_accent
	
	style_button_accent.bg_color = color_accent
	style_button_accent.border_color = color_accent.lightened(.2)
	
	style_line_edit.bg_color = color_base_min
	style_line_edit.border_color = color_border
	
	style_line_edit_focus.bg_color = color_base_mid
	style_line_edit_focus.border_color = color_accent
	
	style_h_line.color = color_border
	style_v_line.color = color_border
	
	style_cornerless_dark.bg_color = color_base_dark
	style_cornerless_panel.bg_color = color_base_mid
	style_cornerless_header.bg_color = color_base_min
	style_cornerless_body.bg_color = color_base_max
	
	var theme_font_controls: Array[Node] = get_tree().get_nodes_in_group(&"theme_font")
	var theme_icon_controls: Array[Node] = get_tree().get_nodes_in_group(&"theme_icon")
	
	for ctrl: Control in theme_font_controls: set_font_colors(ctrl)
	for ctrl: Control in theme_icon_controls: set_icon_colors(ctrl)
	
	if EditorServer.is_editor_server_ready:
		EditorServer.player.volume_control.queue_redraw()
		EditorServer.time_line2.update_timeline_view()




func expand(control: Control, h: bool = true, v: bool = false) -> void:
	if h:
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if v:
		control.size_flags_vertical = Control.SIZE_EXPAND_FILL

func set_base_settings(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	control.add_theme_stylebox_override(&"focus", style_box_empty)
	if not (control is LineEdit or control is TextEdit):
		control.focus_mode = Control.FOCUS_NONE

func set_base_container_settings(container: Control) -> void:
	set_base_settings(container)
	container.set_anchors_preset(Control.PRESET_FULL_RECT)

func set_base_panel_settings(panel: Control, style: StyleBox = null) -> void:
	set_base_settings(panel)
	panel.add_theme_stylebox_override(&"panel", style)

func set_base_label_settings(label: Label, label_settings: LabelSettings) -> void:
	set_base_settings(label)
	label.label_settings = label_settings

func set_font_from_label_settings(control: Control, label_settings: LabelSettings) -> void:
	control.add_theme_font_override(&"font", label_settings.font)
	control.add_theme_font_size_override(&"font_size", label_settings.font_size)
	control.add_theme_constant_override(&"outline_size", label_settings.outline_size)

func set_font_colors(control: Control) -> void:
	control.add_to_group(&"theme_font")
	control.add_theme_color_override(&"font_color", color_label_transp)
	control.add_theme_color_override(&"font_hover_color", color_label_transp)
	control.add_theme_color_override(&"font_pressed_color", color_label)
	control.add_theme_color_override(&"font_hover_pressed_color", color_label)
	control.add_theme_color_override(&"font_outline_color", color_label_transp)

func set_icon_colors(control: Control) -> void:
	control.add_to_group(&"theme_icon")
	control.add_theme_color_override(&"icon_normal_color", color_label_transp)
	control.add_theme_color_override(&"icon_hover_color", color_label_transp)
	control.add_theme_color_override(&"icon_pressed_color", color_label)
	control.add_theme_color_override(&"icon_hover_pressed_color", color_label)

func set_button_style(button: Button, style: StyleBox = STYLE_CORNERLESS_WHITE, hover: StyleBox = null, pressed: StyleBox = null) -> void:
	button.add_theme_stylebox_override(&"focus", style_box_empty)
	button.add_theme_stylebox_override(&"normal", style)
	button.add_theme_stylebox_override(&"hover", hover if hover else style)
	button.add_theme_stylebox_override(&"pressed", pressed if pressed else style)

func describe_box_container(box_container: BoxContainer, separation_scale: int, vertical: bool) -> void:
	set_base_container_settings(box_container)
	box_container.add_theme_constant_override(&"separation", separation_scale)
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

func create_panel_container(min_size: Vector2 = Vector2.ZERO, style: StyleBox = style_panel, more: Dictionary = {}) -> PanelContainer:
	var panel:= PanelContainer.new()
	set_base_panel_settings(panel, style)
	panel.custom_minimum_size = min_size
	ObjectServer.describe(panel, more)
	return panel

func create_margin_container(left:= 12, right:= 12, up:= 12, down:= 12, more: Dictionary = {}) -> MarginContainer:
	var margin_container:= MarginContainer.new()
	set_base_container_settings(margin_container)
	set_margin_settings(margin_container, left, right, up, down)
	ObjectServer.describe(margin_container, more)
	return margin_container

func set_margin_settings(margin_cont: MarginContainer, left: int, right: int, up: int, down: int) -> void:
	margin_cont.add_theme_constant_override(&"margin_left", left)
	margin_cont.add_theme_constant_override(&"margin_right", right)
	margin_cont.add_theme_constant_override(&"margin_top", up)
	margin_cont.add_theme_constant_override(&"margin_bottom", down)

func create_box_container(separation_scale: int = 16, vertical: bool = false, more: Dictionary = {alignment = BoxContainer.ALIGNMENT_CENTER, custom_minimum_size = Vector2(32, 32)}) -> BoxContainer:
	var box_container = BoxContainer.new()
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
	split_container.add_theme_stylebox_override("bg", style_body)
	split_container.vertical = vertical
	ObjectServer.describe(split_container, more)
	return split_container

func create_scroll_container(h_scroll_mode: int = 1, v_scroll_mode: int = 1, more: Dictionary = {}) -> ScrollContainer:
	var scroll_container = ScrollContainer.new()
	set_base_container_settings(scroll_container)
	scroll_container.horizontal_scroll_mode = h_scroll_mode
	scroll_container.vertical_scroll_mode = v_scroll_mode
	# Style scrollbars
	scroll_container.add_theme_stylebox_override("bg", style_body)
	ObjectServer.describe(scroll_container, more)
	return scroll_container

func create_viewport_container(more: Dictionary = {}) -> SubViewportContainer:
	var viewport_container: SubViewportContainer = SubViewportContainer.new()
	set_base_container_settings(viewport_container)
	ObjectServer.describe(viewport_container, more)
	return viewport_container

func create_button(text: String, icon: Texture2D = null, accent: bool = false, flat: bool = false, apply_icon_colors: bool = true, more: Dictionary = {}) -> Button:
	var button:= Button.new()
	set_base_settings(button)
	
	if accent:
		set_button_style(button, style_button_accent, style_button_accent, style_button_accent)
		set_font_from_label_settings(button, label_settings_bold)
	else:
		set_button_style(button, style_button, style_button_hover, style_button_pressed)
		set_font_from_label_settings(button, label_settings_main)
	
	set_font_colors(button)
	
	if apply_icon_colors:
		set_icon_colors(button)
	
	button.text = text
	button.icon = icon
	button.flat = flat
	
	ObjectServer.describe(button, more)
	return button


func create_menu_button(text: String, items_info: Array[Dictionary], more: Dictionary = {}) -> MenuButton:
	var button:= MenuButton.new()
	button.text = text
	button.switch_on_hover = true
	
	set_font_colors(button)
	
	var _popup: PopupMenu = button.get_popup()
	
	_describe_popup_menu(_popup, items_info)
	
	ObjectServer.describe(button, more)
	return button


func create_popup_menu(items_info: Array[Dictionary], more: Dictionary = {}) -> PopupMenu:
	var _popup_menu:= PopupMenu.new()
	_describe_popup_menu(_popup_menu, items_info)
	ObjectServer.describe(_popup_menu, more)
	return _popup_menu

func _describe_popup_menu(_popup_menu: PopupMenu, items_info: Array[Dictionary]) -> void:
	
	_popup_menu.add_theme_stylebox_override(&"panel", STYLE_CORNERLESS_DARK)
	_popup_menu.add_theme_stylebox_override(&"hover", STYLE_CORNERLESS)
	_popup_menu.add_theme_constant_override(&"icon_max_width", 16)
	
	for idx: int in items_info.size():
		
		var info: Dictionary = items_info[idx]
		
		_popup_menu.add_item(info.text if info.has(&"text") else "")
		
		if info.has(&"icon"):
			_popup_menu.set_item_icon(idx, info.icon)
		if info.has(&"disabled"):
			_popup_menu.set_item_disabled(idx, info.disabled)
		if info.has(&"as_separator"):
			_popup_menu.set_item_as_separator(idx, info.as_separator)
		if info.has(&"shortcut"):
			_popup_menu.set_item_shortcut(idx, info.shortcut)
			_popup_menu.set_item_shortcut_disabled(idx, true)
		if info.has(&"submenu"):
			_popup_menu.set_item_submenu_node(idx, info.submenu)



class CustomTextureButton extends TextureButton:
	
	var use_theme_main_color: bool = true
	
	func _ready() -> void:
		button_down.connect(set_self_modulate.bind(IS.color_accent))
		button_up.connect(update_button)
		IS.colors_updated.connect(update_button)
		update_button()
	
	func change_button_pressed(to: bool) -> void:
		button_pressed = to
		update_button()
	
	func update_button() -> void:
		var main_color: Color = IS.color_label if use_theme_main_color else Color.GRAY
		var toggle_color: Color = IS.color_accent if button_pressed else main_color
		set_self_modulate(toggle_color if toggle_mode else main_color)

func create_texture_button(normal: Texture2D, hover: Texture2D = null, pressed: Texture2D = null, toggle_mode: bool = false, more: Dictionary = {}) -> CustomTextureButton:
	var texture_button = CustomTextureButton.new()
	set_base_settings(texture_button)
	texture_button.toggle_mode = toggle_mode
	texture_button.stretch_mode = CustomTextureButton.STRETCH_KEEP_CENTERED
	texture_button.texture_normal = normal
	texture_button.texture_hover = hover if hover else normal
	texture_button.texture_pressed = pressed if pressed else normal
	
	texture_button.add_theme_stylebox_override(&"normal", style_button)
	texture_button.add_theme_stylebox_override(&"hover", style_button_hover)
	texture_button.add_theme_stylebox_override(&"pressed", style_button_pressed)
	
	ObjectServer.describe(texture_button, more)
	return texture_button


func create_panel(style: StyleBox = style_panel, more: Dictionary = {}) -> Panel:
	var panel = Panel.new()
	set_base_panel_settings(panel, style)
	ObjectServer.describe(panel, more)
	return panel

func create_v_line_panel(min_size: float = 1, color: Color = Color(1,1,1, .3), more: Dictionary = {size_flags_horizontal = Control.SIZE_SHRINK_CENTER}) -> Panel:
	var panel = create_panel(style_v_line.duplicate())
	panel.get_theme_stylebox("panel").color = color
	panel.custom_minimum_size.x = min_size
	ObjectServer.describe(panel, more)
	return panel

func create_h_line_panel(min_size: float = 1, color: Color = Color(1,1,1, .3), more: Dictionary = {size_flags_vertical = Control.SIZE_SHRINK_CENTER}) -> Panel:
	var panel = create_panel(style_h_line.duplicate())
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

func create_label(text: String, label_settings: LabelSettings = label_settings_main, more: Dictionary = {horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER, vertical_alignment = VERTICAL_ALIGNMENT_CENTER}) -> Label:
	var label = Label.new()
	set_base_label_settings(label, label_settings)
	label.text = text
	ObjectServer.describe(label, more)
	return label

func create_tree() -> Tree:
	var tree: Tree = Tree.new()
	expand(tree, true, true)
	tree.add_theme_constant_override(&"icon_max_width", 24)
	tree.add_theme_stylebox_override(&"focus", style_box_empty)
	return tree

func create_item_list(items: Array[Dictionary], more: Dictionary = {}) -> ItemList:
	var item_list: ItemList = ItemList.new()
	expand(item_list, true, true)
	
	for item_info: Dictionary in items:
		item_list.add_item(item_info.text, item_info.icon if item_info.has(&"icon") else null)
	
	ObjectServer.describe(item_list, more)
	return item_list

func create_progress_bar(curr_val: float, min_val: float, max_val: float, step: float, more:= {}) -> ProgressBar:
	var bar:= ProgressBar.new()
	set_base_settings(bar)
	bar.add_theme_stylebox_override("fill", style_accent)
	
	bar.min_value = min_val
	bar.max_value = max_val
	bar.step = step
	bar.value = curr_val
	ObjectServer.describe(bar, more)
	return bar


func create_category(has_header: bool, category_name: StringName, custom_color: Color = Color.BLACK, content_size: Vector2 = Vector2(32, 32), use_flex_container: bool = true, more: Dictionary = {}) -> Category:
	var category:= Category.new()
	set_base_settings(category)
	category.add_theme_stylebox_override("bg", style_body)
	ObjectServer.describe(category, {
		collapsed = true,
		vertical = true,
		has_header = has_header,
		category_name = category_name,
		category_custom_color = custom_color,
		content_control_size = content_size,
		use_flex_container = use_flex_container
	}.merged(more))
	return category

func create_menu(options: Array, is_vertical: bool = false, is_expanded: bool = true, more: Dictionary = {}) -> Menu:
	var menu = Menu.new()
	menu.options = options
	menu.is_vertical = is_vertical
	expand(menu, is_expanded, false)
	ObjectServer.describe(menu, more)
	return menu

func create_popuped_text(text: String = "", more: Dictionary = {}) -> PopupedText:
	var pop_text = PopupedText.new()
	set_base_panel_settings(pop_text, style_panel)
	pop_text.text = text
	ObjectServer.describe(pop_text, more)
	return pop_text

func create_popuped_menu(options: Array, more: Dictionary = {}) -> PopupedMenu:
	var pop_menu = PopupedMenu.new()
	set_base_panel_settings(pop_menu, style_panel)
	pop_menu.options = options
	ObjectServer.describe(pop_menu, more)
	return pop_menu

func create_popuped_categories_menu(options: Dictionary[MenuOption, Array], more: Dictionary = {}) -> PopupedCategoriesMenu:
	var pop_categories_menu:= PopupedCategoriesMenu.new(options)
	set_base_panel_settings(pop_categories_menu, style_panel)
	ObjectServer.describe(pop_categories_menu, more)
	return pop_categories_menu

func create_popuped_color_controller(main_color: Color, more: Dictionary = {}) -> PopupedColorController:
	var pop_color_controller = PopupedColorController.new()
	set_base_panel_settings(pop_color_controller, style_panel)
	pop_color_controller.curr_color = main_color
	ObjectServer.describe(pop_color_controller, more)
	return pop_color_controller

func create_popuped_box(elements: Array, more: Dictionary = {}) -> PopupedBox:
	var pop_box = PopupedBox.new()
	set_base_panel_settings(pop_box, style_panel)
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



func create_option_controller(options_info: Array[Dictionary], save_path: String = "", default_id: int = 0, accent: bool = false, more: Dictionary = {}) -> OptionController:
	var option_controller:= OptionController.new()
	set_base_settings(option_controller)
	
	if accent:
		set_button_style(option_controller, style_button_accent, style_button_accent, style_button_accent)
		set_font_from_label_settings(option_controller, label_settings_bold)
	else:
		set_button_style(option_controller, style_button, style_button_hover, style_button_pressed)
		set_font_from_label_settings(option_controller, label_settings_main)
	
	set_font_colors(option_controller)
	set_icon_colors(option_controller)
	
	option_controller.icon = TEXTURE_DOWN
	option_controller.options = MenuOption.new_options_with_check_group(options_info, save_path, default_id)
	option_controller.save_path = save_path
	option_controller.selected_id = default_id
	
	ObjectServer.describe(option_controller, more)
	return option_controller

func create_options_controller_2(val: int, options: Dictionary) -> OptionController:
	var ctrlr:= OptionController.new()
	set_base_settings(ctrlr)
	set_button_style(ctrlr, style_button, style_button_hover, style_button_pressed)
	set_font_from_label_settings(ctrlr, label_settings_bold)
	set_font_colors(ctrlr)
	set_icon_colors(ctrlr)
	var options_result: Array
	for option_text: String in options:
		options_result.append(MenuOption.new(option_text))
	ctrlr.icon = TEXTURE_DOWN
	ctrlr.options = options_result
	ctrlr.selected_id = val
	return ctrlr

func create_check_button(is_checked: bool = false, more: Dictionary = {}) -> CheckButton:
	var check_button:= CheckButton.new()
	set_base_settings(check_button)
	set_button_style(check_button, style_box_empty)
	check_button.add_theme_icon_override(&"checked", TEXTURE_TOGGLE_BUTTON_CHECKED)
	check_button.add_theme_icon_override(&"unchecked", TEXTURE_TOGGLE_BUTTON_UNCHECKED)
	check_button.button_pressed = is_checked
	ObjectServer.describe(check_button, more)
	return check_button

func create_line_edit(placeholder: String = "", text: String = "", right_icon: Texture2D = null, more: Dictionary = {size_flags_horizontal = Control.SIZE_EXPAND_FILL}) -> LineEdit:
	var line_edit:= LineEdit.new()
	set_base_settings(line_edit)
	line_edit.add_theme_color_override(&"selection_color", color_accent_selection)
	line_edit.add_theme_stylebox_override(&"normal", style_line_edit)
	line_edit.add_theme_stylebox_override(&"focus", style_line_edit_focus)
	line_edit.caret_blink = true
	line_edit.placeholder_text = placeholder
	line_edit.text = text
	line_edit.right_icon = right_icon
	ObjectServer.describe(line_edit, more)
	return line_edit

func create_text_edit(placeholder: String = "", text: String = "", more: Dictionary = {}) -> CustomTextEdit:
	var text_edit:= CustomTextEdit.new()
	set_base_settings(text_edit)
	text_edit.add_theme_color_override(&"selection_color", color_accent_selection)
	text_edit.add_theme_stylebox_override(&"normal", style_line_edit)
	text_edit.add_theme_stylebox_override(&"focus", style_line_edit_focus)
	text_edit.custom_minimum_size = Vector2(.0, 200.)
	text_edit.caret_blink = true
	text_edit.placeholder_text = placeholder
	text_edit.text = text
	expand(text_edit)
	ObjectServer.describe(text_edit, more)
	return text_edit

func create_slider_controller(curr_val: float, min_val: float, max_val: float, step: float, snap_step: float, more: Dictionary = {}) -> SliderController:
	var slider_controller:= SliderController.new()
	set_base_settings(slider_controller)
	slider_controller.min_val = min_val
	slider_controller.max_val = max_val
	slider_controller.step = step
	slider_controller.curr_val = curr_val
	slider_controller.snap_step = snap_step
	ObjectServer.describe(slider_controller, more)
	return slider_controller

func create_float_controller(curr_val: float, min_val: float, max_val: float, step: float, spin_scale: float = .01, spin_magnet_step: float = 10.0, is_int: bool = false, more: Dictionary = {}) -> FloatController:
	var float_controller:= FloatController.new()
	set_base_settings(float_controller)
	set_base_panel_settings(float_controller, style_button)
	#float_controller.texture_right = TEXTURE_RIGHT
	float_controller.min_val = min_val
	float_controller.max_val = max_val
	float_controller.step = step
	float_controller.spin_scale = spin_scale
	float_controller.spin_magnet_step = spin_magnet_step
	float_controller.set_curr_val_manually(curr_val)
	float_controller.is_int = is_int
	ObjectServer.describe(float_controller, more)
	return float_controller

func create_vec2_controller(curr_val: Vector2, more: Dictionary = {}) -> Vector2Controller:
	var vec2_controller:= Vector2Controller.new()
	vec2_controller.curr_val = curr_val
	ObjectServer.describe(vec2_controller, more)
	return vec2_controller

func create_vec3_controller(curr_val: Vector3) -> Vector3Controller:
	var vec3_controller:= Vector3Controller.new()
	vec3_controller.curr_val = curr_val
	return vec3_controller

func create_color_button(color: Color, more: Dictionary = {}) -> ColorButton:
	var color_button:= ColorButton.new()
	set_base_settings(color_button)
	set_button_style(color_button, style_button, style_button_hover, style_button_pressed)
	color_button.curr_color = color
	ObjectServer.describe(color_button, more)
	return color_button

func create_list_controller(list: Array, list_type: StringName = &"", can_add_element: bool = true, can_remove_element: bool = true, can_duplicate_element: bool = true, can_change_element_priority: bool = true, min_elements_count: int = 0, more: Dictionary = {}) -> ListController:
	var list_controller:= ListController.new()
	set_base_panel_settings(list_controller, style_body)
	set_base_settings(list_controller)
	list_controller.list = list
	list_controller.types = [list_type]
	list_controller.can_add_element = can_add_element
	list_controller.can_remove_element = can_remove_element
	list_controller.can_duplicate_element = can_duplicate_element
	list_controller.can_change_element_priority = can_change_element_priority
	list_controller.min_elements_count = min_elements_count
	ObjectServer.describe(list_controller, more)
	return list_controller

func create_color_range_control(color_range_res: ColorRangeRes, more: Dictionary = {}) -> ColorRangeControl:
	var color_range_control = ColorRangeControl.new()
	color_range_control.color_range_controller.color_range_res = color_range_res
	ObjectServer.describe(color_range_control, more)
	return color_range_control

enum StringControllerType {
	TYPE_LINE,
	TYPE_MULTILINE,
	TYPE_OPEN_FILE,
	TYPE_OPEN_DIR
}
enum FloatControllerType {
	TYPE_SPINBOX,
	TYPE_SLIDER,
	TYPE_OPTIONS,
	TYPE_360DEG
}

func create_edit_box(name: String, min_size: Vector2, vertical: bool = false, name_alignment: HorizontalAlignment = 0, keyframable: bool = false, more: Dictionary = {custom_minimum_size = min_size}) -> EditBoxContainer:
	var edit_box:= EditBoxContainer.new()
	edit_box.name_label.text = name.capitalize()
	edit_box.name_label.horizontal_alignment = name_alignment
	describe_box_container(edit_box, 8, vertical)
	ObjectServer.describe(edit_box, more)
	return edit_box

func create_custom_edit_box(name: String, edits_box_container: BoxContainer, min_size: Vector2 = EDIT_BOX_MIN_SIZE) -> EditBoxContainer:
	var box: EditBoxContainer = create_edit_box(name, min_size, true, 0, false)
	var panel_container: PanelContainer = create_panel_container()
	var margin_container: MarginContainer = create_margin_container(8,8,8,8)
	margin_container.add_child(edits_box_container)
	panel_container.add_child(margin_container)
	box.add_child(panel_container)
	return box

func connect_controller_to_edit_box(box: EditBoxContainer, controller: Control, connect_signal_func: Callable, set_func_id: StringName = "", set_func_manually_id: StringName = "", vari_id: StringName = "") -> void:
	connect_signal_func.call()
	box.controller = controller
	box.controller_set_ids = {
		method = set_func_id,
		method_manual = set_func_manually_id,
		vari = vari_id
	}

func create_option_edit(name: String, options_info: Array[Dictionary], save_path: String = "", default_id: int = 0, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box: EditBoxContainer = create_edit_box(name, min_size, false, name_alignment)
	var option_controller: OptionController = create_option_controller(options_info, save_path, default_id)
	expand(option_controller)
	box.add_child(option_controller)
	connect_controller_to_edit_box(box, option_controller, func() -> void: option_controller.selected_option_changed.connect(func(id: int, option: MenuOption) -> void: box.set_curr_val(id)), "set_selected_id", "set_selected_id_manually")
	return [option_controller]

func create_bool_edit(name: String, is_checked: bool, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box: EditBoxContainer = create_edit_box(name, min_size, false, name_alignment)
	var check_button: CheckButton = create_check_button(is_checked)
	box.add_child(check_button)
	connect_controller_to_edit_box(box, check_button, func() -> void: check_button.pressed.connect(func() -> void: box.set_curr_val(check_button.button_pressed)), "", "", "button_pressed")
	return [check_button]

func create_string_edit(name: String, text: String = "", placeholder: String = "", string_controller_type: StringControllerType = 0, filter: PackedStringArray = [], editable: bool = true, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box: EditBoxContainer = create_edit_box(name, min_size, string_controller_type == 1, name_alignment)
	
	if string_controller_type == StringControllerType.TYPE_MULTILINE:
		var text_edit: CustomTextEdit = create_text_edit(placeholder, text)
		text_edit.editable = editable
		box.add_child(text_edit)
		connect_controller_to_edit_box(
			box, text_edit, func() -> void:
				text_edit.text_changed.connect(func():
					box.set_curr_val(text_edit.get_text())),
			"set_text"
		)
		return [text_edit]
	
	else:
		var line_edit: LineEdit = create_line_edit(placeholder, text)
		line_edit.editable = editable
		expand(line_edit)
		connect_controller_to_edit_box(
			box, line_edit, func() -> void:
				line_edit.text_changed.connect(func(new_text: String) -> void: box.set_curr_val(new_text)),
			"set_text"
		)
		
		match string_controller_type:
			
			StringControllerType.TYPE_LINE:
				box.add_child(line_edit)
				return [line_edit]
			
			_:
				
				var on_btn_pressed: Callable
				var tex: Texture2D
				if string_controller_type == StringControllerType.TYPE_OPEN_FILE:
					tex = TEXTURE_FILE
					on_btn_pressed = func(btn: Button) -> void:
						var window: FileDialog = WindowManager.create_file_dialog_window(
						btn.get_window(), FileDialog.FileMode.FILE_MODE_OPEN_FILE, filter, Vector2i(800, 500), "Open File")
						window.current_dir = text
						window.popup_file_dialog()
						window.file_selected.connect(
							func(path: String) -> void:
								line_edit.text = path
								line_edit.text_changed.emit(path)
						)
				else:
					tex = TEXTURE_FOLDER
					on_btn_pressed = func(btn: Button) -> void:
						var window: FileDialog = WindowManager.create_file_dialog_window(
						btn.get_window(), FileDialog.FileMode.FILE_MODE_OPEN_DIR, filter, Vector2i(800, 500), "Open Folder")
						window.current_dir = text
						window.popup_file_dialog()
						window.dir_selected.connect(
							func(dir: String) -> void:
								line_edit.text = dir
								line_edit.text_changed.emit(dir)
						)
				
				var split_container: SplitContainer = IS.create_split_container()
				var open_file_btn: Button = create_button("", tex)
				open_file_btn.disabled = not editable
				
				split_container.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
				expand(split_container)
				
				split_container.add_child(line_edit)
				split_container.add_child(open_file_btn)
				box.add_child(split_container)
				
				open_file_btn.pressed.connect(on_btn_pressed.bind(open_file_btn))
				
				return [split_container]
	
	return []

func create_text_edit_edit(name: String, placeholder: String = "", text: String = "", min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box: EditBoxContainer = create_edit_box(name, min_size, true, name_alignment)
	var text_edit: TextEdit = create_text_edit(placeholder, text)
	expand(text_edit, false, true)
	box.add_child(text_edit)
	
	connect_controller_to_edit_box(box, text_edit, func() -> void: text_edit.text_changed.connect(func(): box.set_curr_val(text_edit.get_text())), "set_text")
	return [text_edit]

func create_float_edit(name: String, val: float, min: float = -INF, max: float = INF, step: float = .01, spin_scale: float = .01, spin_magnet_step: float = 10.0, is_int: bool = false, controller_type: FloatControllerType = FloatControllerType.TYPE_SPINBOX, options: Dictionary = {}, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box: EditBoxContainer = create_edit_box(name, min_size, controller_type == 1, name_alignment)
	var controller: Control
	
	match controller_type:
		
		FloatControllerType.TYPE_SPINBOX:
			controller = create_float_controller(val, min, max, step, spin_scale, spin_magnet_step, is_int)
			connect_controller_to_edit_box(box, controller, func() -> void:
				controller.val_changed.connect(box.set_curr_val), &"set_curr_val", &"set_curr_val_manually")
		
		FloatControllerType.TYPE_SLIDER:
			controller = create_slider_controller(val, min, max, step, spin_magnet_step)
			connect_controller_to_edit_box(box, controller, func() -> void:
				controller.val_changed.connect(box.set_curr_val), &"set_curr_val", &"set_curr_val_manually")
		
		FloatControllerType.TYPE_OPTIONS:
			controller = create_options_controller_2(val, options)
			connect_controller_to_edit_box(box, controller,
				func() -> void:
					controller.selected_option_changed.connect(
						func(id: int, option: MenuOption) -> void:
							box.set_curr_val(id)),
				&"set_selected_id", &"set_selected_id_manually"
			)
		
		FloatControllerType.TYPE_360DEG:
			pass
	
	expand(controller)
	box.add_child(controller)
	
	return [controller]

func create_vec2_edit(name: String, curr_val: Vector2, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box: EditBoxContainer = create_edit_box(name, min_size, false, name_alignment)
	var vec2_controller:= create_vec2_controller(curr_val)
	expand(vec2_controller)
	box.add_child(vec2_controller)
	connect_controller_to_edit_box(box, vec2_controller, func() -> void: vec2_controller.val_changed.connect(box.set_curr_val), "set_curr_val", "set_curr_val_manually")
	return [vec2_controller]

func create_vec3_edit(name: String, curr_val: Vector3, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box: EditBoxContainer = create_edit_box(name, min_size, false, name_alignment)
	var vec3_controller:= create_vec3_controller(curr_val)
	expand(vec3_controller)
	box.add_child(vec3_controller)
	connect_controller_to_edit_box(box, vec3_controller, func() -> void: vec3_controller.val_changed.connect(box.set_curr_val), "set_curr_val", "set_curr_val_manually")
	return [vec3_controller]

func create_color_edit(name: String, color: Color = Color.BLACK, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box: EditBoxContainer = create_edit_box(name, min_size, false, name_alignment)
	var color_button:= create_color_button(color)
	expand(color_button)
	box.add_child(color_button)
	
	connect_controller_to_edit_box(box, color_button, func(): color_button.color_changed.connect(box.set_curr_val), "set_curr_color", "set_curr_color_manually")
	return [color_button]

func create_list_edit(name: String, list: Array, list_type: StringName = &"", can_add_element: bool = true, can_remove_element: bool = true, can_duplicate_element: bool = true, can_change_element_priority: bool = true, min_elements_count: int = 0, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box: EditBoxContainer = create_edit_box(name, min_size, true, name_alignment)
	var list_controller: ListController = create_list_controller(list, list_type, can_add_element, can_remove_element, can_duplicate_element, can_change_element_priority, min_elements_count)
	expand(list_controller, true, true)
	box.add_child(list_controller)
	
	connect_controller_to_edit_box(box, list_controller,
	func() -> void:
		var callable = box.set_curr_val.bind(list)
		list_controller.list_changed.connect(callable)
		list_controller.list_val_changed.connect(func(index: int, val: Variant) -> void: callable.call()), "set_list", "set_list_manually")
	return [list_controller]

func create_color_range_edit(name: String, color_range_res: ColorRangeRes, min_size: Vector2 = EDIT_BOX_MIN_SIZE, name_alignment: int = 0) -> Array[Control]:
	var box:= create_edit_box(name, min_size, true, name_alignment)
	var color_range_control:= create_color_range_control(color_range_res)
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


func create_name_label(name: String, h_alignment: int = 0) -> Label:
	var label:= create_label(name.capitalize(), label_settings_main, {horizontal_alignment = h_alignment, vertical_alignment = 1, text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS})
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.custom_minimum_size.y = 30
	return label




func add_children(parent: Node, children: Array[Node]) -> void:
	for node: Node in children:
		parent.add_child(node)

func clear_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		child.queue_free()

