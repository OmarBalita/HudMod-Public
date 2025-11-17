class_name GDDrawingRes extends UsableRes

signal points_changed()
signal entities_changed()
signal sliced(right_slice_points: PackedVector2Array)

enum RangeTypes {
	DIST,
	RATIO
}

enum CapsTypes {
	NONE = 0,
	ROUND = 2
}

enum DistMode {
	POINTS_DIST,
	CONST_DIST
}

@export var points: PackedVector2Array
@export var drawn_entities: Array[DrawnEntityRes]


@export_group("Default Properties")
@export var draw_line: bool = true
@export var draw_fill: bool = false
@export var antialised: bool = true

@export_subgroup("Color")
@export var color_line: Color = Color.WHITE
@export var color_fill: Color = Color.GRAY
@export var use_color_range: bool = false
@export var color_range: ColorRangeRes = ColorRangeRes.new()
@export_range(.0, 1.0) var strength: float = 1.0

@export_subgroup("Width")
@export_range(.01, 1000.0) var main_width: float = 5.0
@export var width_curve_range_type: RangeTypes = 0
@export var width_begin_curve: Curve
@export var width_end_curve: Curve
@export var baked_width: Array[float]
@export var is_width_free: bool = false
@export var width_begin_dist: float = 60.0
@export var width_end_dist: float = 60.0

@export_subgroup("Capping")
@export var cap_begin_type: CapsTypes = 0
@export var cap_end_type: CapsTypes = 0
@export var cap_begin_scale: float = 1.0
@export var cap_end_scale: float = 1.0

@export_subgroup("Meta Data")
@export var is_brush: bool = true
@export var brush_name: String

var center_point: Vector2




func _init(init_points: PackedVector2Array = [], init_drawn_entities: Array[DrawnEntityRes] = []) -> void:
	set_res_id("GDDrawingRes")
	
	points = init_points
	drawn_entities = init_drawn_entities
	
	res_changed.connect(on_res_changed)
	points_changed.connect(on_points_changed)


func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	var line_cond = [get_draw_line, [true]]
	var display_container = _get_drawing_res_display_viewport_container()
	var is_brush_exported_parameters: Dictionary[StringName, Dictionary]
	if is_brush:
		is_brush_exported_parameters = {
			"display": {'val': display_container, 'update_func': display_container.get_meta('update_func'), 'ui_cond': []},
			"brush_name": CtrlrHelper.get_string_controller_args([], brush_name),
		}
	return is_brush_exported_parameters.merged({
		"drawn_entities": CtrlrHelper.get_list_controller_args([], drawn_entities, ["DrawnEntityRes"]),
		
		"draw_line": CtrlrHelper.get_bool_controller_args([], draw_line),
		"draw_fill": CtrlrHelper.get_bool_controller_args([], draw_fill),
		"antialised": CtrlrHelper.get_bool_controller_args(line_cond, antialised),
		
		"color_line": CtrlrHelper.get_color_controller_args(line_cond, color_line),
		"color_fill": CtrlrHelper.get_color_controller_args([get_draw_fill, [true]], color_fill),
		"use_color_range": CtrlrHelper.get_bool_controller_args([], use_color_range),
		"color_range": CtrlrHelper.get_color_range_controller_args([get_use_color_range, [true]], color_range),
		
		"main_width": CtrlrHelper.get_float_controller_args(line_cond, false, main_width),
		"width_curve_range_type": CtrlrHelper.get_option_controller_args(line_cond, RangeTypes.keys(), width_curve_range_type),
		#"width_begin_curve": CtrlrHelper.get_curve_controller_args(width_begin_curve),
		#"width_end_curve": CtrlrHelper.get_curve_controller_args(width_end_curve),
		"width_begin_dist": CtrlrHelper.get_float_controller_args(line_cond, false, width_begin_dist),
		"width_end_dist": CtrlrHelper.get_float_controller_args(line_cond, false, width_end_dist),
		
		"cap_begin_type": CtrlrHelper.get_option_controller_args(line_cond, CapsTypes.keys(), cap_begin_type),
		"cap_end_type": CtrlrHelper.get_option_controller_args(line_cond, CapsTypes.keys(), cap_end_type),
		"cap_begin_scale": CtrlrHelper.get_float_controller_args([func() -> bool: return get_draw_line() and get_cap_begin_type(), [true]], false, cap_begin_scale),
		"cap_end_scale": CtrlrHelper.get_float_controller_args([func() -> bool: return get_draw_line() and get_cap_end_type(), [true]], false, cap_end_scale)
	})


