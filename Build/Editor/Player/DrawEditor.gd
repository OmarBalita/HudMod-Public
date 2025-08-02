class_name DrawEdit extends Node2D

signal editor_mode_changed(new_val: int)


enum EditorModes {
	DRAW,
	EDIT,
	SCULPT
}

enum ToolLevels {
	START,
	PROCESS,
	END
}

@export var draw_node: GDDraw
@export var enabled: bool = true

@export_group("Edit Properties")
@export var editor_mode: EditorModes:
	set(val):
		editor_mode = val
		selected_points_multimesh_instance.visible = val
		queue_redraw()
		editor_mode_changed.emit(val)

@export_subgroup("Draw")
@export_enum("Pen", "Pointing", "Erase", "Fill", "Draw_shape") var draw_mode: int
@export_enum("Line", "Rect", "Circle") var draw_shape_mode: int
@export var default_drawing_res: GDDrawingRes
@export var pen_is_stabilize: bool = true
@export_range(.0, 100.0) var stiffness: float = 4.0
@export_range(1, 1000) var eraser_scale: float = 100.0
@export var draw_shape_is_centered: bool = true

@export_subgroup("Edit")
@export_enum("Point", "Drawing") var edit_select_mode: int
@export_enum("None", "Move", "Rotate", "Scaling", "Expand Radius") var is_editing: int
@export_enum("World Origin", "Median Point", "Individual Origins") var center_type: int = 1

@export_subgroup("Snap")
@export var snap_grid: bool = false
@export_range(1, 1000) var grid_size: int = 20

@export_group("Theme")
@export_subgroup("Texture")
@export var texture_draw: Texture2D = preload("res://Asset/Icons/pen.png")
@export var texture_fill: Texture2D = preload("res://Asset/Icons/fill.png")
@export var texture_cursor: Texture2D = preload("res://Asset/Icons/clicks.png")


var selected_points: Dictionary[GDDrawingRes, Dictionary]
var selected_points_size: int


var is_draw_started: bool
var draw_stabilize_pos: Vector2

var is_erase_started: bool

var is_shape_started: bool
var shape_start_pos: Vector2

var select_start_pos = null: # if select_start_pos is a Vector2 draw selection_box else don't draw
	set(val):
		select_start_pos = val
		if select_start_pos != null:
			latest_rot_angle = select_start_pos.angle()
			latest_scale_dist = .0
			set_axis_editing()
		queue_redraw()

var edit_axis: Dictionary[String, bool]
var drawings_editing_right_now: Dictionary[GDDrawingRes, Dictionary]

var latest_rot_angle: float
var latest_scale_dist: float

# RealTime Nodes

var selected_points_multimesh_instance:= MultiMeshInstance2D.new()










func _ready() -> void:
	# selected_points_multimesh_instance Setup
	var multimesh = MultiMesh.new()
	var mesh = SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	multimesh.use_colors = true
	multimesh.mesh = mesh
	selected_points_multimesh_instance.multimesh = multimesh
	add_child(selected_points_multimesh_instance)

