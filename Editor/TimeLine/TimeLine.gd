class_name TimeLine extends EditorRect


signal curr_frame_changed(new_val: int)
signal curr_frame_changed_automatically(new_val: int)
signal curr_frame_changed_manually(new_val: int)

signal curr_frame_played_manually()
signal curr_frame_stopped_manually()

signal timeline_played()
signal timeline_stoped()

signal timeline_view_changed()


# Editor Global Variables
# ---------------------------------------------------

enum TimelineSelectionModes {
	SELECT_MODE,
	SPLIT_MODE,
	SLIP_MODE
}

enum TimelineEditMode {
	EDIT_MODE_SINGLE,
	EDIT_MODE_MULTIPLE,
}

enum TimelineStates {
	IDLE,
	DRAG,
	DRAG_CURSOR,
	EXPAND_MEDIA_CLIP,
}

enum MediaClipPlaceMethod {
	PLACE_METHOD_PLACE_ON_TOP,
	PLACE_METHOD_INSERT,
	PLACE_METHOD_OVERWRITE,
	PLACE_METHOD_FIT_TO_FILL,
	PLACE_METHOD_REPLACE
}

@export_group("Properties")

@export var timeline_selection_mode: TimelineSelectionModes:
	set(val):
		timeline_selection_mode = val
		match val:
			0: mouse_default_cursor_shape = Control.CURSOR_ARROW
			1: mouse_default_cursor_shape = Control.CURSOR_IBEAM
			2: mouse_default_cursor_shape = Control.CURSOR_HSPLIT
		edited_media_clip = null
		queue_redraw()

@export var timeline_edit_mode: TimelineEditMode = 1

@export var timeline_state: TimelineStates:
	set(val):
		timeline_state = val
		shortcut_node.enabled = val == 0

@export var media_clip_place_method: MediaClipPlaceMethod

@export var is_snap_to_timemarks: bool = true
@export var is_snap_to_timemarkers_and_cursor: bool = true
@export var is_magnet_to_media_clips: bool = true

@export_subgroup("Zoom")
@export var zoom: float = 100.0:
	set(val):
		zoom = clamp(val, min_zoom, max_zoom)
		queue_redraw()
		timeline_view_changed.emit()

@export_range(.01, 10.0, .01) var zoom_step: float = .05
@export_range(1.0, 1000.0) var min_zoom: float = 1.0
@export_range(1.0, 10000.0) var max_zoom: float = 5000.0

@export_group("Layers")
#@export_range(1, 200) var layer_display_size: float = 80.0
@export_range(1, 1000) var layer_side_panel_x_size: float = 280.0
@export_range(1, 10) var default_layers_count: int = 2
@export_range(1, 100) var max_layers_count: int = 5

@export_group("Theme")
@export_subgroup("Texture", "texture")
@export var texture_select_mode: Texture2D
@export var texture_split_mode: Texture2D
@export var texture_slip_mode: Texture2D
@export var texture_split: Texture2D
@export var texture_split_right: Texture2D
@export var texture_split_left: Texture2D
@export var texture_marker: Texture2D
@export var texture_snap_cursor: Texture2D
@export var texture_snap_markers: Texture2D
@export var texture_magnet_clips: Texture2D
@export var texture_link: Texture2D
@export var texture_zoom_in: Texture2D
@export var texture_zoom_out: Texture2D
@export var texture_place_on_top: Texture2D
@export var texture_insert: Texture2D
@export var texture_overwrite: Texture2D
@export var texture_fit_to_fill: Texture2D
@export var texture_replace: Texture2D

@export_subgroup("Constant")
@export var timemarks_bg_size: float = 30:
	set(val):
		timemarks_bg_size = val
		queue_redraw()
@export_range(1, 1000) var timemarks_between: int = 20:
	set(val):
		timemarks_between = val
		queue_redraw()
@export var cursor_width: float = 1.5:
	set(val):
		cursor_width = val
		queue_redraw()
@export_subgroup("Color", "color")
@export var color_timemarks_bg: Color = Color("191919"):
	set(val):
		color_timemarks_bg = val
		queue_redraw()
@export var color_timemarks: Color = Color.DIM_GRAY:
	set(val):
		color_timemarks = val
		queue_redraw()
@export var color_cursor: Color = Color.WHITE:
	set(val):
		color_cursor = val
		queue_redraw()
@export var color_layer: Color = Color.DIM_GRAY:
	set(val):
		color_layer = val
		queue_redraw()

# Resources
# ---------------------------------------------------

@export var editor_settings: AppEditorSettings = EditorServer.editor_settings
@export var media_clips_selection_group: SelectionGroupRes = EditorServer.media_clips_selection_group

# RealTime Variables
# ---------------------------------------------------

var is_playing: bool:
	set(val):
		is_playing = val
		if is_playing:
			step_frame()

var start_time = 0.0

var emit_frame_changed: bool = true

var curr_frame: int:
	set(val):
		curr_frame = val
		EditorServer.set_frame(val)
		ProjectServer.update_scene_objects()
		queue_redraw()
		if emit_frame_changed:
			curr_frame_changed.emit(val)

var snap_pos:
	set(val):
		snap_pos = val
		queue_redraw()

var displacement_pos: Vector2:
	set(val):
		displacement_pos = val
		queue_redraw()
		timeline_view_changed.emit()

var curr_layers: Dictionary[int, Layer]

var display_snap_dist: float
var display_snap_step: int
var display_frame_size: float
var display_cursor_pos: int

var select_rect: Rect2

# RealTime Nodes
# ---------------------------------------------------

var path_controller: PathController

var layers_scroll_container: ScrollContainer
var layers_container: BoxContainer

var clips_selection_box: SelectionBox

var timemarkers_parent: Control
var timemarkers_nodes: Dictionary[int, TimeMarker]

var edited_media_clip: MediaClip

var selection_mode_button: OptionController
var edit_mode_button: OptionController


# Set Get Functions
# ---------------------------------------------------

func set_timeline_state(state: TimelineStates) -> void:
	timeline_state = state

func set_curr_frame_manually(frame: Variant) -> void:
	
	if frame == null:
		frame = get_frame_from_display_pos(get_global_mouse_position().x, [], false).keys()[0]
	stop()
	curr_frame = frame
	curr_frame_changed_manually.emit(curr_frame)

func is_timeline_state_equal_to(state: TimelineStates) -> bool:
	return state == timeline_state

func set_snap_pos(new_val: Variant) -> void:
	snap_pos = new_val


# Background Called Functions
# ---------------------------------------------------

func _init() -> void:
	super()
	editor_guides = [
		{"Move Cursor": "[Mouse-Left]"},
		{"Move TimeLine": "[Mouse-Right]"},
		{"Move Layers": "[Mouse-Right] + [Shift]"}
	]


