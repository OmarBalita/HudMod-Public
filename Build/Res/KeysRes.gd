class_name KeysRes extends Resource

signal keys_changed()

@export var keys: Dictionary[float, Dictionary]
# Example: {"x_pos": {"y_val": float, "left_pos": Vector2(), "left_pos": Vector2()}}

@export var domain: float
@export var min_val: float
@export var max_val: float

enum InterpolationType {
	LINEAR,
	CUBIC_CURVE
}



func get_keys() -> Dictionary[float, Dictionary]:
	return keys

func get_custom_keys(function: Callable) -> Dictionary[float, Dictionary]:
	var custom_keys: Dictionary[float, Dictionary]
	for x_pos: float in keys:
		var info = keys.get(x_pos)
		if function.call(x_pos, info) == true:
			custom_keys[x_pos] = info
	return custom_keys

func get_right_neighbor_key_pos(x_pos: float) -> Variant:
	var keys_keys = keys.keys()
	var right_index = keys_keys.find(x_pos) + 1
	if right_index <= keys_keys.size() - 1:
		return keys_keys[right_index]
	return null

func get_left_neighbor_key_pos(x_pos: float) -> Variant:
	var keys_keys = keys.keys()
	var left_index = keys_keys.find(x_pos) - 1
	if left_index >= 0:
		return keys_keys[left_index]
	return null


func get_custom_handles(function: Callable) -> Array[Dictionary]:
	var custom_handles: Array[Dictionary]
	for x_pos: float in keys:
		var info = keys.get(x_pos)
		var key_coord = Vector2(x_pos, info.y_val)
		var in_handle = info.in
		var out_handle = info.out
		if function.call(key_coord, in_handle, 0): custom_handles.append(_get_handle_dict(key_coord, in_handle, 0))
		if function.call(key_coord, out_handle, 1): custom_handles.append(_get_handle_dict(key_coord, out_handle, 1))
	return custom_handles

func _get_handle_dict(key_coord: Vector2, handle: Vector2, type: int, interpolation_type: int = 0) -> Dictionary:
	return {"key_coord": key_coord, "coord": handle, "type": type, "out_type": interpolation_type, "is_keeped": keys.get(key_coord.x).handles_keeped}

func set_keys(new_keys: Dictionary[float, Dictionary]) -> void:
	keys = new_keys
	keys.sort()
	keys_changed.emit()

func clear_keys() -> void:
	keys.clear()

func add_key(x_pos: float, y_val: float, in_handle: Vector2 = Vector2(-1.0, .0), out_handle: Vector2 = Vector2(1.0, .0), out_interpolation_type: int = 1, is_keeped: bool = true) -> Dictionary[float, Dictionary]:
	x_pos = clamp(x_pos, .0, domain)
	y_val = clamp(y_val, min_val, max_val)
	if keys.has(x_pos):
		return {}
	var key: Dictionary[float, Dictionary] = {x_pos: {
		"y_val": y_val,
		"in": in_handle,
		"out": out_handle,
		"out_type": out_interpolation_type,
		"handles_keeped": is_keeped,
	}}
	keys.merge(key)
	keys.sort()
	keys_changed.emit()
	return key

func remove_key(x_pos: float) -> void:
	keys.erase(x_pos)
	keys_changed.emit()

func move_key(from_x_pos: float, to_x_pos: float, to_y_val: float) -> Dictionary[float, Dictionary]:
	if from_x_pos != to_x_pos and keys.has(to_x_pos):
		return {}
	var info = keys.get(from_x_pos)
	remove_key(from_x_pos)
	var key = add_key(to_x_pos, to_y_val, info.in, info.out, info.out_type, info.handles_keeped)
	keys.sort()
	return key

func move_handle(key_xpos: float, to_coord: Vector2, handle_type: int) -> Dictionary:
	var info = keys.get(key_xpos)
	match handle_type:
		0: info.in = Vector2(clamp(to_coord.x, -INF, .0), to_coord.y)
		1: info.out = Vector2(clamp(to_coord.x, .0, INF), to_coord.y)
	return _get_handle_dict(Vector2(key_xpos, get_key_val(key_xpos)), to_coord, handle_type)

func get_key_val(x_pos: float) -> float:
	return keys.get(x_pos).y_val


#Made by ChatGPT, Edited by Omar TOP
func sample(offset: float) -> float:
	
	var keys_keys = keys.keys()
	var keys_size = keys.size()
	
	match keys_size:
		0:
			return .0
		1:
			return keys.values()[0].y_val
		_:
			
			var min_xpos = keys_keys.min()
			var max_xpos = keys_keys.max()
			
			if offset < min_xpos:
				return get_key_val(min_xpos)
			elif offset > max_xpos:
				return get_key_val(max_xpos)
			else:
				
				var key1: Dictionary
				var key2: Dictionary
				
				for index: int in keys_size:
					if index <= keys_size - 2:
						var key1_xpos = keys.keys()[index]
						var key2_xpos = keys.keys()[index + 1]
						if offset >= key1_xpos and offset <= key2_xpos:
							key1 = _get_sample_format(key1_xpos)
							key2 = _get_sample_format(key2_xpos)
							break
				
				# Cubic Bezier interpolation
				var t = (offset - key1.x_pos) / (key2.x_pos - key1.x_pos)
				var out_type = key1.out_type
				
				match out_type:
					InterpolationType.LINEAR:
						return lerp(key1.y_val, key2.y_val, t)
					InterpolationType.CUBIC_CURVE:
						var p0 = Vector2(key1.x_pos, key1.y_val)
						var p1 = Vector2(key1.x_pos + key1.out.x, key1.y_val - key1.out.y)
						var p2 = Vector2(key2.x_pos + key2.in.x, key2.y_val - key2.in.y)
						var p3 = Vector2(key2.x_pos, key2.y_val)
						return cubic_bezier(t, p0, p1, p2, p3).y
				
				return .0



func ease_in_out(t: float) -> float:
	if t < 0.5: return 2 * t * t
	else: return 1 - pow(-2 * t + 2, 2) / 2


func cubic_bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	var u = 1.0 - t
	var tt = t * t
	var uu = u * u
	var uuu = uu * u
	var ttt = tt * t
	return uuu * p0 + 3 * uu * t * p1 + 3 * u * tt * p2 + ttt * p3


func _get_sample_format(x_pos: float) -> Dictionary:
	var result: Dictionary = keys.get(x_pos).merged({"x_pos": x_pos})
	return result