func _input(event: InputEvent) -> void:
	
	if not enabled: return
	
	if event is InputEventMouse:
		
		var mouse_pos = get_global_mouse_position()
		var mouse_pos_snapped = mouse_pos
		if snap_grid: mouse_pos_snapped = snapped(mouse_pos, Vector2(grid_size, grid_size))
		
		var on_left_button_pressed: Callable
		var on_left_button_released: Callable
		var on_right_button_pressed: Callable
		var on_right_button_released: Callable
		var on_mouse_motion: Callable
		
		match editor_mode:
			
			EditorModes.DRAW:
				
				match draw_mode:
					
					0:
						on_left_button_pressed = start_drawing.bind(mouse_pos_snapped)
						on_left_button_released = end_drawing
						on_mouse_motion = add_point_to_drawing.bind(mouse_pos_snapped)
					1:
						on_left_button_pressed = add_point_to_drawing.bind(mouse_pos_snapped) if is_draw_started else start_drawing.bind(mouse_pos_snapped)
						on_right_button_pressed = end_drawing
					2:
						on_left_button_pressed = start_erase.bind(mouse_pos)
						on_left_button_released = end_erase
						on_mouse_motion = erase_drawings.bind(mouse_pos)
					3:
						on_left_button_pressed = fill.bind(mouse_pos)
					4:
						on_left_button_pressed = start_shape.bind(mouse_pos_snapped)
						on_left_button_released = end_shape
						on_mouse_motion = update_shape.bind(mouse_pos_snapped, event.shift_pressed)
			
			EditorModes.EDIT:
				if is_editing:
					on_left_button_released = apply_editing.bind()
					on_right_button_released = discard_editing.bind()
					on_mouse_motion = process_editing.bind(mouse_pos_snapped)
				else:
					var args = [mouse_pos, event.ctrl_pressed, event.alt_pressed]
					on_left_button_pressed = start_selection.bindv(args)
					on_left_button_released = end_selection.bindv(args)
		
		if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if event.is_pressed():
						if on_left_button_pressed:
							on_left_button_pressed.call()
					elif on_left_button_released:
						on_left_button_released.call()
				MOUSE_BUTTON_RIGHT:
					if event.is_pressed():
						if on_right_button_pressed:
							on_left_button_pressed.call()
					elif on_right_button_released:
						on_right_button_released.call()
		
		elif event is InputEventMouseMotion:
			if on_mouse_motion:
				on_mouse_motion.call()
		
		queue_redraw()




func _draw() -> void:
	
	# Theme Colors
	var color_normal = InterfaceServer.COLOR_NORMAL
	var color_accent = InterfaceServer.COLOR_ACCENT_BLUE
	
	var mouse_pos = get_global_mouse_position()
	var rect_size = Vector2(24, 24)
	var rect = Rect2(mouse_pos - rect_size, rect_size)
	
	if editor_mode == 0:
		
		if is_shape_started:
			draw_a_to_b_line(shape_start_pos, mouse_pos, color_normal, color_accent)
		
		match draw_mode:
			0: draw_texture_rect(texture_draw, rect, false, color_normal)
			1, 4: draw_texture_rect(texture_cursor, rect, false, color_normal)
			2: draw_circle(mouse_pos, eraser_scale, Color.INDIAN_RED, false, 1.0, true)
			3: draw_texture_rect(texture_fill, rect, false, color_normal)
	else:
		
		match is_editing:
			0 when select_start_pos != null:
					# Draw Custom SelectionBox
					var to_x_pos = Vector2(mouse_pos.x, select_start_pos.y)
					var to_y_pos = Vector2(select_start_pos.x, mouse_pos.y)
					var selection_box_rect = Rect2(select_start_pos, mouse_pos - select_start_pos)
					
					draw_rect(selection_box_rect, Color(color_normal, .5))
					draw_dashed_line(select_start_pos, to_x_pos, Color.WHITE, 2.0, 10.0)
					draw_dashed_line(to_x_pos, mouse_pos, Color.WHITE, 2.0, 10.0)
					draw_dashed_line(mouse_pos, to_y_pos, Color.WHITE, 2.0, 10.0)
					draw_dashed_line(to_y_pos, select_start_pos, Color.WHITE, 2.0, 10.0)
			2:
				pass
			3:
				draw_a_to_b_line(Vector2.ZERO, mouse_pos, color_normal, color_accent)



func draw_a_to_b_line(a: Vector2, b: Vector2, dashed_line_color: Color, circle_color: Color) -> void:
	draw_dashed_line(a, b, dashed_line_color, 2.0, 10.0)
	draw_circle(a, 5.0, circle_color, true, -1.0, true)
	draw_circle(b, 5.0, circle_color, true, -1.0, true)





