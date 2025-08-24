class_name DrawEdit extends Node2D

signal editor_mode_changed(new_val: int)

signal edit_finished()
signal edit_accepted()
signal edit_discarded()

signal selected_points_changed(selected_points_size: int, selected_points_center: Vector2)


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

enum DrawModes {
	PEN,
	POINTING,
	ERASE,
	FILL,
	DRAW_SHAPE
}


@export var enabled: bool = true
@export var draw_node: GDDraw

@export_group("Edit Properties")
@export var editor_mode: EditorModes:
	set(val):
		editor_mode = val
		update_points_multimesh_instance_visibility()
		queue_redraw()
		editor_mode_changed.emit(val)

@export_subgroup("Draw")
@export var draw_mode: DrawModes:
	set(val):
		draw_mode = clamp(val, 0, DrawModes.size())
		queue_redraw()

@export var brushes: Array[GDDrawingRes]
@export var curr_brush_index: int
@export var pen_is_stabilize: bool = true
@export_range(.0, 100.0) var stiffness: float = 4.0
@export_range(1, 1000) var eraser_scale: float = 100.0
@export_range(2, 10) var fill_grid_size: int = 4
@export_enum("Line", "Rect", "Circle") var draw_shape_mode: int
@export var draw_shape_is_centered: bool = true
@export_range(1, 4069) var circle_subdv: int = 32

@export_subgroup("Draw Custom Properties")
@export var use_custom_properties: bool
@export var custom_line_color: Color = Color.WHITE
@export var custom_fill_color: Color = Color.GRAY
@export_range(.01, 1000.0) var custom_width: float = 5.0
@export_range(.0, 1.0) var custom_strength: float = 1.0

@export_subgroup("Edit")
@export_enum("Point", "Drawing") var edit_select_mode: int
@export_enum("None", "Move", "Rotate", "Scaling", "Expand Radius") var is_editing: int
@export_enum("World Origin", "Median Point", "Individual Origins") var center_type: int = 1
@export var edit_is_proportional: bool
@export_enum("Smooth", "Sphere", "Sharp", "Linear", "Constant") var proportional_edit_option: int
@export_range(.01, 1000.0) var proportional_edit_scale: float = 1.0
@export var proportional_edit_connected_only: bool

@export_subgroup("Snap")
@export var snap_grid: bool = false
@export_range(1, 1000) var grid_size: int = 20

@export_group("Theme")
@export_group("Draw and Debugging")
@export var force_points_multimesh_visiblity: bool:
	set(val): force_points_multimesh_visiblity = val; update_points_multimesh_instance_visibility()
@export_subgroup("Texture")
@export var texture_draw: Texture2D = preload("res://Asset/Icons/pen.png")
@export var texture_fill: Texture2D = preload("res://Asset/Icons/fill.png")
@export var texture_cursor: Texture2D = preload("res://Asset/Icons/clicks.png")


var selected_points: Dictionary[GDDrawingRes, Dictionary]
var selected_points_size: int
var selected_points_center: Vector2

var focused_drawing: GDDrawingRes

var is_draw_started: bool
var draw_stabilize_pos: Vector2

var is_erase_started: bool

var is_shape_started: bool
var shape_start_pos: Vector2

var select_start_pos = null: # if select_start_pos is a Vector2 draw selection_box else don't draw
	set(val):
		select_start_pos = val
		if select_start_pos != null:
			latest_rot_angle = (val - selected_points_center).angle()
			latest_scale_dist = .0
		queue_redraw()

var drawings_editing_right_now: Dictionary[GDDrawingRes, Dictionary]
var edit_axis: Dictionary[String, bool] = {"x": true, "y": true}
var edit_value: Variant = null:
	set(val):
		edit_value = val
		if edit_value != null and is_editing:
			var curr_is_editing = is_editing
			discard_editing(false, false, false)
			set_is_editing(curr_is_editing)
			process_editing()
var latest_rot_angle: float
var latest_scale_dist: float

var copied_drawings_ress: Array[GDDrawingRes]


# RealTime Nodes

var points_multimesh_instance:= MultiMeshInstance2D.new()






