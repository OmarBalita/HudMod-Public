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
	SELECT,
	SPLIT
}

enum TimelineStates {
	IDLE,
	DRAG,
	DRAG_CURSOR,
	EXPAND_MEDIA_CLIP,
}


@export_group("Properties")

@export var timeline_selection_mode: TimelineSelectionModes:
	set(val):
		timeline_selection_mode = val
		match val:
			0:
				mouse_default_cursor_shape = Control.CURSOR_ARROW
				splited_media_clip = null
			1:
				mouse_default_cursor_shape = Control.CURSOR_IBEAM
		update_selection_box_enabling()

@export var timeline_state: TimelineStates = 0:
	set(val):
		timeline_state = val
		shortcut_node.enabled = val == 0
		update_selection_box_enabling()

@export var is_snap_to_timemarks: bool = true
@export var is_snap_to_timemarkers_and_cursor: bool = true
@export var is_magnet_to_media_clips: bool = true

@export_subgroup("Zoom")
@export var zoom: float = 100.0:
	set(val):
		zoom = clamp(val, min_zoom, max_zoom)
		queue_redraw()

@export_range(.01, 10.0, .01) var zoom_step: float = .05
@export_range(1.0, 1000.0) var min_zoom: float = 1.0
@export_range(1.0, 10000.0) var max_zoom: float = 5000.0

@export_group("Layers")
@export_range(1, 100) var layer_display_size: float = 80.0:
	set(val):
		layer_display_size = val
		queue_redraw()

@export_group("Theme")
@export_subgroup("Texture", "texture")
@export var texture_select_mode: Texture2D
@export var texture_split_mode: Texture2D
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

#const RESULT_STEPS = [1, 2, 3, 6, 9, 15, 30, 60, 90, 120, 300, 900, 1800, 3600, 7200, 14400, 21600, 28800]



# RealTime Variables
# ---------------------------------------------------

var is_playing: bool:
	set(val):
		is_playing = val
		if is_playing:
			step_frame()

var start_time = 0.0

var curr_frame: int:
	set(val):
		curr_frame = val
		curr_frame_changed.emit(curr_frame)
		ProjectServer.update_scene_nodes()
		queue_redraw()

var snap_pos:
	set(val):
		snap_pos = val
		queue_redraw()

var displacement_pos: Vector2:
	set(val):
		displacement_pos = val
		queue_redraw()

var curr_layers_range: Array

var display_snap_dist: float
var display_snap_step: int
var display_frame_size: float
var display_cursor_pos: int


# RealTime Nodes

var layers_container: BoxContainer
var clips_selection_box: SelectionBox
var timemarkers_parent: Control
var timemarkers_nodes: Dictionary[int, TimeMarker]

var splited_media_clip: MediaClip

var selection_mode_button: Button




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
	editor_guides = [
		{"Move Cursor": "[Mouse-Left]"},
		{"Move TimeLine": "[Mouse-Right]"},
		{"Move Layers": "[Mouse-Right] + [Shift]"}
	]


func _start() -> void:
	super()
	
	# Start ShortCuts
	shortcut_node.create_key_shortcut(CTRL_MASK, KEY_X, copy_media_clips.bind(true))
	shortcut_node.create_key_shortcut(CTRL_MASK, KEY_C, copy_media_clips.bind(false))
	shortcut_node.create_key_shortcut(CTRL_MASK, KEY_V, past_media_clips)
	shortcut_node.create_key_shortcut(CTRL_MASK, KEY_D, duplicate_media_clips)
	shortcut_node.create_key_shortcut(0, KEY_DELETE, remove_media_clips)
	shortcut_node.create_key_shortcut(0, KEY_X, split_media_clips.bind(true, true))
	shortcut_node.create_key_shortcut(0, KEY_C, split_media_clips.bind(true, false))
	shortcut_node.create_key_shortcut(0, KEY_Z, split_media_clips.bind(false, true))
	shortcut_node.create_key_shortcut(0, KEY_TAB, func(): update_timeline_selection_mode(timeline_selection_mode + 1))
	
	# Start Connections
	ProjectServer.time_markers_changed.connect(on_project_server_timemarkers_changed)
	
	l_button_downed.connect(on_l_button_downed)
	l_button_upped.connect(on_l_button_upped)
	wheel_downed.connect(on_wheel_downed)
	wheel_upped.connect(on_wheel_upped)
	
	just_press_functions = {
		KEY_SPACE: func(): stop() if is_playing else play()
	}
	press_functions = {
		KEY_LEFT: on_key_left_pressed,
		KEY_RIGHT: on_key_right_pressed,
	}
	
	# Start Layers
	start_layers()
	start_selection_box()
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


