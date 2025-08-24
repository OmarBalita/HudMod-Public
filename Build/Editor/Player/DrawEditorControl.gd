class_name DrawEditControl extends FocusControl

@export var draw_edit: DrawEdit

@export_group("Theme")
@export_subgroup("Texture")
@export var texture_world_origin: Texture2D
@export var texture_median_point: Texture2D
@export var texture_individual_origins: Texture2D
@export var texture_point: Texture2D
@export var texture_line: Texture2D
@export var texture_edit_options: Texture2D
@export var texture_select_options: Texture2D
@export var texture_point_options: Texture2D
@export var texture_drawing_settings: Texture2D
@export var texture_pen: Texture2D
@export var texture_pointing: Texture2D
@export var texture_erase: Texture2D
@export var texture_fill: Texture2D
@export var texture_shaping: Texture2D


var edit_value_code: String:
	set(val):
		var empty_code = val.is_empty()
		edit_value_code = val
		draw_edit.set_edit_value(null if empty_code else val.to_float())
		if edit_label.is_node_ready():
			if empty_code: edit_label.set_text("")
			else: edit_label.set_text(str("Edit Scale: ", val, " X: ", draw_edit.get_x_editing(), " y: ", draw_edit.get_y_editing()))



var ui_profile: UIProfile = UIProfile.new()

# RealTime Nodes
var draw_shortcut_node:= ShortcutNode.new()
var edit_shortcut_node:= ShortcutNode.new()

@onready var top_bar_panel = InterfaceServer.create_panel_container(Vector2.ZERO, InterfaceServer.STYLE_BODY)
var top_bar_margin = InterfaceServer.create_margin_container(4,4,4,4)
var top_bar = InterfaceServer.create_box_container(10, false, {})

@onready var bottom_bar_panel = InterfaceServer.create_panel_container(Vector2.ZERO, InterfaceServer.STYLE_BODY)
var bottom_bar_margin = InterfaceServer.create_margin_container(4,4,4,4)
var bottom_bar = InterfaceServer.create_box_container(10, false, {})

@onready var draw_left_side_panel = InterfaceServer.create_panel_container()

var draw_ui_box = InterfaceServer.create_box_container(16)
var edit_ui_box = InterfaceServer.create_box_container(16)

var editor_mode_button: OptionController

var mouse_pos_label: Label
var selected_count_label: Label
var edit_label: Label

var brush_options_button: Button
var custom_properties_check_button: CheckButton
var custom_color_button: ColorButton
var custom_fill_color_button: ColorButton
var custom_width_controller: FloatController
var custom_strength_controller: FloatController
var pen_stabilize_check_button: CheckButton
var stiffness_controller: FloatController
var eraser_scale_controller: FloatController
var draw_shape_mode_button: OptionController
var draw_shape_is_centered_button: CheckButton
var fill_grid_size_controller: FloatController
var circle_subdv_controller: FloatController
var drawings_button: Button

var draw_mode_menu: Menu

var center_point_button: OptionController
var basic_options_button: Button
var select_options_button: Button
var point_options_button: Button
var drawing_settings_button: Button
var proportional_edit_check_button: CheckButton
var proportional_edit_options_button: OptionController
var proportional_edit_scale_controller: FloatController
var proportional_edit_connected_only_button: CheckButton




