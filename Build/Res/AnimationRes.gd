class_name AnimationRes extends Resource

static var funcs_indexer: Dictionary[int, Dictionary] = {
	3: {s=&"sample_int", a=&"add_key_int", g=&"get_key_int", p=1},
	4: {s=&"sample_float", a=&"add_key_float", g=&"get_key_float", p=1},
	5: {s=&"sample_vec2", a=&"add_key_vec2", g=&"get_key_vec2", p=2},
	6: {s=&"sample_vec3", a=&"add_key_vec3", g=&"get_key_vec3", p=3},
	7: {s=&"sample_color", a=&"add_key_color", g=&"get_key_color", p=4},
	8: {s=&"sample_vec4", a=&"add_key_vec4", g=&"get_key_vec4", p=4},
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
		profiles.append(CurveProfile.new_profile_curve({} as Dictionary[float, CurveKey]))


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

func profile_sample(index: int, x: float) -> float:
	return profiles[index].sample_func.call(x)

func profile_add_key(index: int, x: float, value: float) -> void:
	profiles[index].add_key(x, CurveKey.new_curve_key(value))

func profile_remove_key(index: int, x: float) -> void:
	profiles[index].remove_key(x)

func profile_get_curve_key(index: int, x: float) -> CurveKey:
	return profiles[index].keys[x]

func profile_get_key(index: int, x: float) -> float:
	return profile_get_curve_key(index, x).value

func profile_has_key(index: int, x: float) -> bool:
	return profiles[index].keys.has(x)


func sample(x: float) -> Variant:
	return sample_func.call(x)

func add_key(x: float, value: Variant) -> void:
	add_key_func.call(x, value)

func remove_key(x: float) -> void:
	for profile: CurveProfile in profiles:
		profile.remove_key(x)

func get_key(x: float) -> Variant:
	return get_key_func.call(x)

func has_key(x: float) -> bool:
	for profile: CurveProfile in profiles:
		if profile.keys.has(x): return true
	return false

func has_any_key() -> bool:
	for profile: CurveProfile in profiles:
		if profile.keys.size(): return true
	return false

func sample_constant(x: float) -> Variant:
	return null

func sample_int(x: float) -> int:
	return round(profile_sample(0, x))

func sample_float(x: float) -> float:
	return profile_sample(0, x)

func sample_vec2(x: float) -> Vector2:
	return Vector2(profile_sample(0, x), profile_sample(1, x))

func sample_vec3(x: float) -> Vector3:
	return Vector3(profile_sample(0, x), profile_sample(1, x), profile_sample(2, x))

func sample_color(x: float) -> Color:
	return Color(
		profile_sample(0, x),
		profile_sample(1, x),
		profile_sample(2, x),
		profile_sample(3, x)
	)

func sample_vec4(x: float) -> Vector4:
	return Vector4(
		profile_sample(0, x),
		profile_sample(1, x),
		profile_sample(2, x),
		profile_sample(3, x)
	)


func add_key_constant(x: float, value: Variant) -> void:
	pass

func add_key_int(x: float, value: int) -> void:
	profile_add_key(0, x, value)

func add_key_float(x: float, value: float) -> void:
	profile_add_key(0, x, value)

func add_key_vec2(x: float, value: Vector2) -> void:
	profile_add_key(0, x, value.x)
	profile_add_key(1, x, value.y)

func add_key_vec3(x: float, value: Vector3) -> void:
	profile_add_key(0, x, value.x)
	profile_add_key(1, x, value.y)
	profile_add_key(2, x, value.z)

func add_key_color(x: float, value: Color) -> void:
	profile_add_key(0, x, value.r)
	profile_add_key(1, x, value.g)
	profile_add_key(2, x, value.b)
	profile_add_key(3, x, value.a)

func add_key_vec4(x: float, value: Vector4) -> void:
	profile_add_key(0, x, value.x)
	profile_add_key(1, x, value.y)
	profile_add_key(2, x, value.z)
	profile_add_key(3, x, value.w)


func get_key_constant(x: float) -> Variant:
	return null

func get_key_int(x: float) -> int:
	return round(profile_get_key(0, x))

func get_key_float(x: float) -> float:
	return profile_get_key(0, x)

func get_key_vec2(x: float) -> Vector2:
	return Vector2(profile_get_key(0, x), profile_get_key(1, x))

func get_key_vec3(x: float) -> Vector3:
	return Vector3(profile_get_key(0, x), profile_get_key(1, x), profile_get_key(2, x))

func get_key_color(x: float) -> Color:
	return Color(
		profile_get_key(0, x),
		profile_get_key(1, x),
		profile_get_key(2, x),
		profile_get_key(3, x)
	)

func get_key_vec4(x: float) -> Vector4:
	return Vector4(
		profile_get_key(0, x),
		profile_get_key(1, x),
		profile_get_key(2, x),
		profile_get_key(3, x)
	)