func _ready() -> void:
	# points_multimesh_instance Setup
	add_child(points_multimesh_instance)

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
						on_left_button_pressed = add_point_to_drawing.bind(mouse_pos_snapped, false) if is_draw_started else start_drawing.bind(mouse_pos_snapped)
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
					on_left_button_released = apply_editing.bind(true)
					on_right_button_released = discard_editing.bind(true)
					if edit_value == null:
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
	var rect = Rect2(mouse_pos, rect_size)
	
	if editor_mode == 0:
		
		if is_shape_started:
			draw_a_to_b_line(shape_start_pos, mouse_pos, color_normal, color_accent)
		
		match draw_mode:
			0:
				rect.position.y -= rect_size.y
				draw_texture_rect(texture_draw, rect, false, color_normal)
			1, 4:
				rect.position -= rect_size / 2.0
				draw_texture_rect(texture_cursor, rect, false, color_normal)
			2:
				draw_circle(mouse_pos, eraser_scale, Color.INDIAN_RED, false, 1.0, true)
			3:
				rect.position -= rect_size
				draw_texture_rect(texture_fill, rect, false, color_normal)
	else:
		
		var center_point = Vector2.ZERO if center_type == 0 else selected_points_center
		var viewport_size = get_viewport_rect().size
		
		if is_editing:
			if get_x_editing(): draw_line(Vector2(0, center_point.y), Vector2(viewport_size.x, center_point.y), Color(Color.RED, .5), 3.0)
			if get_y_editing(): draw_line(Vector2(center_point.x, 0), Vector2(center_point.x, viewport_size.y), Color(Color.GREEN, .5), 3.0)
		
		match is_editing:
			0 when select_start_pos != null:
					# Draw Custom SelectionBox
					var to_x_pos = Vector2(mouse_pos.x, select_start_pos.y)
					var to_y_pos = Vector2(select_start_pos.x, mouse_pos.y)
					var selection_box_rect = Rect2(select_start_pos, mouse_pos - select_start_pos)
					
					draw_rect(selection_box_rect, Color(color_accent, .5))
					draw_dashed_line(select_start_pos, to_x_pos, color_accent, 2.0, 10.0)
					draw_dashed_line(to_x_pos, mouse_pos, color_accent, 2.0, 10.0)
					draw_dashed_line(mouse_pos, to_y_pos, color_accent, 2.0, 10.0)
					draw_dashed_line(to_y_pos, select_start_pos, color_accent, 2.0, 10.0)
			3:
				draw_a_to_b_line(center_point, mouse_pos, color_normal, color_accent)



func draw_a_to_b_line(a: Vector2, b: Vector2, dashed_line_color: Color, circle_color: Color) -> void:
	draw_dashed_line(a, b, dashed_line_color, 2.0, 10.0)
	draw_circle(a, 5.0, circle_color, true, -1.0, true)
	draw_circle(b, 5.0, circle_color, true, -1.0, true)



func sleep(times: int = 1) -> void:
	enabled = false
	for time in times:
		await get_tree().process_frame
	enabled = true

func get_curr_brush() -> GDDrawingRes:
	return brushes[curr_brush_index]

func get_absolute_brush() -> GDDrawingRes:
	var brush: GDDrawingRes = get_curr_brush()
	if use_custom_properties:
		brush = brush.duplicate(true)
		brush.color_line = custom_line_color
		brush.color_fill = custom_fill_color
		brush.main_width = custom_width
		brush.strength = custom_strength
	return brush

func get_curr_brush_index() -> int:
	return curr_brush_index

func set_curr_brush_index(index: int) -> void:
	curr_brush_index = index

func set_edit_value(new_edit_value: Variant) -> void:
	edit_value = new_edit_value


func set_is_editing(val: int) -> void:
	
	if not selected_points_size:
		return
	is_editing = val
	
	select_selected()
	
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

func reset_drawings_edited_right_now() -> void:
	drawings_editing_right_now.keys().map(
		func(d: GDDrawingRes) -> void:
			d.set_points(drawings_editing_right_now.get(d).original_points)
	)
	update_points_multimesh_instance_from_selected_points()

func set_axis_editing(edit_x: bool = true, edit_y: bool = true) -> void:
	set_axis(edit_x, edit_y)
	if is_editing:
		var curr_is_editing = is_editing
		discard_editing()
		set_is_editing(curr_is_editing)

func set_axis(edit_x: bool = true, edit_y: bool = true) -> void:
	edit_axis["x"] = edit_x
	edit_axis["y"] = edit_y

func get_x_editing() -> bool:
	return edit_axis["x"]

func get_y_editing() -> bool:
	return edit_axis["y"]



func is_point_selected(drawing_res: GDDrawingRes, point_index: int) -> bool:
	if selected_points.has(drawing_res):
		return selected_points[drawing_res].has(point_index)
	return false

