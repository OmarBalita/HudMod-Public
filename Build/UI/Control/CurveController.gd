class_name CurveController extends ColorRect

enum KeysType {
	KEY_TYPE_VEC_1,
	KEY_TYPE_VEC_2,
	KEY_TYPE_VEC_3,
	KEY_TYPE_VEC_4,
	KEY_TYPE_VEC_5,
}

const KEYS_COLORS: Array[Color] = [
	Color.RED,
	Color.GREEN,
	Color.BLUE,
	Color.VIOLET,
	Color.YELLOW
]

@export var keys_type: KeysType = KeysType.KEY_TYPE_VEC_1:
	set(val):
		keys_type = val
		_update_keys_array()

@export_group("Range")
@export var min_val: float = -30.0
@export var max_val: float = 30.0
@export var min_domain: float = -30.0
@export var max_domain: float = 30.0

@export_group("Draw", "draw")
@export var draw_val_step: int = 15
@export var draw_domain_step: int = 15
@export var draw_x_snap_step: int = 5
@export var draw_y_snap_step: int = 5


@export_group("Theme")
@export_subgroup("Constant")
@export var key_close_distance: float = 2.5


var keys_array: Array[Dictionary]

var is_snapped: bool = false:
	set(val):
		if val != is_snapped:
			is_snapped = val
			queue_redraw()


func keys_get(keys_index: int) -> Dictionary[float, Variant]:
	return keys_array[keys_index]

func keys_set(keys_index: int, keys: Dictionary[float, Variant]) -> void:
	keys_array[keys_index] = keys

func keys_has(keys_index: int, x: float) -> bool:
	return keys_array[keys_index].has(x)

func keys_add(keys_index: int, x: float, y: Variant, redraw: bool = true) -> void:
	x = clamp(x, min_domain, max_domain)
	y = clamp(y, min_val, max_val)
	var keys:= keys_get(keys_index)
	keys[x] = y
	keys.sort()
	if redraw:
		queue_redraw()

func keys_delete(keys_index: int, x: float, redraw: bool = true) -> void:
	var keys:= keys_get(keys_index)
	keys.erase(x)
	keys.sort()
	if redraw:
		queue_redraw()

func keys_move(keys_index: int, from: Vector2, to: Vector2, redraw: bool = true) -> bool:
	from.x = clamp(from.x, min_domain, max_domain)
	to.x = clamp(to.x, min_domain, max_domain)
	var same_x:= from.x == to.x
	var has_key:= keys_has(keys_index, to.x)
	var can_move_to: bool = (not same_x and not has_key) or (same_x and has_key) or (to.x in [min_domain, max_domain])
	if can_move_to:
		keys_delete(keys_index, from.x, false)
		keys_add(keys_index, to.x, to.y, redraw)
	return can_move_to

func keys_merge(keys_index: int, new_keys: Dictionary[float, Variant]) -> void:
	var keys:= keys_get(keys_index)
	keys.merge(new_keys)
	keys.sort()
	queue_redraw()

func keys_find_custom(keys_index: int, method: Callable) -> Variant:
	var keys:= keys_get(keys_index)
	return keys.keys()[keys.keys().find_custom(method)]

func keys_find_closest(keys_index: int, to_coord: Vector2) -> Variant:
	var keys:= keys_get(keys_index)
	var result: Variant = null
	for key: float in keys:
		var val: Variant = keys[key]
		var coord:= Vector2(key, val)
		if coord.distance_to(to_coord) <= key_close_distance:
			result = coord
			break
	return result

func find_closest(to_coord: Vector2) -> Variant:
	var result: Variant = null
	for keys_index: int in keys_array.size():
		var index_result: Variant = keys_find_closest(keys_index, to_coord)
		if index_result is Vector2:
			result = index_result
			break
	return result


func get_coord_from_display_pos(pos: Vector2) -> Vector2:
	var coord:= Vector2(
		get_domain_from_display_pos(pos.x),
		get_val_from_display_pos(pos.y)
	)
	if is_snapped:
		coord = snapped(coord, Vector2(draw_x_snap_step, draw_y_snap_step))
	return coord

func get_display_pos_from_coord(coord: Vector2) -> Vector2:
	return Vector2(
		get_display_pos_from_domain(coord.x),
		get_display_pos_from_val(coord.y)
	)

func get_val_from_display_pos(pos: float) -> float:
	return min_val + pos * (max_val - min_val) / size.y

func get_display_pos_from_val(val_step: float) -> float:
	return (val_step - min_val) * (size.y / (max_val - min_val))

func get_domain_from_display_pos(pos: float) -> float:
	return min_domain + pos * (max_domain - min_domain) / size.x

func get_display_pos_from_domain(domain_step: float) -> float:
	return (domain_step - min_domain) * (size.x / (max_domain - min_domain))