func _ready() -> void:
	super()
	
	_ready_shortcut_nodes()
	_ready_ui()
	
	var get_editor_mode = func() -> Variant: return draw_edit.editor_mode
	var get_draw_mode = func() -> Variant: return draw_edit.draw_mode
	var is_custom_properties = func() -> bool: return custom_properties_check_button.button_pressed
	var can_stabilized = func(): return get_draw_mode.call() in [0, 1]
	
	ui_profile.set_ui_conditions({
		[get_editor_mode, [1]]: [edit_ui_box, edit_shortcut_node],
		[get_editor_mode, [0]]: [draw_ui_box, draw_left_side_panel, draw_shortcut_node],
		[get_draw_mode, [0, 1, 3]]: [brush_options_button],
		[is_custom_properties, [true]]: [custom_color_button.get_parent(), custom_fill_color_button.get_parent(), custom_width_controller.get_parent(), custom_strength_controller.get_parent()],
		[can_stabilized, [true]]: [pen_stabilize_check_button.get_parent()],
		[func() -> bool: return can_stabilized.call() and draw_edit.pen_is_stabilize, [true]]: [stiffness_controller.get_parent()],
		[get_draw_mode, [2]]: [eraser_scale_controller.get_parent()],
		[get_draw_mode, [3]]: [fill_grid_size_controller.get_parent()],
		[get_draw_mode, [4]]: [draw_shape_mode_button, draw_shape_is_centered_button.get_parent()],
		[func() -> bool: return get_draw_mode.call() == 4 and draw_edit.draw_shape_mode == 2, [true]]: [circle_subdv_controller.get_parent()],
		[func() -> bool: return draw_edit.edit_is_proportional, [true]]: [proportional_edit_options_button, proportional_edit_scale_controller, proportional_edit_connected_only_button.get_parent()]
	})
	ui_profile.update()
	
	# Connections
	focus_changed.connect(on_focus_changed)
	draw_edit.editor_mode_changed.connect(on_draw_edit_editor_mode_changed)
	draw_edit.edit_finished.connect(on_draw_edit_edit_finished)
	draw_edit.selected_points_changed.connect(on_draw_edit_selected_points_changed)


func _ready_shortcut_nodes() -> void:
	_ready_draw_shortcut_node()
	_ready_edit_shortcut_node()

func _ready_draw_shortcut_node() -> void:
	pass

func _ready_edit_shortcut_node() -> void:
	# Basics
	edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_X, draw_edit.cut_selected)
	edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_C, draw_edit.copy_selected)
	edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_V, draw_edit.past_selected)
	edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_D, draw_edit.duplicate_selected)
	edit_shortcut_node.create_key_shortcut(0, KEY_DELETE, draw_edit.delete_selected)
	
	# Select
	edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_A, draw_edit.select_all.bind(true))
	edit_shortcut_node.create_key_shortcut(ALT_MASK, KEY_A, draw_edit.select_all.bind(false))
	edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_I, draw_edit.select_invert)
	edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_L, draw_edit.select_linked)
	edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_N, draw_edit.select_intermittent.bind(2))
	edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_R, draw_edit.select_random)
	
	# Points
	edit_shortcut_node.create_key_shortcut(0, KEY_G, draw_edit.set_is_editing.bind(1))
	edit_shortcut_node.create_key_shortcut(0, KEY_R, draw_edit.set_is_editing.bind(2))
	edit_shortcut_node.create_key_shortcut(0, KEY_S, draw_edit.set_is_editing.bind(3))
	edit_shortcut_node.create_key_shortcut(0, KEY_K, draw_edit.set_is_editing.bind(4))
	edit_shortcut_node.create_key_shortcut(0, KEY_X, draw_edit.set_axis_editing.bind(true, false))
	edit_shortcut_node.create_key_shortcut(0, KEY_Y, draw_edit.set_axis_editing.bind(false, true))
	
	edit_shortcut_node.create_key_shortcut(ALT_MASK, KEY_X, draw_edit.mirror.bind(true, false))
	edit_shortcut_node.create_key_shortcut(ALT_MASK, KEY_Y, draw_edit.mirror.bind(false, true))
	edit_shortcut_node.create_key_shortcut(ALT_MASK, KEY_Z, draw_edit.mirror)
	edit_shortcut_node.create_key_shortcut(ALT_MASK, KEY_F, draw_edit.close_selected)
	edit_shortcut_node.create_key_shortcut(ALT_MASK, KEY_T, draw_edit.separate_selected)
	edit_shortcut_node.create_key_shortcut(ALT_MASK, KEY_D, draw_edit.desolve_selected)
	edit_shortcut_node.create_key_shortcut(ALT_MASK, KEY_S, draw_edit.subdivide_selected)
	edit_shortcut_node.create_key_shortcut(0, KEY_E, draw_edit.extrude_selected)
	edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_J, draw_edit.join_selected)
	
	# Drawing Settings
	#edit_shortcut_node.create_key_shortcut(CTRL_MASK, KEY_M, open_drawing_settings)
	
	edit_shortcut_node.focus_control = self
	edit_shortcut_node.enabled = false
	
	add_child(edit_shortcut_node)