func loop_selected_points(custom_info: Dictionary, _selected_points: Variant, function: Callable, drawing_function: Callable = Callable(), emit_points_changed: bool = false) -> Dictionary:
	
	if _selected_points == null:
		_selected_points = selected_points
	
	for drawing_res: GDDrawingRes in _selected_points.keys():
		var points = _selected_points[drawing_res]
		for point_index: int in points.keys():
			var point = points[point_index]
			function.call(drawing_res, point_index, point, custom_info)
		if emit_points_changed:
			drawing_res.points_changed.emit()
		if not drawing_function.is_null():
			drawing_function.call(drawing_res, custom_info)
	
	return custom_info

func loop_selected_drawings(custom_info: Dictionary, update_when_finished: bool, function: Callable) -> Dictionary:
	
	var result = draw_node.loop_drawings_ress(custom_info,
		func(drawing_res: GDDrawingRes, custom_info: Dictionary) -> void:
			if not selected_points.has(drawing_res):
				return
			function.call(drawing_res, custom_info)
	)
	
	if update_when_finished:
		draw_node.update_drawings()
	
	return result


func loop_selected_points_as_entities(custom_info: Dictionary, entity_function: Callable) -> Dictionary:
	
	var result = loop_selected_points(custom_info.merged({"entities_points": {}}), null,
		func(d: GDDrawingRes, i: int, p: Vector2, c: Dictionary) -> void:
			
			var ep = c.entities_points
			var curr_entities: Array = ep.get_or_add(d, [])
			if not curr_entities.size():
				curr_entities.append({})
			
			var curr_entity = curr_entities.back()
			var latest_index = curr_entity.keys().back()
			var is_collection_ended = i >= selected_points[d].keys().max()
			var is_collection_separated = latest_index != null and latest_index != i - 1
			
			if is_collection_ended:
				curr_entity[i] = p
				if not entity_function.is_null(): entity_function.call(d, curr_entity, c)
			elif is_collection_separated:
				if not entity_function.is_null(): entity_function.call(d, curr_entity, c)
				curr_entities.append({i: p})
			if is_collection_ended or not is_collection_separated:
				curr_entity[i] = p
	)
	return result


func set_selected_points_center(new_selected_points_center: Vector2) -> void:
	selected_points_center = new_selected_points_center

func calculate_selected_points_center() -> Vector2:
	var total = loop_selected_points({"total": Vector2()}, null,
		func(drawing_res: GDDrawingRes, point_index: int, point: Vector2, custom_info: Dictionary) -> void:
			custom_info.total += point
	).total
	return total / selected_points_size

func get_center_func() -> Callable:
	var center_func: Callable
	match center_type:
		0: center_func = func(d,i,p) -> Vector2: return Vector2.ZERO
		1: center_func = func(d,i,p) -> Vector2: return selected_points_center
		2: center_func = func(d,i,p) -> Vector2: return d.get_center_point()
	return center_func

func update_points_multimesh_instance_visibility() -> void:
	points_multimesh_instance.visible = editor_mode == 1 or force_points_multimesh_visiblity


func update_points_multimesh_instance_from_selected_points() -> void:
	
	update_points_multimesh_instance(func(d,i,p,c) -> Color:
		var color_result: Color
		if is_point_selected(d, i):
			color_result = Color.ORANGE if d == focused_drawing else Color.ORANGE_RED
		else: color_result = Color.GRAY
		return color_result
	)


func update_points_multimesh_instance(color_func: Callable = Callable(), custom_drawings_ress: Variant = null) -> void:
	if custom_drawings_ress == null:
		custom_drawings_ress = draw_node.get_drawings_ress()
	
	var multimesh = MultiMesh.new()
	var mesh = BoxMesh.new()
	multimesh.use_colors = true
	multimesh.mesh = mesh
	multimesh.instance_count = draw_node.get_drawings_points_size()
	points_multimesh_instance.multimesh = multimesh
	
	draw_node.loop_all_points({"time": 0},
		func(drawing_res: GDDrawingRes, point_index: int, point: Vector2, info: Dictionary) -> void:
			var curr_time = info.time
			var color_result = Color.GRAY if color_func.is_null() else color_func.call(drawing_res, point_index, point, info)
			multimesh.set_instance_transform_2d(curr_time, Transform2D(.0, Vector2(5, 5), .0, point))
			multimesh.set_instance_color(curr_time, color_result)
			info.time += 1,
	custom_drawings_ress
	)