func _get_drawing_res_display_viewport_container() -> SubViewportContainer:
	var viewport_container = IS.create_viewport_container({stretch = true, custom_minimum_size = Vector2(0, 80.0)})
	var viewport = SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	
	var drawing_node = GDDrawingNode.new()
	var camera = Camera2D.new()
	
	viewport.add_child(drawing_node)
	viewport.add_child(camera)
	viewport_container.add_child(viewport)
	
	viewport_container.set_meta('update_func', func() -> void:
		
		var drawing_res = self.duplicate(true)
		var points_count = 50
		var time_scale = 360.0 / points_count
		var points_scale = time_scale * .8
		var height = 15.0
		
		var points: PackedVector2Array
		for time: int in points_count:
			points.append(Vector2((time - points_count / 2.0) * points_scale, sin(deg_to_rad(time * time_scale)) * height))
		drawing_res.set_points(points)
		
		drawing_node.set_drawing_res(drawing_res)
		drawing_node.queue_redraw()
		
		await viewport.get_tree().create_timer(.1).timeout
		if is_instance_valid(viewport):
			viewport.get_texture().get_image().save_jpg(get_brush_thumbnail_path())
			# Note: saving image was made many times sometimes in the same Time
			# I want to fix it in future, because the performance is Bad in this case.
	)
	
	return viewport_container



func get_points_size() -> int:
	return points.size()

func get_max_index() -> int:
	return get_points_size() - 1

func is_max_index(index: int) -> bool:
	return index == get_max_index()

func get_points() -> PackedVector2Array:
	return points

func set_points(_points: PackedVector2Array, emit_changes: bool = true) -> void:
	points = _points
	if emit_changes:
		points_changed.emit()

func get_drawn_entities() -> Array[DrawnEntityRes]:
	return drawn_entities

func set_drawn_entities(new_drawn_entities: Array[DrawnEntityRes]) -> void:
	drawn_entities = new_drawn_entities

func get_is_brush() -> bool:
	return is_brush

func set_is_brush(new_is_brush: bool) -> void:
	is_brush = new_is_brush


func add_point(point: Vector2, emit_changes: bool = true) -> void:
	if points.size() and points[-1] == point: return
	points.append(point)
	if emit_changes:
		points_changed.emit()

func move_point(point_index: int, new_pos: Vector2, move_x: bool, move_y: bool) -> void:
	if move_x: points[point_index].x = new_pos.x
	if move_y: points[point_index].y = new_pos.y

func rotate_point(point_index: int, degrees: float, center: Vector2) -> void:
	var point = points[point_index]
	var angle_rad = deg_to_rad(degrees)
	var offset = point - center
	var rotated = Vector2(
		offset.x * cos(angle_rad) - offset.y * sin(angle_rad),
		offset.x * sin(angle_rad) + offset.y * cos(angle_rad)
	)
	points[point_index] = center + rotated

func scale_point(point_index: int, scale_time: float, center: Vector2, scale_x: bool, scale_y: bool) -> void:
	var point = points[point_index]
	var offset = point - center
	var scaled_offset = offset * scale_time
	var new_pos = center + scaled_offset
	if scale_x: points[point_index].x = new_pos.x
	if scale_y: points[point_index].y = new_pos.y

func expand_point_radius(point_index: int, expand_time: float) -> void:
	is_width_free = true
	if point_index < points.size() - 1:
		baked_width[point_index] *= expand_time

func desolve_points(index_from: int, index_to: int, emit_changes: bool = true) -> int: # Returns Remove Times
	var times = index_to - index_from - 1
	for time: int in times:
		points.remove_at(index_from + 1)
	if emit_changes: points_changed.emit()
	return times

