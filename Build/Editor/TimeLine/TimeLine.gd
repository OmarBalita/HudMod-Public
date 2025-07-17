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

@export_group("Zoom")
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
@export var texture_selection: Texture2D
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



enum TimelineStates {
	IDLE,
	DRAG,
	DRAG_CURSOR,
	EXPAND_MEDIA_CLIP,
}

@export var timeline_state: TimelineStates = 0:
	set(val):
		timeline_state = val
		shortcut_node.enabled = val == 0



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
	
	# Start Connections
	l_button_downed.connect(on_l_button_downed)
	l_button_upped.connect(on_l_button_upped)
	wheel_downed.connect(on_wheel_downed)
	wheel_upped.connect(on_wheel_upped)
	
	just_press_functions = {
		KEY_SPACE: func(): stop() if is_playing else play()
	}
	press_functions = {
		KEY_LEFT: func(): set_curr_frame_manually(curr_frame - 1),
		KEY_RIGHT: func(): set_curr_frame_manually(curr_frame + 1),
	}
	
	# Start Layers
	start_toolbar()
	start_layers()
	start_selection_box()


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


func _draw() -> void:
	
	# Limit Y Displacement Position
	var zoom_ratio = zoom / 100.0
	var pos_0 = layer_display_size * 2.0
	displacement_pos.y = clamp(displacement_pos.y, -INF, -size.y + layer_display_size * 2.0)
	
	# Update Layers When Rect Settings Changed
	update_layers()
	
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
		Rect2(cursor_from + Vector2.LEFT * 4.0, Vector2(8, timemarks_bg_size)),
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
	
	super()
	
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
	
	var selection_mode_button = InterfaceServer.create_button("Select Mode", texture_selection)
	var split_button = InterfaceServer.create_texture_button(texture_split)
	var split_right_button = InterfaceServer.create_texture_button(texture_split_right)
	var split_left_button = InterfaceServer.create_texture_button(texture_split_left)
	var marker_button = InterfaceServer.create_texture_button(texture_marker)
	
	var snap_cursor_button = InterfaceServer.create_texture_button(texture_snap_cursor)
	var snap_markers_button = InterfaceServer.create_texture_button(texture_snap_markers)
	var magnet_clips_button = InterfaceServer.create_texture_button(texture_magnet_clips)
	var link_button = InterfaceServer.create_texture_button(texture_link)
	var zoom_slider = InterfaceServer.create_slider_control(zoom, min_zoom, max_zoom, 500.0, texture_zoom_out, texture_zoom_in)
	
	splittool_panel.add_child(splittool_margin)
	splittool_margin.add_child(splittool_container)
	splittool_container.add_child(split_button)
	splittool_container.add_child(split_right_button)
	splittool_container.add_child(split_left_button)
	
	snaptool_panel.add_child(snaptool_margin)
	snaptool_margin.add_child(snaptool_container)
	snaptool_container.add_child(snap_cursor_button)
	snaptool_container.add_child(snap_markers_button)
	snaptool_container.add_child(magnet_clips_button)
	
	toolbar_left_container.add_child(selection_mode_button)
	toolbar_left_container.add_child(marker_button)
	toolbar_left_container.add_child(splittool_panel)
	
	toolbar_right_container.add_child(snaptool_panel)
	toolbar_right_container.add_child(link_button)
	toolbar_right_container.add_child(zoom_slider)
	
	split_container.add_child(toolbar_left_container)
	split_container.add_child(toolbar_right_container)
	header.add_child(split_container)
	
	selection_mode_button.pressed.connect(on_selection_mode_button_pressed)


func start_selection_box() -> void:
	clips_selection_box = InterfaceServer.create_selection_box([], [is_timeline_state_equal_to.bind(2), EditorServer.is_any_media_clip_focused])
	clips_selection_box.id_key_function_name = "get_id_key"
	body.add_child(clips_selection_box)
	clips_selection_box.selection_ended.connect(on_clips_selection_box_selection_ended)

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
	clips_selection_box.select_from.append(layer)
	layers_container.add_child(layer)
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






# Connections Functions
# ---------------------------------------------------


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

func on_clips_selection_box_selection_ended(grouping: bool, remove: bool) -> void:
	var selection_group_res = EditorServer.media_clips_selection_group
	var selected_nodes = clips_selection_box.selected_nodes
	
	if remove:
		selection_group_res.remove_objects(selected_nodes)
		return
	
	elif not grouping:
		selection_group_res.clear_objects()
	selection_group_res.add_objects(selected_nodes, ["layer_index", "clip_pos", "clip_res"])


func on_selection_mode_button_pressed() -> void:
	var selection_mode_menu = InterfaceServer.create_popuped_menu([
		MenuOption.new("Select"),
		MenuOption.new("Split")
	])
	add_child(selection_mode_menu)
	selection_mode_menu.popup()


# ---------------------------------------------------


func get_frame_from_display_pos(pos: float, media_cannot_snap: Array = [], cursor_can_snap: bool = true, timemarks_can_snap: bool = true, snap_pos_can_change: bool = true) -> Dictionary[int, Variant]:
	
	var target_pos = int((pos - global_position.x) * display_snap_step / display_snap_dist + displacement_pos.x * display_snap_step)
	var snap_dist = null
	snap_pos = null
	
	if KEY_CTRL in pressed_keys:
		
		var snappable_frames: Dictionary[int, int] # kes is frame_index and value is dist to target_pos
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
		
		if cursor_can_snap:
			var dist_to_curr_frame = abs(curr_frame - target_pos)
			if dist_to_curr_frame < 10:
				snappable_frames[dist_to_curr_frame] = curr_frame
		
		var _snap_dist = snappable_frames.keys().min()
		if _snap_dist == null:
			if timemarks_can_snap:
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