func set_is_editing(val: int) -> void:
	if not selected_points_size:
		return
	is_editing = val
	
	if val:
		var result = loop_selected_points({"drawings_editing_right_now": {} as Dictionary[GDDrawingRes, Dictionary]}, null,
		func(d,i,p,c) -> void:
			if not c.drawings_editing_right_now.has(d):
				c.drawings_editing_right_now[d] = {"original_points": d.points.duplicate()}
		)
		drawings_editing_right_now = result.drawings_editing_right_now
		_result_selected_points_from({}, 0, true, false, true)
		select_start_pos = get_global_mouse_position()
	else:
		select_start_pos = null
	
	queue_redraw()

func is_point_selected(drawing_res: GDDrawingRes, point_index: int) -> bool:
	if selected_points.has(drawing_res):
		return selected_points[drawing_res].has(point_index)
	return false

func loop_selected_points(custom_info: Dictionary, _selected_points: Variant, function: Callable) -> Dictionary:
	
	if _selected_points == null:
		_selected_points = selected_points
	
	for drawing_res: GDDrawingRes in _selected_points.keys():
		var points = _selected_points[drawing_res]
		for point_index: int in points.keys():
			var point = points[point_index]
			function.call(drawing_res, point_index, point, custom_info)
	
	return custom_info

func get_selected_points_center() -> Vector2:
	var result = loop_selected_points({"total": Vector2()}, null,
		func(drawing_res: GDDrawingRes, point_index: int, point: Vector2, custom_info: Dictionary) -> void:
			custom_info.total += point
	)
	return result.total / selected_points_size

func set_axis_editing(edit_x: bool = true, edit_y: bool = true) -> void:
	edit_axis["x"] = edit_x
	edit_axis["y"] = edit_y

func get_x_editing() -> bool:
	return edit_axis["x"]

func get_y_editing() -> bool:
	return edit_axis["y"]


func sleep(times: int = 1) -> void:
	enabled = false
	for time in times:
		await get_tree().process_frame
	enabled = true








func start_drawing(pos: Vector2) -> void:
	draw_stabilize_pos = pos
	draw_node.start_new_drawing(default_drawing_res, pos)
	is_draw_started = true

func add_point_to_drawing(pos: Vector2) -> void:
	if is_draw_started:
		draw_stabilize_pos = draw_stabilize_pos.lerp(pos, 1.0 / stiffness)
		draw_node.add_point_to_current_drawing(draw_stabilize_pos if pen_is_stabilize else pos)

func end_drawing() -> void:
	is_draw_started = false


func start_erase(pos: Vector2) -> void:
	erase_drawings(pos)
	is_erase_started = true

func erase_drawings(pos: Vector2) -> void:
	if is_erase_started:
		draw_node.erase_drawing_nodes(pos, eraser_scale)

func end_erase() -> void:
	is_erase_started = false


func fill(pos: Vector2) -> void:
	draw_node.fill_drawing_nodes(default_drawing_res, pos, 5)







func start_shape(pos: Vector2) -> void:
	draw_node.start_new_drawing(default_drawing_res, pos)
	shape_start_pos = pos
	is_shape_started = true