func get_subdv_points_from(points: PackedVector2Array, subdv_times: int = 1) -> PackedVector2Array:
	var result: PackedVector2Array
	for index: int in points.size() - 1:
		var p1 = points[index]
		var p2 = points[index + 1]
		var index_result = get_subdv_points_from_two_points(p1, p2, subdv_times + 1)
		result.append_array(index_result)
	result.append(points[-1])
	return result


func get_subdv_points_from_two_points(p1: Vector2, p2: Vector2, times: int = 1) -> PackedVector2Array:
	var result: PackedVector2Array
	var a_to_b_dist: float = p1.distance_to(p2)
	for time: int in times:
		var offset = time / float(times)
		var point = p1 + (p2 - p1) * offset
		result.append(point)
	return result






func start_drawing(pos: Vector2) -> void:
	draw_stabilize_pos = pos
	draw_node.start_new_drawing(get_absolute_brush(), pos)
	is_draw_started = true

func add_point_to_drawing(pos: Vector2, use_stabilizer: bool = true) -> void:
	if is_draw_started:
		draw_stabilize_pos = draw_stabilize_pos.lerp(pos, 1.0 / stiffness)
		draw_node.add_point_to_current_drawing(draw_stabilize_pos if use_stabilizer and pen_is_stabilize else pos)

func end_drawing() -> void:
	is_draw_started = false


func start_erase(pos: Vector2) -> void:
	erase_drawings(pos)
	is_erase_started = true

func erase_drawings(pos: Vector2) -> void:
	if is_erase_started:
		draw_node.erase_drawing_nodes(func(d: GDDrawingRes, i: int, p: Vector2) -> bool: return p.distance_to(pos) <= eraser_scale)

func end_erase() -> void:
	is_erase_started = false
	draw_node.update_drawings()


func fill(pos: Vector2) -> void:
	draw_node.fill_drawing_nodes(get_absolute_brush(), pos, fill_grid_size)







func start_shape(pos: Vector2) -> void:
	draw_node.start_new_drawing(get_absolute_brush(), pos)
	shape_start_pos = pos
	is_shape_started = true

func update_shape(shape_end_pos: Vector2, is_shape_absolute: bool) -> void:
	
	if not is_shape_started:
		return
	
	var new_points: PackedVector2Array
	
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
			
			var step_rad = TAU / float(circle_subdv)
			
			for polygon: int in circle_subdv + 1:
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
		update_points_multimesh_instance_from_selected_points()
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





func apply_editing(reset_axis: bool = false, emit_changes: bool = true) -> void:
	if reset_axis: set_axis()
	
	set_is_editing(0)
	select_selected()
	sleep()
	
	if emit_changes:
		edit_accepted.emit()
		edit_finished.emit()

func discard_editing(reset_axis: bool = false, reset_edit_val: bool = true, emit_changes: bool = true) -> void:
	if reset_axis: set_axis()
	if reset_edit_val: set_edit_value(null)
	
	reset_drawings_edited_right_now()
	set_is_editing(0)
	sleep()
	
	if emit_changes:
		edit_discarded.emit()
		edit_finished.emit()

func process_editing(pos: Vector2 = Vector2.ZERO) -> void:
	var time = Time.get_ticks_msec()
	
	var center_func: Callable = get_center_func()
	
	var curr_offset = pos - select_start_pos
	
	var curr_rot_angle = (pos - selected_points_center).angle()
	var angle_delta = rad_to_deg(curr_rot_angle - latest_rot_angle)
	
	var curr_scale_dist = pos.distance_to(selected_points_center)
	var scale_ratio: float = 1.0
	if latest_scale_dist != .0:
		scale_ratio = curr_scale_dist / latest_scale_dist
	
	if edit_value != null:
		curr_offset = Vector2.ONE * edit_value
		angle_delta = edit_value
		scale_ratio = edit_value
	
	var is_x_editing = get_x_editing()
	var is_y_editing = get_y_editing()
	
	match is_editing:
		1: move_selected_points(curr_offset, is_x_editing, is_y_editing)
		2: rotate_selected_points(angle_delta, center_func)
		3: scale_selected_points(scale_ratio, center_func, is_x_editing, is_y_editing)
		4: expand_selected_points_radius(scale_ratio)
	
	latest_rot_angle = curr_rot_angle
	latest_scale_dist = curr_scale_dist
	
	update_points_multimesh_instance_from_selected_points()
	
	# C# - 18009 points - (avg : 238) (min : 215) (max : 268)
	# GDScript Time_1 - 18009 points - (avg : 169) (min : 152) (max : 297)
	# GDScript Time_2 (Multithreading) - 18009+ - (avg : 119) (min : 109) (max : 139)
	print(Time.get_ticks_msec() - time)