func _input(event: InputEvent) -> void:
	super(event)
	
	if timeline_state == 1:
		return
	
	if event is InputEventMouseMotion:
		if r_button_down:
			displacement_pos -= Vector2(
				event.relative.x / display_snap_dist,
				event.relative.y * float(KEY_SHIFT in pressed_keys)
			)
		elif timeline_selection_mode == TimelineSelectionModes.SPLIT:
			var media_clips_focused = EditorServer.media_clips_focused
			if media_clips_focused.size():
				splited_media_clip = media_clips_focused[0]
			else:
				splited_media_clip = null
			queue_redraw()
	
	elif event is InputEventMouseButton:
		if event.is_released():
			if splited_media_clip:
				splited_media_clip.split(true, true, get_frame_from_mouse_pos())
			else:
				snap_pos = null


func _draw() -> void:
	
	# Limit Y Displacement Position
	var pos_0 = layer_display_size * 2.0
	displacement_pos.y = clamp(displacement_pos.y, -INF, -size.y + layer_display_size * 2.0)
	
	# Draw TimeMarkers
	draw_rect(
		Rect2(Vector2(.0, header_size), Vector2(size.x, timemarks_bg_size)),
		color_timemarks_bg
	)
	
	var curr_timemarks_between = .0
	var raw_interval = timemarks_between / zoom
	var steps = .1
	while not curr_timemarks_between:
		if raw_interval > steps:
			steps *= 2.0
			continue
		curr_timemarks_between = steps
	
	var timemarks_count = size.x / (curr_timemarks_between * zoom)
	display_snap_dist = size.x / timemarks_count
	
	var raw_step = int(max_zoom / zoom * steps)
	display_snap_step = max(1, raw_step)
	display_frame_size = display_snap_dist / display_snap_step
	
	var min_diff = INF
	
	#for step in RESULT_STEPS:
		#var diff = abs(step - raw_step)
		#if diff < min_diff:
			#min_diff = diff
			#display_snap_step = step
	
	for i in range(displacement_pos.x, displacement_pos.x + timemarks_count):
		var curr_frame = i * display_snap_step
		var is_marked = i == snapped(i, 6) or zoom >= max_zoom - 3000.0
		var x_pos = (i - displacement_pos.x) * display_snap_dist
		var from = Vector2(x_pos, header_size)
		var to = from + Vector2.DOWN * (5.0 + 20.0 * int(is_marked))
		draw_line(from, to, color_timemarks, 1.0 + int(is_marked))
		if is_marked:
			draw_string(font_main,
			to + Vector2.RIGHT * 10.0,
			str(curr_frame, "f") # if zoom >= 100.0 else frames_to_timecode(curr_frame, 30, true)
		)
	
	draw_line(Vector2(.0, header_size), Vector2(size.x, header_size), Color(Color.CORNFLOWER_BLUE, .7), 3.0)
	
	
	# Draw Cursor
	display_cursor_pos = get_display_pos_from_frame(curr_frame)
	var cursor_from = Vector2(display_cursor_pos, header_size)
	
	if display_cursor_pos > 310.0:
		draw_line(
			cursor_from,
			Vector2(display_cursor_pos, size.y),
			color_cursor.darkened(.4),
			cursor_width
		)
	draw_rect(
		Rect2(cursor_from, Vector2(12, timemarks_bg_size)),
		color_cursor
	)
	
	# Draw Snap Line
	if snap_pos != null:
		var display_snap_pos = get_display_pos_from_frame(snap_pos)
		var dist_between = 10
		for time in range(body.size.y / dist_between):
			var y_pos = time * dist_between
			draw_line(
				Vector2(display_snap_pos, y_pos),
				Vector2(display_snap_pos, y_pos + 5),
				Color.YELLOW_GREEN,
				2.0
			)
	
	# Draw Split Line on Top of Layer
	if splited_media_clip != null:
		var display_split_pos = get_display_frame_from_mouse_pos()
		var y_pos = splited_media_clip.global_position.y - global_position.y
		draw_line(
			Vector2(display_split_pos, y_pos),
			Vector2(display_split_pos, y_pos + splited_media_clip.size.y),
			Color.RED,
			2.0
		)
	
	super()
	
	# Update Layers When Rect Settings Changed
	update_layers()
	update_timemarkers()
	timeline_view_changed.emit()