func _ready_editor() -> void:
	# Start ShortCuts
	shortcut_node.create_key_shortcut(CTRL_MASK, KEY_A, select_all_media_clips)
	shortcut_node.create_key_shortcut(ALT_MASK, KEY_A, deselect_all_media_clips)
	shortcut_node.create_key_shortcut(CTRL_MASK, KEY_X, copy_media_clips.bind(true))
	shortcut_node.create_key_shortcut(CTRL_MASK, KEY_C, copy_media_clips.bind(false))
	shortcut_node.create_key_shortcut(CTRL_MASK, KEY_V, past_media_clips)
	shortcut_node.create_key_shortcut(CTRL_MASK, KEY_D, duplicate_media_clips)
	shortcut_node.create_key_shortcut(0, KEY_DELETE, remove_media_clips)
	shortcut_node.create_key_shortcut(0, KEY_X, split_media_clips.bind(true, true))
	shortcut_node.create_key_shortcut(0, KEY_C, split_media_clips.bind(true, false))
	shortcut_node.create_key_shortcut(0, KEY_Z, split_media_clips.bind(false, true))
	shortcut_node.create_key_shortcut(0, KEY_TAB, func() -> void:
		timeline_selection_mode += 1
		if timeline_selection_mode > TimelineSelectionModes.size() - 1:
			timeline_selection_mode = 0
		selection_mode_button.set_selected_id(timeline_selection_mode)
	)
	shortcut_node.create_key_shortcut(0, KEY_ENTER, enter_media_clip)
	shortcut_node.create_key_shortcut(0, KEY_BACKSPACE, ProjectServer.exit_media_clip_children.bind(1))
	shortcut_node.create_key_shortcut(CTRL_MASK, KEY_G, open_graph_editor)
	shortcut_node.create_key_shortcut(ALT_MASK, KEY_G, close_graph_editor)
	shortcut_node.cond_func = func() -> bool:
		return EditorServer.graph_editors_focused.is_empty()
	
	# Start Connections
	
	ProjectServer.media_clip_entered.connect(on_project_server_media_clip_entered)
	ProjectServer.media_clip_exited.connect(on_project_server_media_clip_exited)
	ProjectServer.layer_added.connect(on_project_server_layer_added)
	ProjectServer.layer_removed.connect(on_project_server_layer_removed)
	ProjectServer.layers_added.connect(on_project_server_layers_added)
	ProjectServer.layers_removed.connect(on_project_server_layers_removed)
	ProjectServer.layer_property_changed.connect(on_project_server_layer_property_changed)
	ProjectServer.time_markers_changed.connect(on_project_server_timemarkers_changed)
	ProjectServer.curr_layers_changed.connect(on_project_server_curr_layers_changed)
	
	EditorServer.player.curr_frame_changed.connect(on_player_curr_frame_changed)
	
	media_clips_selection_group.selected_objects_changed.connect(on_media_clips_selection_group_changed)
	
	resized.connect(on_resized)
	l_button_downed.connect(on_l_button_downed)
	l_button_upped.connect(on_l_button_upped)
	
	press_functions = {
		KEY_LEFT: on_key_left_pressed,
		KEY_RIGHT: on_key_right_pressed,
	}
	
	# Start
	start_selection_box()
	start_layers()
	start_toolbar()
	start_timemarkers()



func _physics_process(delta: float) -> void:
	
	match timeline_state:
		0:
			pass
		1:
			drag(delta)
		2:
			drag(delta, true, false)
			set_curr_frame_manually(null)
		3:
			drag(delta, true, false)


var right_button_down: bool

func _input(event: InputEvent) -> void:
	super(event)
	
	if event is InputEventMouseMotion:
		if right_button_down:
			displacement_pos -= Vector2(event.relative.x / display_snap_dist, .0)
			if KEY_SHIFT in pressed_keys and not EditorServer.graph_editors_focused:
				layers_scroll_container.scroll_vertical -= event.relative.y
		
		elif is_focus and timeline_selection_mode != 0:
			var media_clips_focused: Array[MediaClip] = EditorServer.media_clips_focused
			if media_clips_focused.size(): edited_media_clip = media_clips_focused[0]
			else: edited_media_clip = null
			queue_redraw()
		
		elif timeline_state == 1:
			clips_moved()
		#timemarks_bg_mouse_entered = get_local_mouse_position().y < header_size + timemarks_bg_size
	
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT when is_focus:
				if event.is_released():
					if edited_media_clip:
						if timeline_selection_mode == 1:
							edited_media_clip.split(true, true, get_frame_from_mouse_pos())
					else:
						snap_pos = null
			MOUSE_BUTTON_RIGHT:
				if event.is_pressed(): right_button_down = is_focus
				else: right_button_down = false
			
			_ when is_focus:
				if not event.shift_pressed:
					if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
						zoom -= zoom_step * zoom
					elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
						zoom += zoom_step * zoom

