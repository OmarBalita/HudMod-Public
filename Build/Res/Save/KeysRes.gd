class_name KeysRes extends Resource

signal keys_changed()

@export var keys: Dictionary[float, Dictionary]
# Example:
# {"x_pos": {"y_val": float, "left_pos": Vector2(), "left_pos": Vector2()}}

# Set Get Functions

func get_keys() -> Dictionary[float, Dictionary]:
	return keys

func get_custom_keys(function: Callable) -> Dictionary[float, Dictionary]:
	var custom_keys: Dictionary[float, Dictionary]
	for x_pos: float in keys:
		var info = keys.get(x_pos)
		if function.call(x_pos, info) == true:
			custom_keys[x_pos] = info
	return custom_keys

func set_keys(new_keys: Dictionary[float, Dictionary]) -> void:
	keys = new_keys
	keys.sort()
	keys_changed.emit()

func add_key(x_pos: float, y_val: float) -> void:
	if keys.has(x_pos):
		return
	keys[x_pos] = {
		"y_val": y_val,
		"left_pos": Vector2.ZERO,
		"right_pos": Vector2.ZERO
	}
	keys.sort()
	keys_changed.emit()

func remove_key(x_pos: float) -> void:
	keys.erase(x_pos)
	keys_changed.emit()

func move_key(from_x_pos: float, to_x_pos: float, to_y_val: float) -> void:
	if keys.has(to_x_pos):
		return
	add_key(to_x_pos, to_y_val)
	remove_key(from_x_pos)
	keys.sort()




#func cubic_bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	#var u = 1.0 - t
	#var tt = t * t
	#var uu = u * u
	#var uuu = uu * u
	#var ttt = tt * t
	#return uuu * p0 + 3 * uu * t * p1 + 3 * u * tt * p2 + ttt * p3