# ---------------------------------------------------

func start_toolbar() -> void:
	
	var split_container = InterfaceServer.create_split_container()
	var toolbar_left_container = InterfaceServer.create_box_container(16, false, {alignment = BoxContainer.ALIGNMENT_BEGIN})
	var toolbar_right_container = InterfaceServer.create_box_container(16, false, {alignment = BoxContainer.ALIGNMENT_END})
	
	var splittool_panel = InterfaceServer.create_panel_container()
	var splittool_container = InterfaceServer.create_box_container()
	var splittool_margin = InterfaceServer.create_margin_container(4, 4, 4, 4)
	
	var snaptool_panel = InterfaceServer.create_panel_container()
	var snaptool_container = InterfaceServer.create_box_container()
	var snaptool_margin = InterfaceServer.create_margin_container(4, 4, 4, 4)
	
	selection_mode_button = InterfaceServer.create_button("Select Mode", texture_select_mode)
	var split_left_button = InterfaceServer.create_texture_button(texture_split_left)
	var split_button = InterfaceServer.create_texture_button(texture_split)
	var split_right_button = InterfaceServer.create_texture_button(texture_split_right)
	var marker_button = InterfaceServer.create_texture_button(texture_marker)
	
	var snap_markers_button = InterfaceServer.create_texture_button(texture_snap_markers, null, null, true, {button_pressed = is_snap_to_timemarks})
	var snap_cursor_button = InterfaceServer.create_texture_button(texture_snap_cursor, null, null, true, {button_pressed = is_snap_to_timemarkers_and_cursor})
	var magnet_clips_button = InterfaceServer.create_texture_button(texture_magnet_clips, null, null, true, {button_pressed = is_magnet_to_media_clips})
	var zoom_slider = InterfaceServer.create_slider_control(zoom, min_zoom, max_zoom, 500.0, texture_zoom_out, texture_zoom_in)
	
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
	toolbar_left_container.add_child(splittool_panel)
	toolbar_left_container.add_child(marker_button)
	
	toolbar_right_container.add_child(snaptool_panel)
	toolbar_right_container.add_child(zoom_slider)
	
	split_container.add_child(toolbar_left_container)
	split_container.add_child(toolbar_right_container)
	header.add_child(split_container)
	
	selection_mode_button.pressed.connect(on_selection_mode_button_pressed.bind(selection_mode_button))
	split_button.pressed.connect(on_split_button_pressed)
	split_left_button.pressed.connect(on_split_left_button_pressed)
	split_right_button.pressed.connect(on_split_right_button_pressed)
	marker_button.pressed.connect(on_marker_button_pressed)
	snap_markers_button.pressed.connect(on_snap_markers_button_pressed)
	snap_cursor_button.pressed.connect(on_snap_cursor_button_pressed)
	magnet_clips_button.pressed.connect(on_magnet_clips_button_pressed)
	zoom_slider.slider_controller.val_changed.connect(on_zoom_slider_val_changed)
	
	update_timeline_selection_mode()
	update_selection_box_enabling()


func start_selection_box() -> void:
	clips_selection_box = InterfaceServer.create_selection_box([])
	clips_selection_box.id_key_function_name = "get_id_key"
	body.add_child(clips_selection_box)
	clips_selection_box.selection_ended.connect(on_clips_selection_box_selection_ended)

