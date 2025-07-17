class_name KeysRes extends Resource


@export var keys: Dictionary[int, Dictionary]
# Example:
# {frame_pos: {"pos": float, "left_pos": Vector2(), "left_pos": Vector2()}}


# Set Get Functions

func get_keys() -> Dictionary[int, Dictionary]:
	return keys

func set_keys(new_keys: Dictionary[int, Dictionary]) -> void:
	keys = new_keys



func add_key(frame_pos: int, pos: float) -> void:
	keys[frame_pos] = {
		"pos": pos,
		"left_pos": Vector2.ZERO,
		"right_pos": Vector2.ZERO
	}

#
#func cubic_bezier(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
	#var u = 1.0 - t
	#var tt = t * t
	#var uu = u * u
	#var uuu = uu * u
	#var ttt = tt * t
	#return uuu * p0 + 3 * uu * t * p1 + 3 * u * tt * p2 + ttt * p3
#