func _draw() -> void:
	
	var curr_timemarks_between: float = .0
	var raw_interval: float = timemarks_between / zoom
	var steps: float = .1
	while not curr_timemarks_between:
		if raw_interval > steps:
			steps *= 2.0
			continue
		curr_timemarks_between = steps
	
	var timemarks_count: float = size.x / (curr_timemarks_between * zoom)
	display_snap_dist = size.x / timemarks_count
	
	var raw_step: int = int(max_zoom / zoom * steps)
	display_snap_step = max(1, raw_step)
	display_frame_size = display_snap_dist / display_snap_step
	
	var min_diff: float = INF
	
	#for step in RESULT_STEPS:
		#var diff = abs(step - raw_step)
		#if diff < min_diff:
			#min_diff = diff
			#display_snap_step = step
	
	# Draw Limits
	
	var start_and_end: Array[int] = ProjectServer.get_start_and_end_frame()
	var frame_start_in: int = start_and_end[0]
	var frame_end_in: int = start_and_end[1]
	
	var left_from_x_pos: float = layer_side_panel_x_size + 12
	var right_to_x_pos: float = size.x
	var left_to_x_pos: float = clamp(get_display_pos_from_frame(frame_start_in), left_from_x_pos, right_to_x_pos)
	var right_from_x_pos: float = clamp(get_display_pos_from_frame(frame_end_in), left_from_x_pos, right_to_x_pos)
	
	var limit_rect_color: Color = Color(Color.BLACK, .3)
	
	draw_rect(Rect2(Vector2(left_from_x_pos, .0), Vector2(left_to_x_pos - left_from_x_pos, size.y)), limit_rect_color)
	draw_rect(Rect2(Vector2(right_from_x_pos, .0), Vector2(right_to_x_pos - right_from_x_pos, size.y)), limit_rect_color)
	draw_line(Vector2(left_from_x_pos, .0), Vector2(left_from_x_pos, size.y), Color.BLACK, 2.0)
	draw_line(Vector2(left_to_x_pos, .0), Vector2(left_to_x_pos, size.y), Color.BLACK, 2.0)
	draw_line(Vector2(right_from_x_pos, .0), Vector2(right_from_x_pos, size.y), Color.BLACK, 2.0)
	draw_line(Vector2(right_to_x_pos, .0), Vector2(right_to_x_pos, size.y), Color.BLACK, 2.0)
	
	# Draw TimeMarkers
	draw_rect(
		Rect2(Vector2(.0, header_size), Vector2(size.x, timemarks_bg_size)),
		color_timemarks_bg
	)
	
	for i: int in range(displacement_pos.x, displacement_pos.x + timemarks_count):
		var curr_frame: int = i * display_snap_step
		var is_marked: bool = i == snapped(i, 6) or zoom >= max_zoom - 3000.0
		var x_pos: int = (i - displacement_pos.x) * display_snap_dist
		var from: Vector2 = Vector2(x_pos, header_size)
		var to: Vector2 = from + Vector2.DOWN * (5.0 + 20.0 * int(is_marked))
		draw_line(from, to, color_timemarks, 2.0)
		if is_marked:
			draw_string(font_main,
			to + Vector2.RIGHT * 10.0,
			str(curr_frame, "f") # if zoom >= 100.0 else frames_to_timecode(curr_frame, 30, true)
		)
	
	draw_line(Vector2(.0, header_size), Vector2(size.x, header_size), Color(Color.CORNFLOWER_BLUE, .7), 3.0)
	
	
	# Draw Cursor
	display_cursor_pos = get_display_pos_from_frame(curr_frame)
	var cursor_from: Vector2 = Vector2(display_cursor_pos, header_size - 12)
	var timemarks_end: float = header_size + timemarks_bg_size
	
	if display_cursor_pos > layer_side_panel_x_size + 12.0:
		draw_line(
			cursor_from,
			Vector2(display_cursor_pos, size.y),
			color_cursor.darkened(.4),
			cursor_width
		)
	draw_polygon(PackedVector2Array([
		Vector2(display_cursor_pos, timemarks_end - 12),
		Vector2(display_cursor_pos + 12, timemarks_end - 12),
		Vector2(display_cursor_pos, timemarks_end)
	]), PackedColorArray([color_cursor]))
	
	var curr_frame_string: String
	if editor_settings.timeline_frame_mode == 0: curr_frame_string = str(curr_frame)
	else: curr_frame_string = TimeServer.frame_to_timecode(curr_frame)
	draw_rect(Rect2(cursor_from, Vector2(curr_frame_string.length() * 12, timemarks_bg_size)), color_cursor)
	draw_string(font_main, cursor_from + Vector2(curr_frame_string.length(), 37), curr_frame_string, 0, -1, 16, Color.BLACK)
	
	
	# Draw Snap Line
	if snap_pos != null:
		var display_snap_pos = get_display_pos_from_frame(snap_pos)
		draw_dashed_line(Vector2(display_snap_pos, header_size), Vector2(display_snap_pos, size.y), Color.ORANGE, 1.0, 10)
	
	# Draw Split Line on Top of Layer
	if edited_media_clip != null:
		match timeline_selection_mode:
			TimelineSelectionModes.SPLIT_MODE:
				var display_split_pos: int = get_display_pos_from_mouse_pos()
				var y_pos: int = edited_media_clip.global_position.y - global_position.y
				draw_line(
					Vector2(display_split_pos, y_pos),
					Vector2(display_split_pos, y_pos + edited_media_clip.size.y),
					Color.RED,
					2.0
				)
	
	super()
	
	update_timemarkers()




# ---------------------------------------------------

func start_toolbar() -> void:
	
	var split_container:= IS.create_split_container()
	var toolbar_left_container:= IS.create_box_container(16, false, {alignment = BoxContainer.ALIGNMENT_BEGIN})
	var toolbar_right_container:= IS.create_box_container(16, false, {alignment = BoxContainer.ALIGNMENT_END})
	
	var splittool_panel:= IS.create_panel_container()
	var splittool_container:= IS.create_box_container()
	var splittool_margin:= IS.create_margin_container(4, 4, 4, 4)
	
	path_controller = PathController.new()
	path_controller.set_root_name("Root")
	path_controller.update([])
	
	var snaptool_panel:= IS.create_panel_container()
	var snaptool_container:= IS.create_box_container()
	var snaptool_margin:= IS.create_margin_container(4, 4, 4, 4)
	
	selection_mode_button = IS.create_option_controller([
		{text = "Select Mode", icon = texture_select_mode},
		{text = "Split Mode", icon = texture_split_mode},
		{text = "Slip Mode", icon = texture_slip_mode}
	], "", timeline_selection_mode, true)
	edit_mode_button = IS.create_option_controller([
		{text = "Edit Single"},
		{text = "Edit Multiple"},
	], "", timeline_edit_mode)
	var split_left_button:= IS.create_texture_button(texture_split_left)
	var split_button:= IS.create_texture_button(texture_split)
	var split_right_button:= IS.create_texture_button(texture_split_right)
	var marker_button:= IS.create_texture_button(texture_marker)
	
	var snap_markers_button:= IS.create_texture_button(texture_snap_markers, null, null, true, {button_pressed = is_snap_to_timemarks})
	var magnet_clips_button:= IS.create_texture_button(texture_magnet_clips, null, null, true, {button_pressed = is_magnet_to_media_clips})
	var clips_overlay_menu: Menu = IS.create_menu([
		MenuOption.new("", texture_place_on_top),
		MenuOption.new("", texture_insert),
		MenuOption.new("", texture_overwrite),
		MenuOption.new("", texture_fit_to_fill),
		MenuOption.new("", texture_replace),
	], false, false, {custom_minimum_size = Vector2(300.0, .0)})
	#var zoom_slider:= IS.create_slider_control(zoom, min_zoom, max_zoom, 500.0, texture_zoom_out, texture_zoom_in)
	var snap_cursor_button:= IS.create_texture_button(texture_snap_cursor, null, null, true, {button_pressed = is_snap_to_timemarkers_and_cursor})
	
	splittool_panel.add_child(splittool_margin)
	splittool_margin.add_child(splittool_container)
	splittool_container.add_child(split_left_button)
	splittool_container.add_child(split_button)
	splittool_container.add_child(split_right_button)
	
	snaptool_panel.add_child(snaptool_margin)
	snaptool_margin.add_child(snaptool_container)
	snaptool_container.add_child(snap_markers_button)
	snaptool_container.add_child(snap_cursor_button)
	snaptool_container.add_child(magnet_clips_button)
	
	toolbar_left_container.add_child(selection_mode_button)
	toolbar_left_container.add_child(edit_mode_button)
	toolbar_left_container.add_child(splittool_panel)
	toolbar_left_container.add_child(marker_button)
	toolbar_left_container.add_child(path_controller)
	
	toolbar_right_container.add_child(clips_overlay_menu)
	#toolbar_right_container.add_child(zoom_slider)
	toolbar_right_container.add_child(snaptool_panel)
	
	split_container.add_child(toolbar_left_container)
	split_container.add_child(toolbar_right_container)
	header.add_child(split_container)
	
	selection_mode_button.selected_option_changed.connect(on_selection_mode_button_selected_option_changed)
	edit_mode_button.selected_option_changed.connect(on_edit_mode_button_selected_option_changed)
	split_button.pressed.connect(on_split_button_pressed)
	split_left_button.pressed.connect(on_split_left_button_pressed)
	split_right_button.pressed.connect(on_split_right_button_pressed)
	marker_button.pressed.connect(on_marker_button_pressed)
	path_controller.undo_requested.connect(on_path_controller_undo_requested)
	snap_markers_button.pressed.connect(on_snap_markers_button_pressed)
	snap_cursor_button.pressed.connect(on_snap_cursor_button_pressed)
	magnet_clips_button.pressed.connect(on_magnet_clips_button_pressed)
	clips_overlay_menu.focus_index_changed.connect(on_clips_overlay_menu_focus_index_changed)
	#zoom_slider.slider_controller.val_changed.connect(on_zoom_slider_val_changed)