func update_shape(shape_end_pos: Vector2, is_shape_absolute: bool) -> void:
	
	if not is_shape_started:
		return
	
	var new_points: Array[Vector2]
	
	var x_dist = shape_end_pos.x - shape_start_pos.x
	var y_dist = shape_end_pos.y - shape_start_pos.y
	var dist = Vector2(x_dist, y_dist)
	
	match draw_shape_mode:
		0:
			new_points.append(shape_start_pos)
			new_points.append(shape_end_pos)
		1:
			var absolute_size = Vector2.ONE * max(abs(x_dist), abs(y_dist))
			if shape_end_pos.x < shape_start_pos.x:
				absolute_size.x *= -1.0
			if shape_end_pos.y < shape_start_pos.y:
				absolute_size.y *= -1.0
			var rect_size = absolute_size if is_shape_absolute else dist
			var offset = shape_start_pos
			if draw_shape_is_centered:
				rect_size *= 2.0
				offset -= rect_size / 2.0
			new_points.append(offset)
			new_points.append(offset + Vector2(rect_size.x, 0))
			new_points.append(offset + rect_size)
			new_points.append(offset + Vector2(0, rect_size.y))
			new_points.append(offset)
		2:
			var absolute_radius = shape_start_pos.distance_to(shape_end_pos)
			var radius = Vector2.ONE * absolute_radius if is_shape_absolute else dist
			var offset = shape_start_pos
			
			if not draw_shape_is_centered:
				radius /= 2.0
				offset += dist / 2.0
			
			var circle_polygons: int = 32
			var step_rad = TAU / float(circle_polygons)
			
			for polygon: int in circle_polygons + 1:
				var time_rad = polygon * step_rad
				var time_point = offset + Vector2(sin(time_rad), cos(time_rad)) * radius
				new_points.append(time_point)
	
	draw_node.set_points_to_current_drawing(new_points)

func end_shape() -> void:
	is_shape_started = false





func start_selection(pos: Vector2, grouping: bool, remove: bool) -> void:
	select_start_pos = pos
	
	var result = _select_with_condition(func(d,i,p): return _is_select_dist(pos, p), true)
	
	if result.selected_points_size and not remove:
		_result_selected_points_from(result.selected_points, result.selected_points_size, grouping, remove, true)
		_update_selected_points_multimesh_instance()
		set_is_editing(1)


func end_selection(pos: Vector2, grouping: bool, remove: bool) -> void:
	
	if select_start_pos != null:
		
		var selection_box_rect = Rect2(select_start_pos, pos - select_start_pos).abs()
		
		var select_function: Callable = func(drawing_res, point_index, point) -> bool:
			return selection_box_rect.has_point(point)
		var select_one_time: bool = false
		
		if pos.distance_to(select_start_pos) < 20.0:
			select_function = func(drawing_res, point_index, point) -> bool:
				return _is_select_dist(pos, point)
			select_one_time = true
		
		select_and_update(select_function, select_one_time, grouping, remove)
		
		select_start_pos = null





func apply_editing() -> void:
	set_is_editing(0)
	sleep()

func discard_editing() -> void:
	drawings_editing_right_now.keys().map(
		func(d: GDDrawingRes) -> void:
			d.set_points(drawings_editing_right_now.get(d).original_points)
	)
	_update_selected_points_multimesh_instance()
	set_is_editing(0)
	sleep()

func process_editing(pos: Vector2) -> void:
	var selected_points_center = get_selected_points_center()
	var center_func: Callable
	match center_type:
		0: center_func = func(b,i,p,c): return Vector2.ZERO
		1: center_func = func(b,i,p,c): return selected_points_center
		2: center_func = func(b,i,p,c): return b.get_center_point()
	
	var curr_offset = pos - select_start_pos
	
	var curr_rot_angle = (pos - selected_points_center).angle()
	var angle_delta = rad_to_deg(curr_rot_angle - latest_rot_angle)
	
	var curr_scale_dist = pos.distance_to(selected_points_center)
	var scale_ratio: float = 1.0
	if latest_scale_dist != .0:
		scale_ratio = curr_scale_dist / latest_scale_dist
	
	var is_x_editing = get_x_editing()
	var is_y_editing = get_y_editing()
	
	loop_selected_points({}, null,
		func(drawing_res: GDDrawingRes, point_index: int, point: Vector2, custom_info: Dictionary) -> void:
			
			var absolute_center = center_func.call(drawing_res, point_index, point, custom_info)
			match is_editing:
				1: drawing_res.move_point(point_index, point + curr_offset, is_x_editing, is_y_editing)
				2: drawing_res.rotate_point(point_index, angle_delta, absolute_center)
				3: drawing_res.scale_point(point_index, scale_ratio, absolute_center, is_x_editing, is_y_editing)
				4: drawing_res.expand_point_radius(point_index, scale_ratio)
	)
	
	drawings_editing_right_now.keys().map(func(d: GDDrawingRes) -> void: d.points_changed.emit())
	
	latest_rot_angle = curr_rot_angle
	latest_scale_dist = curr_scale_dist
	_update_selected_points_multimesh_instance()