func update_selection_box_enabling() -> void:
	if clips_selection_box:
		clips_selection_box.enabled = timeline_selection_mode == 0 and timeline_state == 0

func start_layers() -> void:
	layers_container = InterfaceServer.create_box_container(2, true, {"clip_contents": true})
	body.add_child(layers_container)

func update_layers() -> void:
	
	var layers_count = int(size.y / layer_display_size)
	var layers_displacement = int(displacement_pos.y / layer_display_size)
	var layers_range = range(layers_displacement, layers_displacement + layers_count + 1)
	
	# Spawn Remaining Layers
	var layers_before: Array[int]
	
	for index in layers_range:
		if index in curr_layers_range or index > 0:
			continue
		var layer = get_layer_from_index(-index)
		if layer == null:
			spawn_layer(-index)
		else:
			layer.show()
	
	layers_before.sort()
	layers_before.reverse()
	
	curr_layers_range = layers_range
	
	# Remove Other Layers
	for layer: Layer in layers_container.get_children():
		var index = -layer.index
		if index not in curr_layers_range:
			if layer.force_existing:
				layer.hide()
				continue
			clips_selection_box.select_from.erase(layer)
			layer.queue_free()
	
	# Fix Arrangement
	var sorted_layers: Array[Node] = layers_container.get_children()
	sorted_layers.sort_custom(func(a, b): return a.index > b.index)
	for i in range(sorted_layers.size()):
		layers_container.move_child(sorted_layers[i], i)
	
	await get_tree().process_frame
	layers_container.position.y = int(-displacement_pos.y) % int(layer_display_size) - layer_display_size


func spawn_layer(index: int) -> Layer:
	var layer = InterfaceServer.create_layer(index, Vector2(.0, layer_display_size), color_layer)
	layers_container.add_child(layer)
	clips_selection_box.select_from.append(layer.clips_control)
	return layer

func get_layer_by_filter(filter_function: Callable) -> Layer:
	for layer: Layer in layers_container.get_children():
		var result = filter_function.call(layer)
		if result:
			return layer
	return null

func get_layer_from_index(layer_index: int) -> Layer:
	return get_layer_by_filter(
		func(layer: Layer) -> bool:
			return layer.index == layer_index
	)

func get_layer_by_pos(pos: Vector2) -> Layer:
	return get_layer_by_filter(
		func(layer: Layer) -> bool:
			return layer.get_global_rect().has_point(pos)
	)

func clear_layers_drawed_entities(layers: Array = []) -> void:
	for layer: Layer in layers_container.get_children():
		var index = layer.index
		if not layers or index in layers:
			layer.clear_drawed_entities()



# Timemarker Functions
# ---------------------------------------------------

func start_timemarkers() -> void:
	timemarkers_parent = InterfaceServer.create_empty_control()
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
			node.time_marker_pos = frame_in
			node.time_marker_res = res
			node.position.y = header_size
			node.custom_minimum_size = Vector2(12, 12)
			timemarkers_parent.add_child(node)
			timemarkers_nodes[frame_in] = node
		
		node.position.x = get_display_pos_from_frame(frame_in)





# Connections Functions
# ---------------------------------------------------

func on_project_server_timemarkers_changed() -> void:
	update_timemarkers()

func on_l_button_downed(pos: Vector2) -> void:
	if pos.y < global_position.y + header_size + timemarks_bg_size:
		set_curr_frame_manually(get_frame_from_display_pos(pos.x, [], false).keys()[0])
		timeline_state = 2
		curr_frame_played_manually.emit()

func on_l_button_upped(pos: Vector2) -> void:
	if timeline_state == 2:
		timeline_state = 0
		curr_frame_stopped_manually.emit()

func on_wheel_downed(pos: Vector2) -> void:
	zoom -= zoom_step * zoom

func on_wheel_upped(pos: Vector2) -> void:
	zoom += zoom_step * zoom

func on_key_right_pressed() -> void:
	set_curr_frame_manually(get_next_spacial_frame() if KEY_CTRL in pressed_keys else curr_frame + 1)