func start_selection_box() -> void:
	clips_selection_box = IS.create_selection_box([], request_selection_box_selection)
	clips_selection_box.set_id_key_function_name("get_id_key")
	clips_selection_box.selection_ended.connect(on_clips_selection_box_selection_ended)
	body.add_child(clips_selection_box)

func calculate_select_rect() -> Rect2:
	var select_from_pos: Vector2 = Vector2(layer_side_panel_x_size + 15, header_size + timemarks_bg_size)
	var select_to_pos: Vector2 = Vector2(size.x - 25.0, size.y)
	select_rect = Rect2(select_from_pos, select_to_pos - select_from_pos)
	return select_rect

func is_inside_rect_has_point(point: Vector2) -> bool:
	return select_rect.has_point(point)

func request_selection_box_selection() -> bool:
	# Approximate numbers for the required Rect
	var cond1: bool = is_inside_rect_has_point(get_local_mouse_position())
	var cond2: bool = timeline_selection_mode == 0
	var cond3: bool = EditorServer.is_timeline_selection_enabled()
	return cond1 and cond2 and cond3

func request_media_clip_selection() -> bool:
	var cond1: bool = is_inside_rect_has_point(get_local_mouse_position())
	var cond2: bool = timeline_selection_mode == 0
	var cond3: bool = EditorServer.is_media_clip_selection_enabled()
	return cond1 and cond2 and cond3



#func update_selection_box_enabling() -> void:
	#if clips_selection_box:
		#clips_selection_box.enabled = timeline_selection_mode == 0 and not timemarks_bg_mouse_entered

func start_layers() -> void:
	layers_scroll_container = IS.create_scroll_container(1, 1, {mouse_filter = MOUSE_FILTER_IGNORE})
	var margin_container: MarginContainer = IS.create_margin_container(0, 6, timemarks_bg_size, 100)
	layers_container = IS.create_box_container(0, true, {"clip_contents": true})
	margin_container.add_child(layers_container)
	layers_scroll_container.add_child(margin_container)
	body.add_child(layers_scroll_container, )
	body.move_child(layers_scroll_container, 0)
	IS.expand(margin_container)
	
	await resized
	ProjectServer.make_layers_absolute(PackedInt32Array(range(default_layers_count)))

#func update_layers(delay_to_update_pos: bool = true) -> void:
	#
	#var layers_count: int = int(size.y / layer_display_size)
	#var layers_displacement: int = int(displacement_pos.y / layer_display_size)
	#var layers_range: Array = range(layers_displacement, layers_displacement + layers_count + 1)
	#
	## Spawn Remaining Layers
	#var layers_before: Array[int]
	#
	#for index in layers_range:
		#if index in curr_layers_range or index > 0:
			#continue
		#var layer = get_layer_from_index(-index)
		#if layer == null:
			#spawn_layer(-index)
		#else:
			#layer.show()
	#
	#layers_before.sort()
	#layers_before.reverse()
	#
	#curr_layers_range = layers_range
	#
	## Remove Other Layers
	#for layer: Layer in layers_container.get_children():
		#var index: int = -layer.index
		#if index not in curr_layers_range:
			#if layer.force_existing:
				#layer.hide()
				#continue
			#clips_selection_box.select_from.erase(layer)
			#layer.queue_free()
	#
	## Fix Arrangement
	#var sorted_layers: Array[Node] = layers_container.get_children()
	#sorted_layers.sort_custom(func(a, b): return a.index > b.index)
	#for i in range(sorted_layers.size()):
		#layers_container.move_child(sorted_layers[i], i)
	#
	#if delay_to_update_pos: await get_tree().process_frame
	#layers_container.position.y = int(-displacement_pos.y) % int(layer_display_size) - layer_display_size

func loop_layers(method: Callable) -> void:
	for index: int in curr_layers.keys():
		var layer: Layer = curr_layers[index]
		method.call(layer)

func spawn_layer(index: int, is_root_layer: bool) -> Layer:
	var layer: Layer
	if curr_layers.has(index):
		layer = curr_layers[index]
	else:
		layer = IS.create_layer(index, is_root_layer, editor_settings.layer_size, layer_side_panel_x_size, color_layer)
		layers_container.add_child(layer)
		clips_selection_box.select_from.append(layer.clips_control)
		curr_layers[index] = layer
	return layer

func spawn_layers(indeces: PackedInt32Array) -> void:
	var root_layers: bool = ProjectServer.curr_layers_path.size() == 0
	for index: int in indeces: spawn_layer(index, root_layers)
	arrange_layers()
	await get_tree().process_frame
	layers_scroll_container.scroll_vertical = layers_container.size.y

func free_layer() -> void:
	var max_layer_index: int = curr_layers.keys().max()
	curr_layers[max_layer_index].queue_free()
	curr_layers.erase(max_layer_index)

func free_layers(layers_count: int) -> void:
	for time: int in layers_count:
		free_layer()
	arrange_layers()

func arrange_layers() -> void:
	curr_layers.sort()
	var layers_count: int = curr_layers.size()
	for layer_index: int in curr_layers.keys():
		var layer: Layer = curr_layers[layer_index]
		layers_container.move_child(layer, layers_count - layer_index - 1)

func get_layer(index: int) -> Layer:
	return curr_layers.get(index)