func insert_points(index_from: int, new_points: PackedVector2Array, emit_changes: bool = true) -> int: # Return Insert Times
	var points_size: int = new_points.size()
	for index: int in points_size:
		var point = new_points[index]
		points.insert(index_from + index, point)
	if emit_changes: points_changed.emit()
	return points_size



func get_draw_line() -> bool:
	return draw_line

func get_draw_fill() -> bool:
	return draw_fill

func get_use_color_range() -> bool:
	return use_color_range

func get_cap_begin_type() -> int:
	return cap_begin_type

func get_cap_end_type() -> int:
	return cap_end_type


func bake_width() -> Array[float]:
	
	var result: Array[float]
	
	var points_size = points.size()
	
	var dist_passed: float
	var dist_max: float
	
	var latest_point = null
	
	for point: Vector2 in points:
		if latest_point:
			dist_max += point.distance_to(latest_point)
		latest_point = point
	
	for time: int in points_size:
		if time >= points_size - 1:
			break
		
		var curr_width = main_width
		
		var ratio = float(time) / points_size
		var a_to_b_dist = points[time].distance_to(points[time + 1])
		
		match width_curve_range_type:
			0:
				dist_passed += a_to_b_dist
				if ratio < .5: curr_width *= sample_curve(width_begin_curve, dist_passed / width_begin_dist)
				else: curr_width *= sample_curve(width_end_curve, (dist_max - dist_passed) / width_end_dist)
			1:
				var ratio_doubled = ratio * 2.0
				if ratio < .5: curr_width *= sample_curve(width_begin_curve, ratio_doubled)
				else: curr_width *= sample_curve(width_end_curve, 1.0 - (ratio_doubled - 1.0))
		result.append(curr_width)
	
	return result


func sample_curve(curve: Curve, offset: float) -> float:
	if curve != null:
		return curve.sample(offset)
	return 1.0



func get_center_point() -> Vector2:
	return center_point


func entity() -> DrawnEntityRes:
	var drawn_entity:= DrawnEntityRes.new()
	drawn_entities.append(drawn_entity)
	return drawn_entity

func clear_entities() -> void:
	drawn_entities.clear()
	entities_changed.emit()



# Made by AI
func erase(cond_func: Callable) -> void:
	var points_to_remove: Array[int] = []
	
	# جمع فهارس النقاط المراد حذفها
	for index: int in points.size():
		var point = points[index]
		if cond_func.call(self, index, point):
			points_to_remove.append(index)
	
	if points_to_remove.is_empty():
		return
	
	# إذا كانت النقاط المحذوفة متتالية، قسم الخط
	if is_continuous_segment(points_to_remove):
		var first_removed = points_to_remove[0]
		var last_removed = points_to_remove[-1]
		
		# الجزء الأيمن (بعد المنطقة المحذوفة)
		if last_removed + 1 < points.size():
			var right_slice = points.slice(last_removed + 1)
			if right_slice.size() > 1:
				sliced.emit(right_slice)
		
		# قطع النقاط من المنطقة المحذوفة
		if first_removed > 0:
			points.resize(first_removed)
		else:
			points.clear()
	else:
		# إذا كانت النقاط متفرقة، احذفها من الخلف للأمام
		points_to_remove.reverse()
		for index in points_to_remove:
			points.remove_at(index)
	
	points_changed.emit()

# Made by AI
# دالة مساعدة للتحقق من تتالي النقاط المحذوفة
func is_continuous_segment(indices: Array[int]) -> bool:
	if indices.size() <= 1:
		return true
	
	for i in range(1, indices.size()):
		if indices[i] != indices[i-1] + 1:
			return false
	
	return true





func on_res_changed() -> void:
	if not is_width_free:
		baked_width = bake_width()

func on_points_changed() -> void:
	# Get the Center Point
	var total: Vector2
	for point in points:
		total += point
	center_point = total / points.size()
	# Bake Width for Each Point and store at baked_width
	if not is_width_free:
		baked_width = bake_width()




func get_brush_thumbnail_path() -> String:
	return ProjectServer.brush_thumbnails_path + "/" + brush_name + ".jpeg"