func _init() -> void:
	_update_keys_array()
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("snap"): is_snapped = true
		elif event.is_action_released("snap"): is_snapped = false

func _gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouse:
		
		var mouse_pos: Vector2 = get_local_mouse_position()
		var coord: Vector2 = get_coord_from_display_pos(mouse_pos)
		
		if event is InputEventMouseButton:
			
			var finded_coord: Variant = find_closest(coord)
			if finded_coord != null:
				coord = finded_coord
			
			if event.is_pressed():
				match event.button_index:
					
					MOUSE_BUTTON_LEFT:
						
						keys_add(0, coord.x, coord.y)
						
						while true:
							var new_mouse_pos: Vector2 = get_local_mouse_position()
							var new_coord: Vector2 = get_coord_from_display_pos(mouse_pos)
							if mouse_pos != new_mouse_pos and keys_move(0, coord, new_coord):
								coord = new_coord
							mouse_pos = new_mouse_pos
							if Input.is_action_just_released(&"left_button"):
								break
							await get_tree().process_frame
					
					MOUSE_BUTTON_RIGHT:
						keys_delete(0, coord.x)
		
		elif event is InputEventMouseMotion:
			
			var curr_sample: Variant = CurveSampler

func _draw() -> void:
	
	var val_size: float = max_val - min_val
	var domain_size: float = max_domain - min_domain
	
	if is_snapped:
		var x_snap_steps_count: int = domain_size / draw_x_snap_step + 1
		var y_snap_steps_count: int = val_size / draw_y_snap_step + 1
		var snap_grid_color: Color = Color(Color.WHITE, .2)
		
		for snap_step: int in x_snap_steps_count:
			var x_pos:= get_display_pos_from_domain(min_domain + snap_step * draw_x_snap_step)
			draw_line(Vector2(x_pos, .0), Vector2(x_pos, size.y), snap_grid_color)
		
		for snap_step: int in y_snap_steps_count:
			var y_pos:= get_display_pos_from_val(min_val + snap_step * draw_y_snap_step)
			draw_line(Vector2(.0, y_pos), Vector2(size.x, y_pos), snap_grid_color)
	
	var val_steps_count: int = val_size / draw_val_step + 1
	var domain_steps_count: int = domain_size / draw_domain_step + 1
	
	for step: int in val_steps_count:
		var val_step: float = min_val + step * draw_val_step
		var y_pos: float = get_display_pos_from_val(val_step)
		draw_line(Vector2(.0, y_pos), Vector2(size.x, y_pos), Color.DIM_GRAY, 2.0)
	
	for step: float in domain_steps_count:
		var domain_step: float = min_domain + step * draw_domain_step
		var x_pos: float = get_display_pos_from_domain(domain_step)
		draw_line(Vector2(x_pos, .0), Vector2(x_pos, size.y), Color.DIM_GRAY, 2.0)
	
	for keys_index: int in keys_array.size():
		
		var keys: Dictionary[float, Variant] = keys_get(keys_index)
		var keys_keys: Array[float] = keys.keys()
		var keys_color: Color = KEYS_COLORS[keys_index]
		
		for index: int in range(0, keys.size() - 1):
			var key_a: float = keys_keys[index]
			var key_b: float = keys_keys[index + 1]
			
			var val_a: Variant = keys.get(key_a)
			var val_b: Variant = keys.get(key_b)
			
			var display_pos_a:= get_display_pos_from_coord(Vector2(key_a, val_a))
			var display_pos_b:= get_display_pos_from_coord(Vector2(key_b, val_b))
			
			draw_line(display_pos_a, display_pos_b, keys_color, 2.0)
			draw_key(display_pos_a)
		
		if keys.size():
			var front_pos:= get_display_pos_from_coord(Vector2(keys_keys.front(), keys.values().front()))
			var back_pos:= get_display_pos_from_coord(Vector2(keys_keys.back(), keys.values().back()))
			draw_line(Vector2(.0, front_pos.y), front_pos, keys_color, 2.0)
			draw_line(back_pos, Vector2(size.x, back_pos.y), keys_color, 2.0)
			draw_key(back_pos)
		else:
			var val_pos:= get_display_pos_from_val(0)
			draw_line(Vector2(.0, val_pos), Vector2(size.x, val_pos), keys_color, 2.0)

const KEY_SIZE:= Vector2(10.0, 10.0)
const KEY_SIZE_HALF:= KEY_SIZE / 2.0

func draw_key(pos: Vector2) -> void:
	var display_pos: Vector2 = pos
	var rect: Rect2 = Rect2(display_pos - KEY_SIZE_HALF, KEY_SIZE)
	
	draw_rect(rect, Color.WHITE, true)
	draw_rect(rect, Color.BLACK, false, 2.0)

func _update_keys_array() -> void:
	keys_array.clear()
	for time: int in keys_type + 1:
		keys_array.append({} as Dictionary[float, Variant])