func get_layer_by_filter(filter_function: Callable) -> Layer:
	for layer: Layer in layers_container.get_children():
		var result = filter_function.call(layer)
		if result: return layer
	return null

func get_layer_by_pos(pos: Vector2) -> Layer:
	return get_layer_by_filter(
		func(layer: Layer) -> bool:
			return layer.get_global_rect().has_point(pos)
	)

func clear_layers_drawn_entities(layers: Array = []) -> void:
	for layer: Layer in layers_container.get_children():
		var index: int = layer.index
		if not layers or index in layers:
			layer.clear_drawn_entities()

func set_layers_clips_modulate_transparent() -> void:
	loop_layers(func(layer: Layer) -> void: layer.set_clips_modulate_transparent())

func set_layers_clips_modulate_white() -> void:
	loop_layers(func(layer: Layer) -> void: layer.set_clips_modulate_white())


# Timemarker Functions
# ---------------------------------------------------

func start_timemarkers() -> void:
	timemarkers_parent = IS.create_empty_control()
	timemarkers_parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(timemarkers_parent)

func update_timemarkers() -> void:
	var timemarkers_ress = ProjectServer.time_markers
	
	var removed_markers_frames: Array[int]
	
	for frame_in: int in timemarkers_nodes.keys():
		if not timemarkers_ress.has(frame_in):
			var node = timemarkers_nodes[frame_in]
			if is_instance_valid(node):
				node.queue_free()
			removed_markers_frames.append(frame_in)
	
	for frame: int in removed_markers_frames:
		timemarkers_nodes.erase(frame)
	
	for frame_in: int in timemarkers_ress.keys():
		var res = timemarkers_ress.get(frame_in)
		
		var node: TimeMarker
		var create_new_node: bool = true
		
		if timemarkers_nodes.has(frame_in):
			node = timemarkers_nodes[frame_in]
			create_new_node = false
			if node.time_marker_res != res:
				node.queue_free()
				create_new_node = true
		
		if create_new_node:
			node = TimeMarker.new()
			node.selection_group = EditorServer.time_markers_selection_group
			node.time_marker_res = res
			node.time_marker_pos = frame_in
			node.position.y = header_size
			node.custom_minimum_size = Vector2(12, 12)
			timemarkers_parent.add_child(node)
			timemarkers_nodes[frame_in] = node
		
		node.position.x = get_display_pos_from_frame(frame_in)

#func get_timemarks_bg_mouse_entered() -> bool:
	#return timemarks_bg_mouse_entered

# ---------------------------------------------------

func get_frame_from_display_pos(pos: float, media_cannot_snap: Array = [], cursor_can_snap: bool = true, timemarks_can_snap: bool = true, snap_pos_can_change: bool = true) -> Dictionary[int, Variant]:
	
	var target_pos: int = int((pos - global_position.x) * display_snap_step / display_snap_dist + displacement_pos.x * display_snap_step)
	var snap_dist: Variant = null
	snap_pos = null
	
	if KEY_CTRL in pressed_keys:
		
		var snappable_frames: Dictionary[int, int] # kes is target-pos and value is dist-to-pos
		
		if is_magnet_to_media_clips:
			var layers: Dictionary[int, Dictionary] = ProjectServer.curr_layers
			
			for layer: int in layers:
				
				var media_clips: Dictionary = layers[layer].media_clips
				for frame_in: int in media_clips:
					var media_res: MediaClipRes = media_clips[frame_in]
					if media_res in media_cannot_snap:
						continue
					var length: int = media_res.length
					var frame_out: int = frame_in + length
					var dist_to_frame_in: int = abs(frame_in - target_pos)
					var dist_to_frame_out: int = abs(frame_out - target_pos)
					if dist_to_frame_in < 10: snappable_frames[dist_to_frame_in] = frame_in
					if dist_to_frame_out < 10: snappable_frames[dist_to_frame_out] = frame_out
		
		if is_snap_to_timemarkers_and_cursor:
			for frame_in: int in ProjectServer.time_markers:
				var dist_to_timemarker: int = abs(frame_in - target_pos)
				if dist_to_timemarker < 10:
					snappable_frames[dist_to_timemarker] = frame_in
			
			if cursor_can_snap:
				var dist_to_curr_frame: int = abs(curr_frame - target_pos)
				if dist_to_curr_frame < 10:
					snappable_frames[dist_to_curr_frame] = curr_frame
		
		var _snap_dist: Variant = snappable_frames.keys().min()
		if _snap_dist == null:
			if is_snap_to_timemarks and timemarks_can_snap:
				target_pos = snapped(target_pos, display_snap_step)
		else:
			target_pos = snappable_frames[_snap_dist]
			snap_dist = _snap_dist
			if snap_pos_can_change:
				snap_pos = target_pos
	
	return {target_pos: snap_dist}

func get_display_pos_from_frame(frame: int, display_node: Control = self) -> float:
	var target_pos = frame * display_frame_size - displacement_pos.x * display_snap_dist
	target_pos -= display_node.global_position.x - global_position.x
	return target_pos

func get_frame_from_mouse_pos(media_cannot_snap: Array = []) -> int:
	return get_frame_from_display_pos(get_global_mouse_position().x, media_cannot_snap).keys()[0]

func get_display_pos_from_mouse_pos(display_node: Control = self) -> int:
	return get_display_pos_from_frame(get_frame_from_mouse_pos(), display_node)


func get_next_spacial_frame(from_frame = null, is_previous: bool = false) -> int:
	
	var frame_poss: Array[int] = ProjectServer.curr_spacial_frames
	
	if from_frame == null:
		from_frame = curr_frame
	
	var left_poss: Dictionary[int, int]
	var right_poss: Dictionary[int, int]
	
	for pos: int in frame_poss:
		var pos_dist: int = pos - from_frame
		if pos_dist == 0:
			continue
		var abs_pos_dist: int = abs(pos_dist)
		
		if sign(pos_dist) == 1:
			right_poss[abs_pos_dist] = pos
		else:
			left_poss[abs_pos_dist] = pos
	
	var result_pos: int
	
	var search_func: Callable = func(poss_lib: Dictionary[int, int]) -> int:
		var closest_dist: Variant = poss_lib.keys().min()
		if closest_dist == null:
			return from_frame
		return poss_lib.get(closest_dist)
	
	if is_previous: result_pos = search_func.call(left_poss)
	else: result_pos = search_func.call(right_poss)
	
	return result_pos



# ---------------------------------------------------


func play(frame: Variant = null) -> void:
	EditorServer.player.play_button.button_pressed = true
	var start_and_end: Array[int] = ProjectServer.get_start_and_end_frame()
	var curr_time: float = Time.get_ticks_msec() / 1_000.0
	
	curr_frame = clamp(curr_frame if frame == null else frame, start_and_end[0], start_and_end[1])
	start_time = curr_time - curr_frame * ProjectServer.delta
	
	is_playing = true
	timeline_played.emit()