func _ready_ui() -> void:
	editor_mode_button = InterfaceServer.create_option_controller([
		{text = "Draw"},
		{text = "Edit"}
	], "", 0, true)
	top_bar.add_child(editor_mode_button)
	top_bar_margin.add_child(top_bar)
	top_bar_panel.add_child(top_bar_margin)
	add_child(top_bar_panel)
	
	mouse_pos_label = InterfaceServer.create_label('')
	selected_count_label = InterfaceServer.create_label('')
	edit_label = InterfaceServer.create_label('')
	InterfaceServer.add_childs(bottom_bar, [
		mouse_pos_label, InterfaceServer.create_v_line_panel(),
		selected_count_label, InterfaceServer.create_v_line_panel(), edit_label
	])
	bottom_bar.add_child(edit_label)
	bottom_bar_margin.add_child(bottom_bar)
	bottom_bar_panel.add_child(bottom_bar_margin)
	add_child(bottom_bar_panel)
	
	var bottom_bar = InterfaceServer.create_panel()
	
	_ready_draw_ui()
	_ready_edit_ui()
	
	top_bar_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bottom_bar_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	top_bar_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	bottom_bar_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	
	editor_mode_button.selected_option_changed.connect(on_editor_mode_button_selected_option_changed)


func _ready_draw_ui() -> void:
	
	var min_size = Vector2(250, 0)
	
	brush_options_button = InterfaceServer.create_button("Brush", null, false, false, {custom_minimum_size = min_size, expand_icon = true})
	custom_properties_check_button = InterfaceServer.create_bool_edit("Custom Properites", false, min_size, 1)[0]
	custom_color_button = InterfaceServer.create_color_edit("Line Color", draw_edit.custom_line_color, min_size, 1)[0]
	custom_fill_color_button = InterfaceServer.create_color_edit("Fill Color", draw_edit.custom_fill_color, min_size, 1)[0]
	custom_width_controller = InterfaceServer.create_float_edit("Radius", false, true, draw_edit.custom_width, 1.0, 1000.0, 1.0, 1.0, 10.0, true, null, null, min_size, 1)[1]
	custom_strength_controller = InterfaceServer.create_float_edit("Strength", false, true, draw_edit.custom_strength, .0, 1.0, .001, .01, 10.0, false, null, null, min_size, 1)[1]
	pen_stabilize_check_button = InterfaceServer.create_bool_edit("Stabilize", draw_edit.pen_is_stabilize, Vector2(150, 0), 1)[0]
	stiffness_controller = InterfaceServer.create_float_edit("Stiffness", false, true, draw_edit.stiffness, .01, 100.0, .01, .01, 10.0, false, null, null, min_size, 1)[1]
	eraser_scale_controller = InterfaceServer.create_float_edit("Eraser Scale", false, true, draw_edit.eraser_scale, 1.0, 1000.0, 1.0, 1.0, 10.0, true, null, null, min_size, 1)[1]
	draw_shape_mode_button = InterfaceServer.create_option_controller([{text = "Line"}, {text = "Rectangle"}, {text = "Circle"}], "", draw_edit.draw_shape_mode)
	draw_shape_is_centered_button = InterfaceServer.create_bool_edit("Shape is Centered", true, Vector2(150, 0), draw_edit.draw_shape_is_centered)[0]
	fill_grid_size_controller = InterfaceServer.create_float_edit("Fill Grid Size", false, true, draw_edit.fill_grid_size, 2, 10, 1, 1, 10, true, null, null, min_size, 1)[1]
	circle_subdv_controller = InterfaceServer.create_float_edit("Circle Subdvision", false, true, draw_edit.circle_subdv, 3, 4096, 1, 1, 10, true, null, null, min_size, 1)[1]
	drawings_button = InterfaceServer.create_button("Drawings", InterfaceServer.TEXTURE_DOWN)
	
	InterfaceServer.add_childs(draw_ui_box, [
		brush_options_button,
		custom_properties_check_button.get_parent(),
		custom_color_button.get_parent(),
		custom_fill_color_button.get_parent(),
		custom_width_controller.get_parent(),
		custom_strength_controller.get_parent(),
		pen_stabilize_check_button.get_parent(),
		stiffness_controller.get_parent(),
		eraser_scale_controller.get_parent(),
		draw_shape_mode_button,
		draw_shape_is_centered_button.get_parent(),
		fill_grid_size_controller.get_parent(),
		circle_subdv_controller.get_parent(),
		drawings_button
	])
	top_bar.add_child(draw_ui_box)
	
	brush_options_button.pressed.connect(on_brush_options_button_pressed)
	custom_properties_check_button.pressed.connect(on_custom_properties_check_button_pressed)
	custom_color_button.color_changed.connect(on_custom_color_button_color_changed)
	custom_fill_color_button.color_changed.connect(on_custom_fill_color_button_color_changed)
	custom_width_controller.val_changed.connect(on_custom_width_controller_val_changed)
	custom_strength_controller.val_changed.connect(on_custom_stength_controller_val_changed)
	pen_stabilize_check_button.pressed.connect(on_pen_stabilize_check_button_pressed)
	stiffness_controller.val_changed.connect(on_stiffness_controller_val_changed)
	eraser_scale_controller.val_changed.connect(on_eraser_scale_controller_val_changed)
	draw_shape_mode_button.selected_option_changed.connect(on_draw_shape_mode_button_selected_option_changed)
	draw_shape_is_centered_button.pressed.connect(on_draw_shape_is_centered_button_pressed)
	fill_grid_size_controller.val_changed.connect(on_fill_grid_size_controller_val_changed)
	circle_subdv_controller.val_changed.connect(on_circle_subdv_controller_val_changed)
	drawings_button.pressed.connect(on_drawings_button_pressed)
	
	var left_side_margin = InterfaceServer.create_margin_container(4,4,4,4)
	draw_mode_menu = InterfaceServer.create_menu([
		MenuOption.new("", texture_pen),
		MenuOption.new("", texture_pointing),
		MenuOption.new("", texture_erase),
		MenuOption.new("", texture_fill),
		MenuOption.new("", texture_shaping)
	], true)
	
	left_side_margin.add_child(draw_mode_menu)
	draw_left_side_panel.add_child(left_side_margin)
	add_child(draw_left_side_panel)
	
	draw_mode_menu.focus_index_changed.connect(on_draw_mode_menu_focus_index_changed)
	
	await draw_mode_menu.updated
	draw_left_side_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	draw_left_side_panel.mouse_filter = Control.MOUSE_FILTER_STOP


