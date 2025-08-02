class_name GDDrawingRes extends Resource

signal points_changed()
signal entities_changed()
signal sliced(right_slice_points: Array[Vector2])

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

@export var points: Array[Vector2]
@export var drawn_entities: Array[Dictionary]

@export var layer: int = 1

@export_group("Default Properties")
@export var draw_line: bool = true
@export var draw_fill: bool = false
@export var antialised: bool = true

@export_subgroup("Color")
@export var color_line: Color = Color.WHITE
@export var color_fill: Color = Color.GRAY
@export var color_range: Gradient

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
@export var cap_begin_scale: float = 1.0:
	get: return cap_begin_scale / cap_begin_type
@export var cap_end_scale: float = 1.0:
	get: return cap_end_scale / cap_end_type

var center_point: Vector2


func _init() -> void:
	points_changed.connect(on_points_changed)


func get_points() -> Array[Vector2]:
	return points

func set_points(_points: Array[Vector2]) -> void:
	points = _points
	points_changed.emit()

func add_point(point: Vector2) -> void:
	if points.back() == point:
		return
	points.append(point)
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



func entity_line(offset:= Vector2.ZERO, dist: int = 1, range = null, custom_color = null, custom_width = null, custom_antialiased = null) -> void:
	entity({"line": get_base_entity_properties(offset, dist, 0, range, custom_color, custom_width, custom_antialiased)})

func entity_dashed_line(dash: float = 2.0, offset:= Vector2.ZERO, dist: int = 1, range = null, custom_color = null, custom_width = null, custom_antialiased = null) -> void:
	entity({"dashed_line": get_base_entity_properties(offset, dist, 0, range, custom_color, custom_width, custom_antialiased).merged({"dash": dash})})

func entity_v_dashed_line(dash_size: float = 2.0, offset:= Vector2.ZERO, dist: int = 1, range = null, custom_color = null, custom_width = null, custom_antialiased = null) -> void:
	var base_properties = get_base_entity_properties(offset, dist, 0, range, custom_color, custom_width, custom_antialiased)
	entity({"v_dashed_line": base_properties.merged({"dash_size": dash_size})})

func entity_rect(rect_size: Vector2 = Vector2.ONE, filled: bool = false, width_scale: float = 1.0, offset:= Vector2.ZERO, dist: int = 1, dist_mode: DistMode = 0, range = null, custom_color = null, custom_width = null, custom_antialiased = null) -> void:
	var base_properties = get_base_entity_properties(offset, dist, dist_mode, range, custom_color, custom_width, custom_antialiased)
	entity({"rect": base_properties.merged({"rect_size": rect_size, "filled": filled, "width_scale": width_scale})})

func entity_circle(filled: bool = false, width_scale: float = -1.0, offset:= Vector2.ZERO, dist: int = 1, dist_mode: DistMode = 0, range = null, custom_color = null, custom_width = null, custom_antialiased = null) -> void:
	var base_properties = get_base_entity_properties(offset, dist, dist_mode, range, custom_color, custom_width, custom_antialiased)
	entity({"circle": base_properties.merged({"filled": filled, "width_scale": width_scale})})

func entity_arc(start_angle: float = 0, end_angle: float = TAU, points_count: float = 8, width_scale: float = -1.0, offset:= Vector2.ZERO, dist: int = 1, dist_mode: DistMode = 0, range = null, custom_color = null, custom_width = null, custom_antialiased = null) -> void:
	var base_properties = get_base_entity_properties(offset, dist, dist_mode, range, custom_color, custom_width, custom_antialiased)
	entity({"arc": base_properties.merged({"start_angle": start_angle, "end_angle": end_angle, "points_count": points_count, "width_scale": width_scale})})

func entity_mesh(mesh: Mesh = null, texture: Texture2D = null, rotation: float = .0, scale: Vector2 = Vector2.ONE, skew: float = .0, offset:= Vector2.ZERO, dist: int = 1, dist_mode: DistMode = 0, range = null, custom_color = null, custom_width = null, custom_antialiased = null) -> void:
	var base_properties = get_base_entity_properties(offset, dist, dist_mode, range, custom_color, custom_width, custom_antialiased)
	entity({"mesh": base_properties.merged({"mesh": mesh, "texture": texture, "rotation": rotation, "scale": scale, "skew": skew})})

func entity_texture(texture: Texture2D = null, offset:= Vector2.ZERO, dist: int = 1, dist_mode: DistMode = 0, range = null, custom_color = null, custom_width = null, custom_antialiased = null) -> void:
	entity({"texture": get_base_entity_properties(offset, dist, dist_mode, range, custom_color, custom_width, custom_antialiased).merged({"texture": texture})})

func entity(entity: Dictionary) -> void:
	drawn_entities.append(entity)

func get_base_entity_properties(offset, dist, dist_mode, range, custom_color, custom_width, custom_antialiased) -> Dictionary:
	if range == null:
		range = [0, 1]
	return {"offset": offset, "dist": dist, "range": range, "dist_mode": dist_mode, "custom_color": custom_color, "custom_width": custom_width, "custom_antialiased": custom_antialiased}

func clear_entities() -> void:
	drawn_entities.clear()
	entities_changed.emit()


# Made by AI
func erase(pos: Vector2, eraser_scale: float) -> void:
	var points_to_remove: Array[int] = []
	
	# جمع فهارس النقاط المراد حذفها
	for index: int in points.size():
		var point = points[index]
		if point.distance_to(pos) <= eraser_scale:
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



func on_points_changed() -> void:
	# Get the Center Point
	var total: Vector2
	for point in points:
		total += point
	center_point = total / points.size()
	# Bake Width for Each Point and store at baked_width
	if not is_width_free:
		baked_width = bake_width()
