func stop() -> void:
	EditorServer.player.play_button.button_pressed = false
	is_playing = false
	timeline_stoped.emit()

func step_frame() -> void:
	
	curr_frame_changed_automatically.emit(curr_frame)
	
	var target_time: float = start_time + curr_frame * ProjectServer.delta
	var curr_time: float = Time.get_ticks_msec() / 1_000.0
	var delay: float = target_time - curr_time
	
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	var start_and_end: Array[int] = ProjectServer.get_start_and_end_frame()
	if curr_frame >= start_and_end[1]:
		if EditorServer.editor_settings.is_replay:
			play(start_and_end[0])
		else:
			stop()
		return
	
	curr_frame += 1
	
	if is_playing: step_frame()


# ---------------------------------------------------

func popup_media_clips_menu() -> void:
	IS.popup_menu([
		MenuOption.new("Cut", null, copy_media_clips.bind(true)),
		MenuOption.new("Copy", null, copy_media_clips.bind(false)),
		MenuOption.new("Duplicate", null, duplicate_media_clips),
		MenuOption.new("Delete", null, remove_media_clips),
		MenuOption.new("Split", null, split_media_clips.bind(true, true)),
		MenuOption.new_line(),
		MenuOption.new("Group", null, group_media_clips),
		MenuOption.new("UnGroup", null, ungroup_media_clips),
		MenuOption.new_line(),
		MenuOption.new("Enter", null, enter_media_clip),
		MenuOption.new("Create Parent", null, create_media_clips_parent),
		MenuOption.new("Reparent", null, reparent_media_clips),
		MenuOption.new("Parent Up", null, parent_up),
		MenuOption.new("Clear Parents", null, clear_parents),
		MenuOption.new_line(),
		MenuOption.new("Replace Media", null, replace_media_clips),
		MenuOption.new("Reverse Clip", null, reverse_media_clips),
		MenuOption.new("Extract Audio", null, extract_audio),
		MenuOption.new_line(),
		MenuOption.new("Open Graph Editor", null, open_graph_editor),
		MenuOption.new("Close Graph Editor", null, close_graph_editor),
		MenuOption.new_line(),
		MenuOption.new("Render Clip/s", null, render_media_clips),
		MenuOption.new("Save Clip/s as", null, save_media_clips_as),
		MenuOption.new("Save as Global Preset", null, save_as_global_preset),
		MenuOption.new("Save as Project Preset", null, save_as_project_preset)
	])


func select_all_media_clips() -> void:
	loop_layers(
		func(layer: Layer) -> void:
			layer.displayed_media_clips_select_all()
	)
	media_clips_selection_group.selected_objects_changed.emit()

func deselect_all_media_clips() -> void:
	media_clips_selection_group.clear_objects()

func copy_media_clips(cut: bool) -> void:
	ProjectServer.copy_media_clips(get_selected_clips_meta(), cut)

func past_media_clips() -> void:
	ProjectServer.past_media_clips([curr_frame])

func duplicate_media_clips() -> void:
	ProjectServer.duplicate_media_clips(get_selected_clips_meta(), curr_frame)

func remove_media_clips() -> void:
	ProjectServer.remove_media_clips(get_selected_clips_meta())
	media_clips_selection_group.clear_objects()

func split_media_clips(right_side: bool, left_side: bool) -> void:
	loop_selected_media_clips({}, func(media_clip: MediaClip, info: Dictionary[StringName, Variant]) -> void:
		media_clip.split(right_side, left_side)
	)

func group_media_clips() -> void:
	pass

func ungroup_media_clips() -> void:
	pass

func enter_media_clip() -> void:
	var focused_object: Dictionary = media_clips_selection_group.get_focused()
	if focused_object:
		var metadata: Dictionary = focused_object.metadata
		ProjectServer.enter_media_clip_children(metadata.layer_index, metadata.clip_pos)

func create_media_clips_parent() -> void:
	ProjectServer.create_media_clips_parent(media_clips_selection_group.get_focused().metadata, get_selected_clips_meta())

func reparent_media_clips() -> void:
	ProjectServer.reparent_media_clips(media_clips_selection_group.get_focused().metadata, get_selected_clips_meta())

func parent_up() -> void:
	ProjectServer.parent_up_media_clips(get_selected_clips_meta())

func clear_parents() -> void:
	ProjectServer.clear_media_clips_parents(get_selected_clips_meta())


func replace_media_clips() -> void:
	pass

func reverse_media_clips() -> void:
	pass

func extract_audio() -> void:
	pass

func open_graph_editor() -> void:
	loop_selected_media_clips({},
		func(media_clip: MediaClip, info: Dictionary[StringName, Variant]) -> void:
			media_clip.open_graph_editor(), Callable(), true
	)

func close_graph_editor() -> void:
	loop_selected_media_clips({},
		func(media_clip: MediaClip, info: Dictionary[StringName, Variant]) -> void:
			media_clip.close_graph_editors(), Callable(), true
	)

func render_media_clips() -> void:
	pass

func save_media_clips_as() -> void:
	pass

func save_as_global_preset() -> void:
	pass

func save_as_project_preset() -> void:
	pass


func loop_selected_media_clips(info: Dictionary[StringName, Variant], instance_valid_method: Callable, else_method: Callable = Callable(), update_media_clips_layers: bool = false) -> void:
	var selected_objects: Dictionary[String, Dictionary] = get_selected_clips()
	var updatable_layers: Array[Layer]
	
	for key: String in selected_objects.keys():
		var media_clip: Variant = selected_objects[key].object
		if media_clip:
			if is_instance_valid(media_clip):
				instance_valid_method.call(media_clip, info)
			elif else_method.is_valid(): else_method.call(info)
			
			if update_media_clips_layers:
				var layer: Layer = media_clip.layer
				if not updatable_layers.has(layer):
					updatable_layers.append(layer)
	
	await get_tree().process_frame
	for layer: Layer in updatable_layers: layer.update()
	#update_layers()


func get_selected_clips() -> Dictionary[String, Dictionary]:
	return media_clips_selection_group.selected_objects

func get_selected_clips_meta() -> Array[Dictionary]:
	return media_clips_selection_group.get_selected_meta()


# ---------------------------------------------------

enum ClipsMoveMode {
	MOVE_ADD,
	MOVE_EDIT
}
var clips_move_mode: ClipsMoveMode = 0
var clips_moved_objects: Array[Dictionary]
var clips_moved_object: Dictionary

var clips_moved_clips_ress: Array
var clips_moved_target_layer_index: int
var clips_moved_target_frame_index: int
var clips_moved_target_layers_indeces: Array
var clips_moved_target_frames_indeces: Array