func _ready_edit_ui() -> void:
	
	center_point_button = InterfaceServer.create_option_controller([
		{text = "World Origin", icon = texture_world_origin},
		{text = "Media Point", icon = texture_median_point},
		{text = "Individual Origins", icon = texture_individual_origins}],
	"", draw_edit.center_type)
	
	basic_options_button = InterfaceServer.create_button("Edit", texture_edit_options)
	select_options_button = InterfaceServer.create_button("Select", texture_select_options)
	point_options_button = InterfaceServer.create_button("Points", texture_point_options)
	drawing_settings_button = InterfaceServer.create_button("Drawing Settings", texture_drawing_settings)
	
	proportional_edit_check_button = InterfaceServer.create_bool_edit("Proportional Edit", false, Vector2(250.0, .0), 1)[0]
	proportional_edit_options_button = InterfaceServer.create_option_controller([{text = "Smooth"}, {text = "Sphere"}, {text = "Sharp"}, {text = "Liner"}, {text = "Constant"}], "", 0)
	proportional_edit_scale_controller = InterfaceServer.create_float_controller(1.0, .01, 1000.0, .01, .01, 10.0, false, {custom_minimum_size = Vector2(120.0, .0)})
	proportional_edit_connected_only_button = InterfaceServer.create_bool_edit("Connected Only", false, Vector2(200.0, .0), 1)[0]
	
	InterfaceServer.add_childs(edit_ui_box, [
		center_point_button,
		basic_options_button,
		select_options_button,
		point_options_button,
		drawing_settings_button,
		proportional_edit_check_button.get_parent(),
		proportional_edit_options_button,
		proportional_edit_scale_controller,
		proportional_edit_connected_only_button.get_parent()
	])
	top_bar.add_child(edit_ui_box)
	
	center_point_button.selected_option_changed.connect(on_center_point_button_pressed)
	basic_options_button.pressed.connect(on_basic_options_button_pressed)
	select_options_button.pressed.connect(on_select_options_button_pressed)
	point_options_button.pressed.connect(on_point_options_button_pressed)
	drawing_settings_button.pressed.connect(on_drawing_settings_button_pressed)
	proportional_edit_check_button.pressed.connect(on_proportional_edit_check_button_pressed)
	proportional_edit_options_button.selected_option_changed.connect(on_proportional_edit_options_button_selected_option_changed)
	proportional_edit_scale_controller.val_changed.connect(on_proportional_scale_controller_val_changed)
	proportional_edit_connected_only_button.pressed.connect(on_proportional_edit_connected_only_button_pressed)