func on_key_left_pressed() -> void:
	set_curr_frame_manually(get_next_spacial_frame(null, true) if KEY_CTRL in pressed_keys else curr_frame - 1)

func on_clips_selection_box_selection_ended(grouping: bool, remove: bool) -> void:
	var selection_group_res = EditorServer.media_clips_selection_group
	var selected_nodes = clips_selection_box.selected_nodes
	
	if remove:
		selection_group_res.remove_objects(selected_nodes)
		return
	
	elif not grouping:
		selection_group_res.clear_objects()
	selection_group_res.add_objects(selected_nodes, ["layer_index", "clip_pos", "clip_res"])

func on_selection_mode_button_pressed(selection_mode_button: BaseButton) -> void:
	var selection_mode_menu = InterfaceServer.create_popuped_menu(get_selection_mode_menu_options())
	
	selection_mode_menu.menu_button_pressed.connect(update_timeline_selection_mode)
	
	add_child(selection_mode_menu)
	selection_mode_menu.popup()

func on_split_button_pressed() -> void:
	split_media_clips(true, true)

func on_split_left_button_pressed() -> void:
	split_media_clips(false, true)

func on_split_right_button_pressed() -> void:
	split_media_clips(true, false)

func on_marker_button_pressed() -> void:
	ProjectServer.add_time_marker(curr_frame)

func on_snap_cursor_button_pressed() -> void:
	is_snap_to_timemarkers_and_cursor = not is_snap_to_timemarkers_and_cursor

func on_snap_markers_button_pressed() -> void:
	is_snap_to_timemarks = not is_snap_to_timemarks

func on_magnet_clips_button_pressed() -> void:
	is_magnet_to_media_clips = not is_magnet_to_media_clips

func on_zoom_slider_val_changed(new_val: float) -> void:
	zoom = new_val



# ---------------------------------------------------


func get_frame_from_display_pos(pos: float, media_cannot_snap: Array = [], cursor_can_snap: bool = true, timemarks_can_snap: bool = true, snap_pos_can_change: bool = true) -> Dictionary[int, Variant]:
	
	var target_pos = int((pos - global_position.x) * display_snap_step / display_snap_dist + displacement_pos.x * display_snap_step)
	var snap_dist = null
	snap_pos = null
	
	if KEY_CTRL in pressed_keys:
		
		var snappable_frames: Dictionary[int, int] # kes is target-pos and value is dist-to-pos
		
		if is_magnet_to_media_clips:
			var layers = ProjectServer.layers
			
			for layer in layers:
				
				var media_clips = layers[layer].media_clips
				for frame_in in media_clips:
					var media_res = media_clips[frame_in]
					if media_res in media_cannot_snap:
						continue
					var length = media_res.length
					var frame_out = frame_in + length
					var dist_to_frame_in = abs(frame_in - target_pos)
					var dist_to_frame_out = abs(frame_out - target_pos)
					if dist_to_frame_in < 10: snappable_frames[dist_to_frame_in] = frame_in
					if dist_to_frame_out < 10: snappable_frames[dist_to_frame_out] = frame_out
		
		if is_snap_to_timemarkers_and_cursor:
			for frame_in in ProjectServer.time_markers:
				var dist_to_timemarker = abs(frame_in - target_pos)
				if dist_to_timemarker < 10:
					snappable_frames[dist_to_timemarker] = frame_in
			
			if cursor_can_snap:
				var dist_to_curr_frame = abs(curr_frame - target_pos)
				if dist_to_curr_frame < 10:
					snappable_frames[dist_to_curr_frame] = curr_frame
		
		var _snap_dist = snappable_frames.keys().min()
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
	return EditorServer.time_line.get_frame_from_display_pos(get_global_mouse_position().x, media_cannot_snap).keys()[0]

func get_display_frame_from_mouse_pos(display_node: Control = self) -> int:
	return get_display_pos_from_frame(get_frame_from_mouse_pos(), display_node)


