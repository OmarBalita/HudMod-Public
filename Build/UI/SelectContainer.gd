class_name SelectContainer extends PanelContainer

class LocalPointInfo extends Object:
	var point_val: Variant
	var point_display_pos: Vector2
	
	func _init(_point_val: Variant, _point_display_pos: Vector2) -> void:
		point_val = _point_val
		point_display_pos = _point_display_pos

class GlobalPointInfo extends Object:
	var owner_as_object: Object
	var key: Variant
	var point_info: LocalPointInfo
	
	func _init(_owner_as_object: Object, _key: Variant, _point_info: LocalPointInfo) -> void:
		owner_as_object = _owner_as_object
		key = _key
		point_info = _point_info

@export_group("Control", "control")
@export_range(.01, 200.0) var control_close_distance: float = 20.0
@export_range(.1, 100.0) var control_drag_distance: float = 20.0
@export var control_use_selection_box: bool = false

var selectable_points_objects: Dictionary[Object, Dictionary]
# Key as int-index, Val as PointInfo
var selected_points: Dictionary[Object, Dictionary]
var focused_point: GlobalPointInfo

func add_selectable_object(object: Object, selectable_points: Dictionary[Variant, LocalPointInfo] = {}) -> void:
	selectable_points_objects[object] = selectable_points_objects

func delete_selectable_object(object: Object) -> void:
	selectable_points_objects.erase(object)


func _init() -> void:
	pass

func _gui_input(event: InputEvent) -> void:
	var mouse_pos: Vector2 = get_local_mouse_position()
	
	if event is InputEventMouseButton:
		
		match event.button_index:
			
			MOUSE_BUTTON_LEFT:
				if event.is_pressed():
					set_meta(&"press_pos", mouse_pos)
					set_meta(&"select_rect", Rect2(mouse_pos, Vector2.ZERO))
				else:
					var press_pos: Vector2 = get_meta(&"press_pos")
					var select_rect: Rect2 = get_meta(&"select_rect")
					
					var get_points_cond_func: Callable
					if press_pos.distance_to(mouse_pos) <= control_drag_distance:
						get_points_cond_func = get_points_close_distance_cond_func
					else:
						get_points_cond_func = get_points_inside_rect_cond_func
					
					var closed_points_info: Dictionary[StringName, Variant] = get_points_info_closed_to(get_points_cond_func, select_rect)
					var closed_points: Dictionary[Object, Dictionary] = closed_points_info.closed_points
					var target_point: GlobalPointInfo = closed_points_info.target_point
					
					remove_meta(&"press_pos")
					remove_meta(&"select_rect")
			
			MOUSE_BUTTON_RIGHT:
				pass
	
	elif event is InputEventMouseMotion:
		if has_meta(&"press_pos"):
			var press_pos: Vector2 = get_meta(&"press_pos")
			set_meta(&"select_rect", Rect2(press_pos, mouse_pos - press_pos))


func _draw() -> void:
	if control_use_selection_box:
		pass


func get_points_info_closed_to(cond: Callable, rect: Rect2) -> Dictionary[StringName, Variant]:
	var closed_points: Dictionary[Object, Dictionary]
	var target_point: GlobalPointInfo
	
	for object: Object in selectable_points_objects:
		var selectable_points: Dictionary[Variant, LocalPointInfo] = selectable_points_objects[object]
		closed_points[object] = {}
		
		for point_key: Variant in selectable_points:
			var point_info: LocalPointInfo = selectable_points[point_key]
			
			if cond.call(object, point_key, point_info, rect):
				
				closed_points[object][point_key] = point_info
				if selected_points.has(object) and selected_points[object].has(point_key):
					continue
				target_point = GlobalPointInfo.new(object, point_key, point_info)
	
	return {&"closed_points": closed_points, &"target_point": target_point}

func get_points_close_distance_cond_func(object: Object2DRes, point_key: Variant, point_info: LocalPointInfo, rect: Rect2) -> bool:
	return point_info.point_display_pos.distance_to(rect.position) <= control_close_distance

func get_points_inside_rect_cond_func(object: Object2DRes, point_key: Variant, point_info: LocalPointInfo, rect: Rect2) -> bool:
	return rect.has_point(point_info.point_display_pos)


