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
		ProjectServer.update_curr_clips()
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
var display_layer_edit_size: Vector2

# RealTime Nodes

var layers_container: BoxContainer


# Set Get Functions
# ---------------------------------------------------

func set_curr_frame_manually(frame: int) -> void:
	stop()
	curr_frame = frame
	curr_frame_changed_manually.emit(curr_frame)


# Background Called Functions
# ---------------------------------------------------

func _init() -> void:
	just_press_functions = {
		KEY_SPACE: func(): stop() if is_playing else play()
	}
	press_functions = {
		KEY_LEFT: func(): set_curr_frame_manually(curr_frame - 1),
		KEY_RIGHT: func(): set_curr_frame_manually(curr_frame + 1),
	}
	l_button_downed.connect(func(): curr_frame_played_manually.emit())
	l_button_upped.connect(func(): curr_frame_stopped_manually.emit())
	
	editor_guides = [
		{"Move Cursor": "[Mouse-Left]"},
		{"Move TimeLine": "[Mouse-Right]"},
		{"Move Layers": "[Mouse-Right] + [Shift]"}
	]


func _start() -> void:
	super()
	# Start Connections
	l_button_downed.connect(on_l_button_downed)
	wheel_downed.connect(on_wheel_downed)
	wheel_upped.connect(on_wheel_upped)
	# Start Layers
	start_layers()


func _input(event: InputEvent) -> void:
	super(event)
	if event is InputEventMouseMotion:
		if l_button_down:
			set_curr_frame_manually(get_frame_from_display_pos(event.position.x))
		elif r_button_down:
			displacement_pos -= Vector2(
				event.relative.x / display_snap_dist,
				event.relative.y * float(KEY_SHIFT in pressed_keys)
			)

func _draw() -> void:
	
	# Limit Y Displacement Position
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
	
	draw_line(Vector2(.0, header_size), Vector2(size.x, header_size), Color.CORNFLOWER_BLUE, 3.0)
	
	
	# Draw Cursor
	display_cursor_pos = get_display_pos_from_frame(curr_frame)
	var cursor_from = Vector2(display_cursor_pos, header_size)
	
	if display_cursor_pos > display_layer_edit_size.x:
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
	
	super()
	
	timeline_view_changed.emit()


# ---------------------------------------------------


func start_layers() -> void:
	layers_container = InterfaceServer.create_box_container(2, true, {"clip_contents": true})
	update_layers()
	body.add_child(layers_container)

func update_layers() -> void:
	
	var layers_count = int(size.y / layer_display_size)
	var layers_displacement = int(displacement_pos.y / layer_display_size)
	var layers_range = range(layers_displacement, layers_displacement + layers_count + 1)
	
	# Spawn Remaining Layers
	var layers_before = []
	
	for index in layers_range:
		if index in curr_layers_range or index > 0: continue
		if curr_layers_range.size() and index < curr_layers_range.min():
			layers_before.append(index)
			continue
		spawn_layer(-index)
	
	layers_before.sort()
	layers_before.reverse()
	
	for index in layers_before:
		var layer = spawn_layer(-index)
		layers_container.move_child(layer, 0)
	
	
	curr_layers_range = layers_range
	
	# Remove Other Layers
	for layer: Layer in layers_container.get_children():
		var index = -layer.index
		if index not in curr_layers_range:
			layer.queue_free()
	
	await get_tree().process_frame
	display_layer_edit_size = layers_container.get_child(0).container.size
	
	layers_container.position.y = int(-displacement_pos.y) % int(layer_display_size) - layer_display_size


func spawn_layer(index: int) -> Layer:
	var layer = InterfaceServer.create_layer(index, Vector2(size.x, layer_display_size), color_layer)
	layers_container.add_child(layer)
	return layer






# Connections Functions
# ---------------------------------------------------

func on_l_button_downed(pos: Vector2) -> void:
	set_curr_frame_manually(get_frame_from_display_pos(pos.x))

func on_wheel_downed(pos: Vector2) -> void:
	zoom -= zoom_step * zoom

func on_wheel_upped(pos: Vector2) -> void:
	zoom += zoom_step * zoom


# ---------------------------------------------------


func get_frame_from_display_pos(pos: float) -> int:
	var target_pos = int((pos - global_position.x) * display_snap_step / display_snap_dist + displacement_pos.x * display_snap_step)
	if KEY_CTRL in pressed_keys: target_pos = snapped(target_pos, display_snap_step)
	return target_pos

func get_display_pos_from_frame(frame: int) -> float:
	return frame * display_frame_size - displacement_pos.x * display_snap_dist


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