func select_and_update(select_condition_function: Callable, select_one_time: bool = false, grouping: bool = false, remove: bool = false, update_all: bool = false) -> void:
	var result = _select_with_condition(select_condition_function, select_one_time)
	_result_selected_points_from(result.selected_points, result.selected_points_size, grouping, remove, update_all)
	_update_selected_points_multimesh_instance()

func select_all(it_is: bool) -> void:
	select_and_update(func(d,i,p): return it_is)

func select_invert() -> void:
	select_and_update(func(d,i,p): return not is_point_selected(d, i))

func select_linked() -> void:
	select_and_update(func(d,i,p): return selected_points.has(d))

func select_intermittent(steps: int) -> void:
	select_and_update(func(d,i,p): return selected_points.has(d) and i % steps == 0)

func select_random() -> void:
	select_and_update(func(d,i,p): return bool(randi_range(0, 1)))


func _select_with_condition(select_condition_function: Callable, select_one_time: bool = false) -> Dictionary:
	
	var info = draw_node.loop_all_points({"selected_points": {} as Dictionary[GDDrawingRes, Dictionary], "selected_points_size": 0},
		func(drawing_res: GDDrawingRes, point_index: int, point: Vector2, info: Dictionary) -> void:
			if select_condition_function.call(drawing_res, point_index, point):
				var new_selected_points = info.selected_points
				if not new_selected_points.has(drawing_res):
					new_selected_points.set(drawing_res, {})
				new_selected_points[drawing_res][point_index] = point
				info.selected_points_size += 1
				if select_one_time:
					info.break = true
	)
	return info


func _is_select_dist(mouse_pos: Vector2, point: Vector2) -> bool:
	return mouse_pos.distance_to(point) <= 10.0

func _result_selected_points_from(new_selected_points: Dictionary[GDDrawingRes, Dictionary], new_selected_points_size: int, grouping: bool, remove: bool, update_all_points: bool = false) -> void:
	if remove:
		var info = loop_selected_points({"new_selected_points": selected_points, "new_selected_points_size": selected_points_size}, new_selected_points,
			func(drawing_res: GDDrawingRes, point_index: int, point: Vector2, info: Dictionary):
				if is_point_selected(drawing_res, point_index):
					info.new_selected_points[drawing_res].erase(point_index)
					info.new_selected_points_size -= 1
		)
		
		selected_points = info.new_selected_points
		selected_points_size = info.new_selected_points_size
	
	elif grouping:
		# Merge Selected Points for Each DrawingRes Part
		selected_points.merge(new_selected_points)
		for drawing_res in selected_points.keys():
			var points = selected_points[drawing_res]
			if update_all_points:
				for point_index: int in points.keys():
					points[point_index] = drawing_res.points[point_index]
			if new_selected_points.has(drawing_res):
				points.merge(new_selected_points[drawing_res])
		
		selected_points_size += new_selected_points_size
	
	else:
		selected_points = new_selected_points
		selected_points_size = new_selected_points_size



func _update_selected_points_multimesh_instance() -> void:
	var multimesh = selected_points_multimesh_instance.multimesh
	multimesh.instance_count = draw_node.get_drawings_points_size()
	
	draw_node.loop_all_points({"time": 0},
		func(drawing_res: GDDrawingRes, point_index: int, point: Vector2, info: Dictionary) -> void:
			var curr_time = info.time
			multimesh.set_instance_transform_2d(curr_time, Transform2D(.0, Vector2(10, 10), .0, point))
			multimesh.set_instance_color(curr_time, Color.ORANGE if is_point_selected(drawing_res, point_index) else Color.WHITE)
			info.time += 1
	)


