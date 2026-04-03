@abstract class_name DrawShapeComponentRes extends ComponentRes

@export var just_store: bool

@export var pos: Vector2:
	set(val): pos = val; max_dirty()
@export var rot_deg: float:
	set(val): rot_deg = val; max_dirty()

@export var color: Color = Color.WHITE

@export var stroke_size: float
@export var stroke_color: Color = Color.WEB_GRAY

var dirty_level: int = 2 ## When dirty_level > 0: redraw, and when it > 1: gen_points
var all_points: Array[PackedVector2Array]

var draw_node: DrawShapeNode
var redraw_func: Callable

func set_prop(property_key: StringName, property_val: Variant) -> void:
	dirty_level = 1
	super(property_key, property_val)

func get_just_store() -> bool: return just_store
func set_just_store(new_val: bool) -> void: just_store = new_val
func get_pos() -> Vector2: return pos
func set_pos(new_val: Vector2) -> void: pos = new_val
func get_rot_deg() -> float: return rot_deg
func set_rot_deg(new_val: float) -> void: rot_deg = new_val
func get_color() -> Color: return color
func set_color(new_val: Color) -> void: color = new_val
func get_stroke_size() -> float: return stroke_size
func set_stroke_size(new_val: float) -> void: stroke_size = new_val
func get_stroke_color() -> Color: return color
func set_stroke_color(new_val: Color) -> void: color = new_val

func get_dirty_level() -> int: return dirty_level
func set_dirty_level(new_val: int) -> void: dirty_level = new_val
func min_dirty() -> void: dirty_level = 0
func mid_dirty() -> void: dirty_level = 1
func max_dirty() -> void: dirty_level = 2

func has_method_type() -> bool: return false

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var draw_cond: Array = [get.bind(&"just_store"), [false]]
	
	return {
		&"just_store": export(bool_args(just_store)),
		
		&"Transform": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"pos": export(vec2_args(pos)),
		&"rot_deg": export(float_args(rot_deg)),
		&"_Transform": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Fill": export_method(ExportMethodType.METHOD_ENTER_CATEGORY, [], draw_cond),
		&"color": export(color_args(color)),
		&"_Fill": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Stroke": export_method(ExportMethodType.METHOD_ENTER_CATEGORY, [], draw_cond),
		&"stroke_size": export(float_args(stroke_size, .0, INF, .01, .5)),
		&"stroke_color": export(color_args(stroke_color)),
		&"_Stroke": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	}

func emit_res_changed() -> void:
	super()
	
	if owner.curr_node: _init_draw_node()
	
	if enabled: all_points = _transform_points(_gen_points())
	else: all_points.clear()
	
	if draw_node: draw_node.queue_redraw()


func _init_draw_node() -> void:
	
	if owner is Shape2DClipRes:
		draw_node = owner.curr_node
		redraw_func = _redraw_none
	else:
		if draw_node:
			draw_node.queue_free()
		_spawn_draw_node()
		redraw_func = _redraw_node

func _spawn_draw_node() -> void:
	draw_node = DrawShapeChild.new()
	draw_node.use_parent_material = true
	draw_node.draw_shape_comp = self
	owner.curr_node.add_child(draw_node)

func _set_owner(new_owner: MediaClipRes) -> void:
	super(new_owner)
	if owner.curr_node:
		_init_draw_node()

func _enter() -> void:
	_init_draw_node()

func _process(frame: int) -> void:
	if dirty_level > 0:
		if dirty_level > 1:
			all_points = _transform_points(_gen_points())
		redraw_func.call()

func _exit() -> void:
	if draw_node:
		draw_node.queue_free()
		draw_node = null

func _gen_points() -> Array[PackedVector2Array]:
	return []

func _transform_points(all_points: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var angle_rad: float = deg_to_rad(rot_deg)
	
	for points: PackedVector2Array in all_points:
		for idx: int in points.size():
			var point: Vector2 = points[idx]
			point = point.rotated(angle_rad) + pos
			points[idx] = point
	
	return all_points

func _redraw_none() -> void:
	pass
func _redraw_node() -> void:
	draw_node.queue_redraw()
	dirty_level = 0