func get_next_spacial_frame(from_frame = null, is_previous: bool = false) -> int:
	
	var frame_poss = ProjectServer.time_markers.keys()
	var layers = ProjectServer.layers
	for layer in layers:
		frame_poss.append_array(layers[layer].media_clips.keys())
	
	if from_frame == null:
		from_frame = curr_frame
	
	var left_poss: Dictionary[int, int]
	var right_poss: Dictionary[int, int]
	
	for pos in frame_poss + [0]:
		var pos_dist = pos - from_frame
		if pos_dist == 0:
			continue
		var abs_pos_dist = abs(pos_dist)
		
		if sign(pos_dist) == 1:
			right_poss[abs_pos_dist] = pos
		else:
			left_poss[abs_pos_dist] = pos
	
	var result_pos: int
	
	var search_func = func(poss_lib: Dictionary[int, int]) -> int:
		var closest_dist = poss_lib.keys().min()
		if closest_dist == null:
			return from_frame
		return poss_lib.get(closest_dist)
	
	if is_previous:
		result_pos = search_func.call(left_poss)
	else:
		result_pos = search_func.call(right_poss)
	
	return result_pos



# ---------------------------------------------------


func play() -> void:
	var curr_time = Time.get_ticks_msec() / 1_000.0
	start_time = curr_time - curr_frame * ProjectServer.delta
	is_playing = true
	timeline_played.emit()

func stop() -> void:
	is_playing = false
	timeline_stoped.emit()

func step_frame() -> void:
	
	curr_frame_changed_automatically.emit(curr_frame)
	
	var target_time = start_time + curr_frame * ProjectServer.delta
	var curr_time = Time.get_ticks_msec() / 1_000.0
	var delay = target_time - curr_time
	
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	curr_frame += 1
	if is_playing: step_frame()




# ---------------------------------------------------


func copy_media_clips(cut: bool) -> void:
	ProjectServer.copy_media_clips(get_selected_clips(), cut)

func past_media_clips() -> void:
	ProjectServer.past_media_clips([curr_frame])

func duplicate_media_clips() -> void:
	ProjectServer.duplicate_media_clips(get_selected_clips(), curr_frame)

func remove_media_clips() -> void:
	ProjectServer.remove_media_clips(get_selected_clips())
	EditorServer.media_clips_selection_group.clear_objects()

func split_media_clips(right_side: bool, left_side: bool) -> void:
	var selected_objects = EditorServer.media_clips_selection_group.selected_objects
	for key in selected_objects:
		var object = selected_objects[key].object
		if is_instance_valid(object):
			object.split(right_side, left_side)

func get_selected_clips() -> Array[Dictionary]:
	return EditorServer.media_clips_selection_group.get_selected_meta()



# ---------------------------------------------------


func drag(delta: float, horizontally: bool = true, vertically: bool = true) -> void:
	var speed = 8.0
	
	var mouse_pos = get_local_mouse_position()
	var half_size = size / 2.0
	var min_dist = half_size - Vector2(100, 100)
	var dist = mouse_pos - half_size
	var move_scale = (dist - sign(dist) * min_dist) * speed * delta
	
	if horizontally and abs(dist.x) > min_dist.x:
		displacement_pos.x += move_scale.x / display_snap_dist
	if vertically and abs(dist.y) > min_dist.y:
		displacement_pos.y += move_scale.y


# ---------------------------------------------------


func update_timeline_selection_mode(index: int = -1) -> void:
	var options = get_selection_mode_menu_options()
	var save_path = get_selection_mode_save_path()
	var group_res = ResourceLoader.load(save_path)
	if index == -1:
		index = group_res.checked_index
	if index >= options.size():
		index = 0
	
	var menu_option = options[index]
	timeline_selection_mode = index
	selection_mode_button.text = menu_option.text
	selection_mode_button.icon = menu_option.icon
	
	group_res.checked_index = index
	ResourceSaver.save(group_res, save_path)


func get_selection_mode_menu_options() -> Array:
	return MenuOption.new_options_with_check_group(
		[
			{text = "Select Mode", icon = texture_select_mode},
			{text = "Split Mode", icon = texture_split_mode}
		], get_selection_mode_save_path()
	)

func get_selection_mode_save_path() -> String:
	return EditorServer.editor_path + "timeline_selection_mode.tres"