var clips_moved_get_target_func: Callable

# the clip_info as Dictionary has 3 arguments
func clips_start_move(_clips_move_mode: ClipsMoveMode, _clips_moved_objects: Array[Dictionary], _clips_moved_object: Dictionary = {}) -> void:
	clips_move_mode = _clips_move_mode
	clips_moved_objects = _clips_moved_objects
	clips_moved_object = _clips_moved_object
	
	match clips_move_mode:
		0:
			clips_moved_get_target_func = func(object_index: int, info: Dictionary, mouse_pos: Vector2,
			main_layer_index: int, layer_delta: int, frame_delta: int) -> Array[int]:
				var metadata: Dictionary = info.metadata
				var key_as_path: StringName = metadata.path if metadata.has(&"path") else &""
				
				var layer_index: int = main_layer_index + object_index
				var frame: int = get_frame_from_display_pos(mouse_pos.x).keys()[0]
				var length: int = int(MediaServer.get_media_default_length(metadata.type, key_as_path) * ProjectServer.fps)
				return [layer_index, frame, length]
		1:
			clips_moved_get_target_func = func(object_index: int, info: Dictionary, mouse_pos: Vector2,
			main_layer_index: int, layer_delta: int, frame_delta: int) -> Array[int]:
				var media_clip: MediaClip = info.object
				var layer_index: int = media_clip.layer_index + layer_delta
				var frame: int = media_clip.clip_pos + frame_delta
				var length: int = media_clip.clip_res.length
				return [layer_index, frame, length]
			
			clips_moved_clips_ress = _clips_moved_objects.map(
			func(element: Dictionary) -> MediaClipRes:
				return element.metadata.clip_res
			)
	
	set_timeline_state(1)
	
	set_layers_clips_modulate_transparent()

func clips_moved() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dragged_object: FocusControl = clips_moved_object.object
	var main_layer: Layer = get_layer_by_pos(mouse_pos)
	var drawable_rect: DrawableRect = EditorServer.drawable_rect
	clear_layers_drawn_entities()
	drawable_rect.clear_drawn_entities()
	
	clips_moved_target_layers_indeces.clear()
	clips_moved_target_frames_indeces.clear()
	
	if is_focus and main_layer:
		
		var layer_delta: int
		var frame_delta: int
		
		clips_moved_target_layer_index = main_layer.index
		
		var begin_pos: float = (mouse_pos - dragged_object.start_drag_dist).x
		var frame_begin_result: Dictionary[int, Variant] = get_frame_from_display_pos(begin_pos, clips_moved_clips_ress, true, true, false)
		
		if clips_move_mode == 1:
			
			var frame_end_result: Dictionary[int, Variant] = get_frame_from_display_pos(begin_pos + dragged_object.size.x, clips_moved_clips_ress, true, true, false)
			var begin_snap_dist: Variant = frame_begin_result.values()[0]
			var end_snap_dist: Variant = frame_end_result.values()[0]
			
			if begin_snap_dist or end_snap_dist == null:
				var begin_frame = frame_begin_result.keys()[0]
				clips_moved_target_frame_index = begin_frame
				set_snap_pos(begin_frame if begin_snap_dist != null else null)
			
			elif end_snap_dist or begin_snap_dist == null:
				var end_frame = frame_end_result.keys()[0]
				clips_moved_target_frame_index = end_frame - dragged_object.clip_res.length
				set_snap_pos(end_frame if end_snap_dist != null else null)
			
			layer_delta = clips_moved_target_layer_index - dragged_object.layer_index
			frame_delta = clips_moved_target_frame_index - dragged_object.clip_pos
		
		for index: int in clips_moved_objects.size():
			var info: Dictionary = clips_moved_objects[index]
			var targets: Array[int] = clips_moved_get_target_func.call(index, info, mouse_pos, clips_moved_target_layer_index, layer_delta, frame_delta)
			
			var target_layer_index: int = targets[0]
			var target_frame: int = targets[1]
			var target_length: float = targets[2]
			
			var target_layer: Layer = get_layer(target_layer_index)
			
			clips_moved_target_layers_indeces.append(target_layer_index)
			clips_moved_target_frames_indeces.append(target_frame)
			if target_layer == null:
				continue
			
			var rect_x_pos: float = get_display_pos_from_frame(target_frame, target_layer)
			var rect_x_size: float = target_length * display_frame_size
			var rect2: Rect2 = Rect2(Vector2(rect_x_pos, .0), Vector2(rect_x_size, target_layer.size.y))
			
			#var is_layer_unoccupied : bool = ProjectServer.is_layer_unoccupied(target_layer_index, target_frame, target_length)
			#var custom_color: Color = IS.COLOR_ACCENT_BLUE if is_layer_unoccupied else IS.COLOR_WARNING_YELLOW
			target_layer.draw_new_theme_rect(rect2, IS.COLOR_ACCENT_BLUE)
		
		#var frame_string: String = str(frame_begin_result.keys()[0], "f")
		#drawable_rect.draw_new_rect(Rect2(mouse_pos + Vector2(-5, 3), Vector2(5 + frame_string.length() * 10.0, -18.0)), Color.BLACK)
		#drawable_rect.draw_new_string(font_main, mouse_pos, frame_string)
	
	elif clips_move_mode == 0:
		var _size: Vector2 = clips_moved_objects[0].object.size
		var center_pos: Vector2 = mouse_pos - _size / 2.0
		for index: int in min(5, clips_moved_objects.size()):
			var info: Dictionary = clips_moved_objects[index]
			var offset: float = index * 24.0
			var rect2: Rect2 = Rect2(center_pos + Vector2(offset, offset), _size)
			drawable_rect.draw_new_theme_rect(rect2)

func clips_end_move() -> void:
	
	if clips_moved_target_layers_indeces.size():
		
		match clips_move_mode:
			0:
				for index: int in clips_moved_objects.size():
					var info: Dictionary = clips_moved_objects[index]
					var media_card: MediaExplorer.MediaCard = info.object
					media_card.add_media(
						clips_moved_target_layers_indeces[index],
						get_frame_from_display_pos(get_global_mouse_position().x).keys()[0]
					)
				ProjectServer.emit_media_clips_change()
			1:
				var clips_info: Array[Dictionary]
				
				for info: Dictionary in clips_moved_objects:
					clips_info.append(info.metadata)
				
				ProjectServer.move_media_clips(
					clips_info,
					clips_moved_target_layers_indeces,
					clips_moved_target_frames_indeces
				)
		
		media_clips_selection_group.set_default_focused()
		media_clips_selection_group.selected_objects_changed.emit()
	
	clips_moved_clips_ress.clear()
	
	set_timeline_state(0)
	
	await get_tree().process_frame
	clear_layers_drawn_entities()
	EditorServer.drawable_rect.clear_drawn_entities()
	set_layers_clips_modulate_white()