func _input(event: InputEvent) -> void:
	super(event)
	
	if not is_focus: return
	
	if event is InputEventKey and event.is_pressed():
		var alt = event.alt_pressed
		match event.keycode:
			KEY_UP when alt: draw_mode_menu.set_focus_index(draw_mode_menu.focus_index - 1)
			KEY_DOWN when alt: draw_mode_menu.set_focus_index(draw_mode_menu.focus_index + 1)
			KEY_ENTER:
				if draw_edit.is_editing:
					draw_edit.apply_editing(true)
			KEY_PERIOD:
				if not edit_value_code.contains("."):
					edit_value_code += "."
			KEY_MINUS:
				if edit_value_code.begins_with("-"): edit_value_code = edit_value_code.replace("-", "")
				else: edit_value_code = "-" + edit_value_code
			_:
				if event.keycode >= KEY_0 and event.keycode <= KEY_9:
					var number = event.keycode - KEY_0
					edit_value_code += str(number)
				
				elif event.keycode in [KEY_DELETE, KEY_BACKSPACE]:
					edit_value_code = edit_value_code.left(-1)
	
	elif event is InputEventMouseMotion:
		mouse_pos_label.set_text(str("Position: ", get_local_mouse_position() as Vector2i))


func update_draw_edit_enabling() -> void:
	draw_edit.enabled = is_focus


func popup_drawings_res_list(drawings: Array[GDDrawingRes], can_add_element: bool, pop_from: Control, popuped_controls: Array[Control] = []) -> ListController:
	var drawings_list_controller = InterfaceServer.create_list_controller(drawings, ["GDDrawingRes"], [], can_add_element)
	
	InterfaceServer.expand(drawings_list_controller, true, true)
	var popuped_box = InterfaceServer.popup_box(popuped_controls + [drawings_list_controller], pop_from, null, Vector2(400, 800))
	popuped_box.popdowned.connect(func() -> void:
		draw_edit.force_points_multimesh_visiblity = false
	)
	
	return drawings_list_controller


func popup_drawings_list(pop_from: Control, apply_to_all: bool, apply_to_selected_layers: bool, apply_to_selected: bool) -> ListController:
	var controls: Array[Control]
	
	if apply_to_all:
		var b = InterfaceServer.create_button("Apply to All Drawings", null, true); controls.append(b)
		b.pressed.connect(draw_edit.apply_focused_drawing_properties)
	if apply_to_selected_layers:
		var b = InterfaceServer.create_button("Apply to Selected Layers"); controls.append(b)
		b.pressed.connect(draw_edit.apply_focused_drawing_properties)
	if apply_to_selected:
		var b = InterfaceServer.create_button("Apply to Selected Drawings"); controls.append(b)
		b.pressed.connect(draw_edit.apply_focused_drawing_properties.bind(draw_edit.selected_points.keys()))
	
	var drawings_list = popup_drawings_res_list(draw_edit.draw_node.drawings_ress, false, pop_from, controls)
	drawings_list.list_changed.connect(draw_edit.draw_node.update_drawings)
	drawings_list.focus_index_changed.connect(draw_edit.set_focused_drawing_from_index)
	
	return drawings_list



