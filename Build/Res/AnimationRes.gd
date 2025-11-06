class_name AnimationRes extends Resource

enum InterpolationType {
	INTERMITTENT,
	LINEAR,
	CUBIC_BEZIER_CURVE,
	LINEAR_INT,
	CUBIC_BEZIER_CURVE_INT
}

var interpolation_indexer: Dictionary[int, Dictionary] = {
	1: {"t": [4, 5, 6, 7], "m": lerp},
	2: {"t": [4, 5, 6, 7], "m": _interpolate_cubic_bezier_curve},
	3: {"t": [3], "m": _interpolate_linear_integer},
	4: {"t": [3], "m": _interpolate_cubic_bezier_curve_integer},
	0: {"t": [1, 2, 3, 4, 5, 6, 7, 8], "m": _interpolate_intermittent}
}

@export var value_type: int = -1:
	set(val):
		value_type = val
		var possible_types: Array[int] = get_possible_interpolation_types()
		if not possible_types.is_empty():
			interpolation_type = possible_types[0]

@export var interpolation_type: InterpolationType = 1:
	set(val):
		if val not in get_possible_interpolation_types(): return
		interpolation_type = val
		interpolation_func = interpolation_indexer[val].m
@export var keys: Dictionary[float, Variant] # Key as frame: int, Val: Variant
# Values should be: bool, int, float, Vector2, Vector3, Color

var interpolation_func: Callable = _interpolate_linear

func _init(_value_type: int) -> void:
	value_type = _value_type

func get_interpolation_type() -> InterpolationType:
	return interpolation_type

func set_interpolation_type(new_val: InterpolationType) -> void:
	interpolation_type = new_val

func get_keys() -> Dictionary[float, Variant]:
	return keys

func set_keys(new_keys: Dictionary[float, Variant]) -> void:
	keys = new_keys
	keys.sort()

func has_key(frame: float) -> bool:
	return keys.has(frame)

func add_key(frame: float, val: Variant) -> void:
	keys[frame] = val
	keys.sort()

func remove_key(frame: float) -> void:
	keys.erase(frame)

func get_key(frame: float) -> Variant:
	return keys[frame]


func get_possible_interpolation_types() -> Array[int]:
	var possible_types: Array[int]
	for type: int in interpolation_indexer:
		if interpolation_indexer[type].t.has(value_type):
			possible_types.append(type)
	return possible_types


func sample(frame: float) -> Variant:
	var min_xpos: float = keys.keys().min()
	var max_xpos: float = keys.keys().max()
	if frame < min_xpos:
		return get_key(min_xpos)
	elif frame >= max_xpos:
		return get_key(max_xpos)
	else:
		var domain: Variant = _get_domain(frame)
		var a: Variant = get_key(domain.x)
		var b: Variant = get_key(domain.y)
		var t: float = (frame - domain.x) / (domain.y - domain.x)
		return interpolation_func.call(a, b, t)

## Returns the domain as Vector2 if it possible, else return null
func _get_domain(frame: float) -> Variant:
	if frame > -1:
		var frames: Array[float] = keys.keys()
		for index: int in keys.size() - 1:
			var key1_xpos: float = frames.get(index)
			var key2_xpos: float = frames.get(index + 1)
			if frame >= key1_xpos and frame < key2_xpos:
				return Vector2(key1_xpos, key2_xpos) # x: key_from; y: key_to
	return null

func _interpolate_intermittent(a: Variant, b: Variant, t: float) -> Variant:
	return a

func _interpolate_linear(a: Variant, b: Variant, t: float) -> Variant:
	return a + (b - a) * t

func _interpolate_linear_integer(a: int, b: int, t: float) -> int:
	return roundi(lerp(a, b, t))

func _interpolate_cubic_bezier_curve(a: Variant, b: Variant, t: float) -> Variant:
	return null

func _interpolate_cubic_bezier_curve_integer(a: Variant, b: Variant, t: float) -> int:
	return 0