func move_selected_points(offset: Vector2, x: bool, y: bool) -> void:
	loop_selected_points({}, null, func(d: GDDrawingRes, i: int, p: Vector2, c: Dictionary) -> void:
		d.move_point(i, p + offset, x, y), Callable(), false
	)

func rotate_selected_points(angle: float, center_func: Callable) -> void:
	loop_selected_points({}, null, func(d: GDDrawingRes, i: int, p: Vector2, c: Dictionary) -> void:
		var center = center_func.call(d, i, p)
		d.rotate_point(i, angle, center), Callable(), false
	)

func scale_selected_points(scale_time: float, center_func: Callable, x: bool, y: bool) -> void:
	loop_selected_points({}, null, func(d: GDDrawingRes, i: int, p: Vector2, c: Dictionary) -> void:
		var center = center_func.call(d, i, p)
		d.scale_point(i, scale_time, center, x, y), Callable(), false
	)

func expand_selected_points_radius(expand_time: float) -> void:
	loop_selected_points({}, null, func(d: GDDrawingRes, i: int, p: Vector2, c: Dictionary) -> void:
		d.expand_point_radius(i, expand_time), Callable(), false
	)




func cut_selected() -> void:
	copy_selected(true)

func copy_selected(cut: bool = false) -> void:
	
	copied_drawings_ress.clear()
	
	for drawing_res: GDDrawingRes in selected_points: selected_points[drawing_res].sort()
	loop_selected_points_as_entities({},
		func(drawing_res: GDDrawingRes, entity: Dictionary, info: Dictionary) -> void:
			var new_res: GDDrawingRes = drawing_res.duplicate(true)
			var new_points = entity.values()
			new_res.set_points(PackedVector2Array(new_points))
			new_res.set_meta('copied_points', new_points.size())
			copied_drawings_ress.append(new_res)
	)
	
	if cut: delete_selected()

func past_selected() -> void:
	
	for d: GDDrawingRes in copied_drawings_ress:
		draw_node.create_new_drawing(d, [], -1, false, false, false)
	draw_node.update_drawings()
	
	select_and_update(
		func(d: GDDrawingRes, i: int, p: Vector2) -> bool:
			if not d.has_meta('copied_points'): return false
			var copied_points = d.get_meta('copied_points')
			d.set_meta('copied_points', copied_points - 1)
			return copied_points > 0
	)
	
	set_is_editing(1)

func duplicate_selected() -> void:
	copy_selected()
	past_selected()

func delete_selected() -> void:
	draw_node.erase_drawing_nodes(func(d: GDDrawingRes, i: int, p: Vector2) -> bool: return is_point_selected(d, i))
	draw_node.update_drawings()
	update_points_multimesh_instance_from_selected_points()


func mirror(x: bool = true, y: bool = true) -> void:
	scale_selected_points(-1, get_center_func(), x, y)
	select_selected()



func close_selected() -> void:
	loop_selected_drawings({}, false, func(d: GDDrawingRes, c: Dictionary) -> void: d.add_point(d.points[0]))

func separate_selected() -> void:
	cut_selected()
	past_selected()

func desolve_and_subdvide_selected(use_subdivide: bool, subdv_times: int = 1) -> void:
	var entities = loop_selected_points_as_entities({}, Callable()).entities_points
	
	for d: GDDrawingRes in entities:
		var indexing_offset: int
		var d_entities = entities.get(d)
		for index: int in d_entities.size():
			var entity = d_entities[index]
			var min_index: int = entity.keys().min()
			var max_index: int = entity.keys().max()
			var subdv_points: PackedVector2Array = get_subdv_points_from(entity.values(), subdv_times)
			indexing_offset -= d.desolve_points(min_index + indexing_offset - int(use_subdivide), max_index + indexing_offset + int(use_subdivide), false)
			if use_subdivide: indexing_offset += d.insert_points(min_index, subdv_points, false)
		d.points_changed.emit()
	
	select_all(false)


func desolve_selected() -> void:
	desolve_and_subdvide_selected(false)

func subdivide_selected(subdv_times: int = 1) -> void:
	desolve_and_subdvide_selected(true, subdv_times)