func on_focus_changed(new_val: bool) -> void:
	update_draw_edit_enabling()


func on_draw_edit_editor_mode_changed(new_val: int) -> void:
	ui_profile.update()

func on_draw_edit_edit_finished() -> void:
	await get_tree().process_frame
	edit_value_code = ""

func on_draw_edit_selected_points_changed(selected_points_size: int, selected_points_center: Vector2) -> void:
	selected_count_label.set_text("Selected Count: %s" % selected_points_size)




func on_editor_mode_button_selected_option_changed(id: int, option: MenuOption) -> void:
	draw_edit.editor_mode = id
	ui_profile.update()


func on_brush_options_button_pressed() -> void:
	var brush_list = popup_drawings_res_list(draw_edit.brushes, true, brush_options_button)
	
	var name_func = func(index: int, element: GDDrawingRes, ready_update: bool) -> String: return element.brush_name
	var icon_func = func(index: int, element: GDDrawingRes, ready_update: bool) -> Texture2D:
		if not ready_update: await get_tree().create_timer(.3).timeout
		return ImageTexture.create_from_image(Image.load_from_file(element.get_brush_thumbnail_path()))
	
	brush_list.display_name_func = name_func
	brush_list.display_icon_func = icon_func
	
	brush_list.min_elements_count = 1
	brush_list.focus_index = draw_edit.get_curr_brush_index()
	brush_list.focus_index_changed.connect(func(index: int) -> void: on_brush_list_focus_index_changed(index, brush_list))


func on_custom_properties_check_button_pressed() -> void:
	draw_edit.use_custom_properties = custom_properties_check_button.button_pressed
	ui_profile.update()

func on_custom_color_button_color_changed(new_color: Color) -> void:
	draw_edit.custom_line_color = new_color

func on_custom_fill_color_button_color_changed(new_color: Color) -> void:
	draw_edit.custom_fill_color = new_color

func on_custom_width_controller_val_changed(new_val: float) -> void:
	draw_edit.custom_width = new_val

func on_custom_stength_controller_val_changed(new_val: float) -> void:
	draw_edit.custom_strength = new_val

func on_pen_stabilize_check_button_pressed() -> void:
	draw_edit.pen_is_stabilize = pen_stabilize_check_button.button_pressed
	ui_profile.update()

func on_stiffness_controller_val_changed(new_val: float) -> void:
	draw_edit.stiffness = new_val

func on_eraser_scale_controller_val_changed(new_val: float) -> void:
	draw_edit.eraser_scale = new_val

func on_draw_shape_mode_button_selected_option_changed(index: int, option: MenuOption) -> void:
	draw_edit.draw_shape_mode = index
	ui_profile.update()

func on_draw_shape_is_centered_button_pressed() -> void:
	draw_edit.draw_shape_is_centered = draw_shape_is_centered_button.button_pressed

func on_fill_grid_size_controller_val_changed(new_val: float) -> void:
	draw_edit.fill_grid_size = new_val

func on_circle_subdv_controller_val_changed(new_val: float) -> void:
	draw_edit.circle_subdv = new_val

func on_drawings_button_pressed() -> void:
	var drawings_list = popup_drawings_list(drawings_button, true, true, false)
	drawings_list.list_button_pressed.connect(on_drawings_list_controller_button_pressed)


func on_draw_mode_menu_focus_index_changed(index: int) -> void:
	draw_edit.draw_mode = index
	ui_profile.update()



func on_center_point_button_pressed(id: int, option: MenuOption) -> void:
	draw_edit.center_type = id