func drag(delta: float, horizontally: bool = true, vertically: bool = true) -> void:
	var mouse_pos: Vector2 = get_local_mouse_position()
	
	if mouse_pos.y >= .0 and mouse_pos.y < position.y + size.y:
		
		var speed: float = 8.0
		var half_size: Vector2 = size / 2.0
		var min_dist: Vector2 = half_size - Vector2(100, 100)
		var dist: Vector2 = mouse_pos - half_size
		var move_scale: Vector2 = (dist - sign(dist) * min_dist) * speed * delta
		
		if horizontally and abs(dist.x) > min_dist.x:
			displacement_pos.x += move_scale.x / display_snap_dist
		if vertically and abs(dist.y) > min_dist.y:
			layers_scroll_container.scroll_vertical += move_scale.y


# ---------------------------------------------------

#func update_timeline_selection_mode(index: int = -1) -> void:
	#var options: Array = get_selection_mode_menu_options()
	#var save_path: String = get_selection_mode_save_path()
	#var group_res: Resource = ResourceLoader.load(save_path)
	#if index == -1:
		#index = group_res.checked_index
	#if index >= options.size():
		#index = 0
	#
	#var menu_option: MenuOption = options[index]
	#timeline_selection_mode = index
	#selection_mode_button.text = menu_option.text
	#selection_mode_button.icon = menu_option.icon
	#
	#group_res.checked_index = index
	#ResourceSaver.save(group_res, save_path)

#func get_selection_mode_menu_options() -> Array:
	#return MenuOption.new_options_with_check_group(
		#[
			#{text = "Select Mode", icon = texture_select_mode},
			#{text = "Split Mode", icon = texture_split_mode}
		#], get_selection_mode_save_path()
	#)
#
#func get_selection_mode_save_path() -> String:
	#return EditorServer.editor_path + "timeline_selection_mode.tres"


# Connections Functions
# ---------------------------------------------------

func on_project_server_media_clip_entered(clip_res_to: MediaClipRes) -> void:
	pass

func on_project_server_media_clip_exited(clip_res_from: MediaClipRes, times: int) -> void:
	pass

func on_project_server_layer_added(index: int) -> void:
	spawn_layer(index, ProjectServer.curr_layers_path.size() == 0)
	arrange_layers()

func on_project_server_layer_removed() -> void:
	free_layer()

func on_project_server_layers_added(indeces: PackedInt32Array) -> void:
	spawn_layers(indeces)

func on_project_server_layers_removed(layers_count: int) -> void:
	free_layers(layers_count)

func on_project_server_layer_property_changed(index: int) -> void:
	var layer: Layer = get_layer(index)
	layer.queue_redraw()

func on_project_server_timemarkers_changed() -> void:
	update_timemarkers()

func on_project_server_curr_layers_changed() -> void:
	var curr_layers_string_path: Array[String] = ProjectServer.curr_layers_string_path
	var backend_curr_layers: Dictionary[int, Dictionary] = ProjectServer.curr_layers
	
	path_controller.update(curr_layers_string_path)
	for layer: Layer in curr_layers.values():
		layer.queue_free()
	curr_layers.clear()
	
	if backend_curr_layers.size():
		var layers_indeces: Array = backend_curr_layers.keys()
		spawn_layers(layers_indeces)
	else: ProjectServer.make_layers_absolute(PackedInt32Array(range(default_layers_count)))
	
	queue_redraw()
	 
	media_clips_selection_group.clear_objects()

func on_player_curr_frame_changed(new_frame: int) -> void:
	emit_frame_changed = false
	set_curr_frame_manually(new_frame)
	emit_frame_changed = true

# ---------------------------------------------------

func on_media_clips_selection_group_changed() -> void:
	#media_clips_selection_group.loop_selected_objects(
		#func(media_clip: MediaClip, metadata: Dictionary) -> void:
			#media_clip.focus_panel.update_displayed_keys()
	#)
	ProjectServer.update_curr_length_and_curr_spacial_frames()

func on_resized() -> void:
	calculate_select_rect()
	update_timemarkers()

func on_l_button_downed(pos: Vector2) -> void:
	if pos.y - global_position.y <= header_size + timemarks_bg_size:
		set_curr_frame_manually(get_frame_from_display_pos(pos.x, [], false).keys()[0])
		timeline_state = 2
		curr_frame_played_manually.emit()

func on_l_button_upped(pos: Vector2) -> void:
	if timeline_state == 2:
		timeline_state = 0
		curr_frame_stopped_manually.emit()


func on_key_right_pressed() -> void:
	set_curr_frame_manually(get_next_spacial_frame() if KEY_CTRL in pressed_keys else curr_frame + 1)

func on_key_left_pressed() -> void:
	set_curr_frame_manually(get_next_spacial_frame(null, true) if KEY_CTRL in pressed_keys else curr_frame - 1)

func on_clips_selection_box_selection_ended(grouping: bool, remove: bool) -> void:
	var selection_group_res: SelectionGroupRes = EditorServer.media_clips_selection_group
	var selected_nodes: Dictionary[String, Control] = clips_selection_box.selected_nodes
	
	if remove:
		selection_group_res.remove_objects(selected_nodes, true)
		return
	elif not grouping:
		selection_group_res.clear_objects({}, false)
	
	selection_group_res.add_objects(selected_nodes, ["layer_index", "clip_pos", "clip_res"])

func on_selection_mode_button_selected_option_changed(id: int, option: MenuOption) -> void:
	timeline_selection_mode = id

func on_edit_mode_button_selected_option_changed(id: int, option: MenuOption) -> void:
	timeline_edit_mode = id

func on_split_button_pressed() -> void:
	split_media_clips(true, true)

func on_split_left_button_pressed() -> void:
	split_media_clips(false, true)

func on_split_right_button_pressed() -> void:
	split_media_clips(true, false)

func on_marker_button_pressed() -> void:
	ProjectServer.add_time_marker(curr_frame)

func on_path_controller_undo_requested(undo_times: int) -> void:
	ProjectServer.exit_media_clip_children(undo_times)

func on_snap_cursor_button_pressed() -> void:
	is_snap_to_timemarkers_and_cursor = not is_snap_to_timemarkers_and_cursor

func on_snap_markers_button_pressed() -> void:
	is_snap_to_timemarks = not is_snap_to_timemarks

func on_magnet_clips_button_pressed() -> void:
	is_magnet_to_media_clips = not is_magnet_to_media_clips

func on_clips_overlay_menu_focus_index_changed(index: int) -> void:
	media_clip_place_method = index as MediaClipPlaceMethod

#func on_zoom_slider_val_changed(new_val: float) -> void:
	#zoom = new_val
