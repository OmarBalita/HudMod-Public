class_name AnimationRes extends Resource

static var funcs_indexer: Dictionary[Variant.Type, Dictionary] = {
	TYPE_INT: {s=&"sample_int", a=&"add_key_int", g=&"get_key_int", p=1},
	TYPE_FLOAT: {s=&"sample_float", a=&"add_key_float", g=&"get_key_float", p=1},
	TYPE_VECTOR2: {s=&"sample_vec2", a=&"add_key_vec2", g=&"get_key_vec2", p=2},
	TYPE_VECTOR3: {s=&"sample_vec3", a=&"add_key_vec3", g=&"get_key_vec3", p=3},
	TYPE_VECTOR4: {s=&"sample_vec4", a=&"add_key_vec4", g=&"get_key_vec4", p=4},
	TYPE_COLOR: {s=&"sample_color", a=&"add_key_color", g=&"get_key_color", p=4}
}

@export var value_type: int = -1:
	set(val):
		value_type = val
		update_funcs()
@export var profiles: Array[CurveProfile]

var sample_func: Callable
var add_key_func: Callable
var get_key_func: Callable

func get_value_type() -> int: return value_type
func set_value_type(new_val: int) -> void: value_type = new_val

func get_profiles() -> Array[CurveProfile]: return profiles
func set_profiles(new_val: Array[CurveProfile]) -> void: profiles = new_val

func update_funcs() -> void:
	if funcs_indexer.has(value_type):
		var index_info: Dictionary = funcs_indexer[value_type]
		sample_func = Callable(self, index_info.s)
		add_key_func = Callable(self, index_info.a)
		get_key_func = Callable(self, index_info.g)
	else:
		sample_func = sample_constant
		add_key_func = add_key_constant
		get_key_func = get_key_constant

func update_profiles() -> void:
	var profiles_size: int = 1
	if funcs_indexer.has(value_type):
		profiles_size = funcs_indexer[value_type].p
	for index: int in profiles_size:
		profiles.append(CurveProfile.new_curve_profile({} as Dictionary[int, CurveKey]))

func duplicate_anim_res() -> AnimationRes:
	var dupl_anim_res:= duplicate()
	var new_profiles: Array[CurveProfile]
	for profile: CurveProfile in profiles:
		var new_profile: CurveProfile = profile.duplicate_profile()
		new_profiles.append(new_profile)
	dupl_anim_res.profiles = new_profiles
	return dupl_anim_res


func get_profile(index: int) -> CurveProfile:
	return profiles[index]

func profile_sample(index: int, x: int) -> float:
	return profiles[index].sample_func.call(x)

func profile_add_key(index: int, x: int, value: float) -> void:
	profiles[index].add_key(x, CurveKey.new_curve_key(value))

func profile_remove_key(index: int, x: int) -> void:
	profiles[index].remove_key(x)

func profile_get_curve_key(index: int, x: int) -> CurveKey:
	return profiles[index].keys[x]

func profile_get_key(index: int, x: int) -> float:
	return profile_get_curve_key(index, x).value

func profile_has_key(index: int, x: int) -> int:
	return profiles[index].keys.has(x)


func sample(x: int) -> Variant:
	return sample_func.call(x)

func add_key(x: int, value: Variant) -> void:
	add_key_func.call(x, value)

func remove_key(x: int) -> void:
	for profile: CurveProfile in profiles:
		profile.remove_key(x)

func get_key(x: int) -> Variant:
	return get_key_func.call(x)

func has_key(x: int) -> bool:
	for profile: CurveProfile in profiles:
		if profile.keys.has(x): return true
	return false

func has_any_key() -> bool:
	for profile: CurveProfile in profiles:
		if profile.keys.size(): return true
	return false

func sample_constant(x: int) -> Variant:
	return null

func sample_int(x: int) -> int:
	return round(profile_sample(0, x))

func sample_float(x: int) -> float:
	return profile_sample(0, x)

func sample_vec2(x: int) -> Vector2:
	return Vector2(profile_sample(0, x), profile_sample(1, x))

func sample_vec3(x: int) -> Vector3:
	return Vector3(profile_sample(0, x), profile_sample(1, x), profile_sample(2, x))

func sample_vec4(x: int) -> Vector4:
	return Vector4(
		profile_sample(0, x),
		profile_sample(1, x),
		profile_sample(2, x),
		profile_sample(3, x)
	)

func sample_color(x: int) -> Color:
	return Color(
		profile_sample(0, x),
		profile_sample(1, x),
		profile_sample(2, x),
		profile_sample(3, x)
	)

func add_key_constant(x: int, value: Variant) -> void:
	pass

func add_key_int(x: int, value: int) -> void:
	profile_add_key(0, x, value)

func add_key_float(x: int, value: float) -> void:
	profile_add_key(0, x, value)

func add_key_vec2(x: int, value: Vector2) -> void:
	profile_add_key(0, x, value.x)
	profile_add_key(1, x, value.y)

func add_key_vec3(x: int, value: Vector3) -> void:
	profile_add_key(0, x, value.x)
	profile_add_key(1, x, value.y)
	profile_add_key(2, x, value.z)

func add_key_vec4(x: int, value: Vector4) -> void:
	profile_add_key(0, x, value.x)
	profile_add_key(1, x, value.y)
	profile_add_key(2, x, value.z)
	profile_add_key(3, x, value.w)

func add_key_color(x: int, value: Color) -> void:
	profile_add_key(0, x, value.r)
	profile_add_key(1, x, value.g)
	profile_add_key(2, x, value.b)
	profile_add_key(3, x, value.a)


func get_key_constant(x: int) -> Variant:
	return null

func get_key_int(x: int) -> int:
	return round(profile_get_key(0, x))

func get_key_float(x: int) -> float:
	return profile_get_key(0, x)

func get_key_vec2(x: int) -> Vector2:
	return Vector2(profile_get_key(0, x), profile_get_key(1, x))

func get_key_vec3(x: int) -> Vector3:
	return Vector3(profile_get_key(0, x), profile_get_key(1, x), profile_get_key(2, x))

func get_key_vec4(x: int) -> Vector4:
	return Vector4(
		profile_get_key(0, x),
		profile_get_key(1, x),
		profile_get_key(2, x),
		profile_get_key(3, x)
	)

func get_key_color(x: int) -> Color:
	return Color(
		profile_get_key(0, x),
		profile_get_key(1, x),
		profile_get_key(2, x),
		profile_get_key(3, x)
	)


func find_minmax_vals() -> Vector2:
	var _min: float = INF
	var _max: float = -INF
	
	for profile: CurveProfile in profiles:
		var keys: Dictionary[int, CurveKey] = profile.keys
		
		if keys.is_empty():
			continue
		
		for key: int in keys:
			var value: float = keys[key].value
			_min = min(_min, value)
			_max = max(_max, value)
	
	return Vector2(_min, _max)