func extrude_selected() -> void:
	select_selected()
	var new_selected_points = loop_selected_points({"selected_points": {}}, null,
		func(d: GDDrawingRes, i: int, p: Vector2, c: Dictionary) -> void:
			var selected_drawing: GDDrawingRes = d
			var selected_index: int
			
			if i == 0:
				d.points.insert(0, p)
			elif d.is_max_index(i):
				d.points.append(p)
				selected_index = i + 1
			else:
				var new_drawing_res = draw_node.create_new_drawing(d, [p, p], draw_node.drawings_ress.find(d), false, true, false)
				selected_drawing = new_drawing_res
				selected_index = 1
			
			c.selected_points.get_or_add(selected_drawing, []).append(selected_index),
		Callable(), true
	).selected_points
	
	draw_node.update_drawings()
	
	select_and_update(func(d,i,p) -> bool: return new_selected_points.has(d) and new_selected_points[d].has(i))
	set_is_editing(1)


func join_selected() -> void:
	
	if selected_points.size() != 2 or selected_points_size != 2:
		return
	
	var drawing1: GDDrawingRes = selected_points.keys()[0]
	var drawing2: GDDrawingRes = selected_points.keys()[1]
	
	var index1: int = selected_points[drawing1].keys()[0]
	var index2: int = selected_points[drawing2].keys()[0]
	
	var new_points: PackedVector2Array
	
	var i1_is_max = drawing1.is_max_index(index1)
	var i2_is_max = drawing2.is_max_index(index2)
	
	if i1_is_max and i2_is_max:
		drawing2.points.reverse()
	elif index1 == 0 and index2 == 0:
		drawing1.points.reverse()
	elif index1 == 0 and i2_is_max:
		drawing1.points.reverse()
		drawing2.points.reverse()
	
	new_points = drawing1.get_points() + drawing2.get_points()
	draw_node.remove_drawing(drawing1, false)
	draw_node.remove_drawing(drawing2, false)
	draw_node.create_new_drawing(drawing1.duplicate(true), new_points, draw_node.get_drawings_ress().find(drawing1))
	
	select_all(false)





func apply_focused_drawing_properties(to_drawings: Array[GDDrawingRes] = []) -> void:
	if not focused_drawing:
		return
	
	var new_drawings = draw_node.loop_drawings_ress({"new_drawings": [] as Array[GDDrawingRes]},
		func(d: GDDrawingRes, c: Dictionary) -> void:
			
			if d == focused_drawing:
				return
			elif to_drawings.size() and d not in to_drawings:
				return
			
			var points = d.points
			var d_index = draw_node.remove_drawing(d, false)
			c.new_drawings.append(draw_node.create_new_drawing(focused_drawing, points, d_index, false, true, false))
	).new_drawings
	new_drawings.append(focused_drawing)
	
	draw_node.update_drawings()
	
	select_drawings(new_drawings)
	set_focused_drawing(focused_drawing)







func select_and_update(select_condition_function: Callable, select_one_time: bool = false, grouping: bool = false, remove: bool = false, update_all: bool = false) -> void:
	var result = _select_with_condition(select_condition_function, select_one_time)
	_result_selected_points_from(result.selected_points, result.selected_points_size, grouping, remove, update_all)
	set_selected_points_center(calculate_selected_points_center())
	set_focused_drawing(result.selected_points.keys().back())
	update_points_multimesh_instance_from_selected_points()
	selected_points_changed.emit(selected_points_size, selected_points_center)

func select_all(it_is: bool) -> void:
	select_and_update(func(d,i,p): return it_is)

func select_selected() -> void:
	select_and_update(func(d,i,p) -> bool: return is_point_selected(d, i))

func select_drawings(drawings: Array[GDDrawingRes]) -> void:
	select_and_update(func(d,i,p) -> bool: return drawings.has(d))

func select_invert() -> void:
	select_and_update(func(d,i,p) -> bool: return not is_point_selected(d, i))

func select_linked() -> void:
	select_and_update(func(d,i,p) -> bool: return selected_points.has(d))

func select_intermittent(steps: int) -> void:
	select_and_update(func(d,i,p) -> bool: return selected_points.has(d) and i % steps == 0)

func select_random() -> void:
	select_and_update(func(d,i,p) -> bool: return bool(randi_range(0, 1)))

func set_focused_drawing(drawing: GDDrawingRes) -> void:
	focused_drawing = drawing

func set_focused_drawing_from_index(index: int) -> void:
	focused_drawing = draw_node.get_drawings_ress()[index]



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