func on_basic_options_button_pressed() -> void:
	var menu = InterfaceServer.popup_menu([
		MenuOption.new("Cut", null, draw_edit.cut_selected),
		MenuOption.new("Copy", null, draw_edit.copy_selected),
		MenuOption.new("Past", null, draw_edit.past_selected),
		MenuOption.new("Duplicate", null, draw_edit.duplicate_selected),
		MenuOption.new("Delete", null, draw_edit.delete_selected),
	], basic_options_button)

func on_select_options_button_pressed() -> void:
	var menu = InterfaceServer.popup_menu([
		MenuOption.new("Select All", null, draw_edit.select_all.bind(true)),
		MenuOption.new("Deselect All", null, draw_edit.select_all.bind(false)),
		MenuOption.new("Select Invert", null, draw_edit.select_invert),
		MenuOption.new("Select Linked", null, draw_edit.select_linked),
		MenuOption.new("Select Intermittent", null, draw_edit.select_intermittent.bind(2)),
		MenuOption.new("Select Random", null, draw_edit.select_random),
	], select_options_button)

func on_point_options_button_pressed() -> void:
	var menu = InterfaceServer.popup_menu([
		MenuOption.new("Move", null, draw_edit.set_is_editing.bind(1)),
		MenuOption.new("Rotate", null, draw_edit.set_is_editing.bind(2)),
		MenuOption.new("Scale", null, draw_edit.set_is_editing.bind(3)),
		MenuOption.new("Point/s Radius", null, draw_edit.set_is_editing.bind(4)),
		MenuOption.new_line(),
		MenuOption.new("Mirror X", null, draw_edit.mirror.bind(true, false)),
		MenuOption.new("Mirror Y", null, draw_edit.mirror.bind(false, true)),
		MenuOption.new("Mirror", null, draw_edit.mirror),
		MenuOption.new_line(),
		MenuOption.new("Close", null, draw_edit.close_selected),
		MenuOption.new("Separate", null, draw_edit.separate_selected),
		MenuOption.new("Subdivide", null, draw_edit.subdivide_selected),
		MenuOption.new("Desolve", null, draw_edit.desolve_selected),
		MenuOption.new("Extrude", null, draw_edit.extrude_selected),
		MenuOption.new("Join", null, draw_edit.join_selected)
	], point_options_button)

func on_drawing_settings_button_pressed() -> void:
	
	var drawings_list = popup_drawings_list(drawing_settings_button, true, true, false)
	var focus_drawing = draw_edit.focused_drawing
	
	var draw_node = draw_edit.draw_node
	
	if focus_drawing:
		var index = draw_node.drawings_ress.find(focus_drawing)
		drawings_list.focus_index = index
	
	drawings_list.list_val_changed.connect(func(index: int, new_val: Variant) -> void:
		draw_edit.apply_focused_drawing_properties(draw_edit.selected_points.keys())
	)


func on_proportional_edit_check_button_pressed() -> void:
	draw_edit.edit_is_proportional = proportional_edit_check_button.button_pressed
	ui_profile.update()

func on_proportional_edit_options_button_selected_option_changed(index: int, option: MenuOption) -> void:
	draw_edit.proportional_edit_option = index

func on_proportional_scale_controller_val_changed(new_val: float) -> void:
	draw_edit.proportional_edit_scale = new_val

func on_proportional_edit_connected_only_button_pressed() -> void:
	draw_edit.proportional_edit_connected_only = proportional_edit_connected_only_button.button_pressed



func on_brush_list_focus_index_changed(index: int, brush_list: ListController) -> void:
	brush_list.set_button_display(index, brush_list.list[index], brush_options_button, true)
	draw_edit.set_curr_brush_index(index)

func on_drawings_list_controller_button_pressed(index: int) -> void:
	var curr_drawing_res = draw_edit.draw_node.drawings_ress[index]
	draw_edit.update_points_multimesh_instance(Callable(), [curr_drawing_res])
	draw_edit.force_points_multimesh_visiblity = true




