class_name CurveProfile extends UsableRes

signal key_added(x: float, curve_key: CurveKey)
signal key_removed(x: float)

static var interpolation_indexer: Dictionary[CurveKey.InterpolationMode, StringName] = {
	CurveKey.InterpolationMode.INTERPOLATION_MODE_CONSTANT: &"_interpolate_constant",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_LINEAR: &"_interpolate_linear",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_BEZIER_CURVE: &"_interpolate_cubic_bezier_curve",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_EASE_IN: &"_interpolate_ease_in",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_EASE_OUT: &"_interpolate_ease_out",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_EASE_IN_OUT: &"_interpolate_ease_in_out",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_EXPO_IN_OUT: &"_interpolate_expo_in_out",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_CIRC_IN_OUT: &"_interpolate_circ_in_out",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_CUBIC: &"_interpolate_cubic",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_QUART: &"_interpolate_quart",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_QUINT: &"_interpolate_quint",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_ELASTIC: &"_interpolate_elastic",
	CurveKey.InterpolationMode.INTERPOLATION_MODE_BOUNCE: &"_interpolate_bounce"
}

@export var keys: Dictionary[float, CurveKey]:
	set(val):
		keys = val
		update_profile()

@export var bakeable: bool:
	set(val):
		bakeable = val
		if val: sample_func = sample_baked
		else: sample_func = sample

@export var baked: Dictionary[float, float]

@export_group(&"Ctrlr Settings")
@export var ctrlr_min_val: float = .0
@export var ctrlr_max_val: float = 1.
@export var ctrlr_val_step: float = .01
@export var ctrlr_min_domain: float = .0
@export var ctrlr_max_domain: float = 256.
@export var ctrlr_domain_step: float = 1.

@export var ctrlr_zoom_min: float = .5
@export var ctrlr_zoom_max: float = 5.

@export var ctrlr_val_snap_step: Vector2 = Vector2(.1, .2)
@export var ctrlr_domain_snap_step: Vector2 = Vector2(1., 8.)

var keys_keys: Array

var sample_func: Callable = sample

static func preset_constant_line(min_val: float = .0, max_val: float = 1., val_step: float = .01, min_domain: float = .0, max_domain: float = 256., domain_step: float = 1.) -> CurveProfile:
	var profile: CurveProfile = new_profile_with_ctrlr_sett(min_val, max_val, val_step, min_domain, max_domain, domain_step)
	var middle_val: float = (profile.ctrlr_max_val + profile.ctrlr_min_val) / 2.
	profile.add_key(profile.ctrlr_min_domain, CurveKey.new_bezier_curve(middle_val))
	profile.add_key(profile.ctrlr_max_domain, CurveKey.new_bezier_curve(middle_val))
	return profile

static func preset_linear(min_val: float = .0, max_val: float = 1., val_step: float = .01, min_domain: float = .0, max_domain: float = 256., domain_step: float = 1.) -> CurveProfile:
	var profile: CurveProfile = new_profile_with_ctrlr_sett(min_val, max_val, val_step, min_domain, max_domain, domain_step)
	profile.add_key(profile.ctrlr_min_domain, CurveKey.new_bezier_curve(profile.ctrlr_min_val))
	profile.add_key(profile.ctrlr_max_domain, CurveKey.new_bezier_curve(profile.ctrlr_max_val))
	return profile

static func new_profile_with_ctrlr_sett(min_val: float = .0, max_val: float = 1., val_step: float = .01, min_domain: float = .0, max_domain: float = 256., domain_step: float = 1.,
	zoom_min: float = .5, zoom_max: float = 5., val_snap_step: Vector2 = Vector2(.1, .2), domain_snap_step: Vector2 = Vector2(1., 8.)) -> CurveProfile:
	
	var curve_profile:= CurveProfile.new()
	ObjectServer.describe(curve_profile, {
		ctrlr_min_val = min_val, ctrlr_max_val = max_val, ctrlr_val_step = val_step,
		ctrlr_min_domain = min_domain, ctrlr_max_domain = max_domain, ctrlr_domain_step = domain_step,
		
		ctrlr_zoom_min = zoom_min, ctrlr_zoom_max = zoom_max,
		
		ctrlr_domain_snap_step = domain_snap_step,
		ctrlr_val_snap_step = val_snap_step,
	})
	return curve_profile


func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var curve_ctrlr:= CurveController.new()
	curve_ctrlr.curves_profiles = [self]
	
	ObjectServer.describe(curve_ctrlr, {
		min_val = ctrlr_min_val, max_val = ctrlr_max_val, val_step = ctrlr_val_step,
		min_domain = ctrlr_min_domain, max_domain = ctrlr_max_domain, domain_step = ctrlr_domain_step,
		
		zoom_min = ctrlr_zoom_min, zoom_max = ctrlr_zoom_max,
		
		draw_x_small_step = ctrlr_domain_snap_step.x, draw_x_big_step = ctrlr_domain_snap_step.y,
		draw_y_small_step = ctrlr_val_snap_step.x, draw_y_big_step = ctrlr_val_snap_step.y
	})
	
	curve_ctrlr.custom_minimum_size.y = 220.
	
	return {
		&"curve_ctrlr": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, [curve_ctrlr]),
	}

static func new_profile_curve(_keys: Dictionary[float, CurveKey], _bakeable: bool = false) -> CurveProfile:
	#_keys: Dictionary[float, CurveKey], _bakeable: bool = false
	var curve_profile:= CurveProfile.new()
	curve_profile.keys = _keys
	curve_profile.bakeable = _bakeable
	curve_profile.update_profile()
	return curve_profile

func get_key(x: float) -> CurveKey:
	return keys.get(x)

func add_key(x: float, curve_key: CurveKey) -> void:
	if keys.has(x):
		var same_curve_key: CurveKey = keys[x]
		same_curve_key.value = curve_key.value
		curve_key = same_curve_key
	keys[x] = curve_key
	key_added.emit(x, curve_key)
	update_profile()

func remove_key(x: float) -> void:
	keys.erase(x)
	key_removed.emit(x)
	update_profile()

func sample(x: float) -> float:
	if not keys: return .0
	var min_xpos: float = keys_keys[0]
	var max_xpos: float = keys_keys[-1]
	if x < min_xpos:
		return get_key(min_xpos).value
	elif x >= max_xpos:
		return get_key(max_xpos).value
	else:
		var domain: Vector2 = _find_domain(x)
		var key_a: CurveKey = get_key(domain.x)
		var key_b: CurveKey = get_key(domain.y)
		var t: float = (x - domain.x) / (domain.y - domain.x)
		return key_a.interpolation_func.call(domain.x, domain.y, key_a, key_b, t)

func sample_baked(x: float) -> float:
	return baked[x]

func _find_domain(x: float) -> Vector2:
	var index: int = _find_domain_index(x)
	# نرجع Vector2 يحتوي على (زمن_البداية، زمن_النهاية)
	return Vector2(keys_keys[index], keys_keys[index + 1])

func _find_domain_index(x: float) -> int:
	# مصفوفة مفاتيح الزمن
	var low: int = 0
	var high: int = keys_keys.size() - 2 # نبحث عن النقطة "أ" بحيث تكون "ب" هي التالية لها
	
	var best_index: int = 0
	
	# الـ Binary Search لإيجاد الفاصل الزمني (Interval) الصحيح
	while low <= high:
		var mid: int = (low + high) / 2
		if keys_keys[mid] <= x:
			best_index = mid
			low = mid + 1
		else:
			high = mid - 1
	
	return best_index

func _solve_for_t(target_x: float, p0x: float, p1x: float, p2x: float, p3x: float) -> float:
	var t_min: float = .0
	var t_max: float = 1.0
	var t: float = .5
	
	# نستخدم 8 تكرارات من البحث الثنائي أولاً للاقتراب من المنطقة الصحيحة
	# هذا يضمن الاستقرار حتى لو كان المنحنى "يلتف"
	
	for i: int in 4:
		var x: float = bezier_interpolate(p0x, p1x, p2x, p3x, t)
		if x < target_x:
			t_min = t
		else:
			t_max = t
		t = (t_min + t_max) * .5
	
	# ثم نستخدم 4 تكرارات من طريقة نيوتن للدقة النهائية (اختياري)
	for i: int in 4:
		var dx: float = bezier_derivative(p0x, p1x, p2x, p3x, t)
		if abs(dx) < .0001: break
		var x: float = bezier_interpolate(p0x, p1x, p2x, p3x, t)
		t -= (x - target_x) / dx
		t = clamp(t, .0, 1.0)
	
	return t

func _interpolate_constant(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	return a.value

func _interpolate_linear(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	return lerp(a.value, b.value, t)

func _interpolate_cubic_bezier_curve(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	# النقاط الأربع التي تشكل منحنى البيزييه
	var p0:= Vector2(time_a, a.value)
	var p1:= p0 + a.right_control
	var p3:= Vector2(time_b, b.value)
	var p2:= p3 + b.left_control
	
	# t = t_linear
	# تذكر: t هو الزمن النسبي الذي تريده (مثلاً 0.5)
	# نحن بحاجة للبحث عن t_bezier التي تجعل x مساوياً للزمن المطلوب
	var target_x: float = lerp(time_a, time_b, t)
	var t_bezier: float = _solve_for_t(target_x, p0.x, p1.x, p2.x, p3.x)
	
	# الآن نستخدم t_bezier للحصول على الـ y الصحيح
	return bezier_interpolate(p0.y, p1.y, p2.y, p3.y, t_bezier)

func _interpolate_ease_in(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	return lerp(a.value, b.value, t * t)

func _interpolate_ease_out(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	var t_ratio: float = 1. - t
	var u:= 1. - t_ratio * t_ratio
	return lerp(a.value, b.value, u)

func _interpolate_ease_in_out(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	var u: float
	if t < 0.5: u = 2.0 * t * t
	else: u = 1.0 - pow(-2.0 * t + 2.0, 2.0) * 0.5
	return lerp(a.value, b.value, u)

func _interpolate_expo_in_out(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	var u: float
	if t < 0.5: u = pow(2.0, 20.0 * t - 10.0) * 0.5
	else: u = (2.0 - pow(2.0, -20.0 * t + 10.0)) * 0.5
	return lerp(a.value, b.value, u)

func _interpolate_circ_in_out(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	var u: float
	if t < 0.5: u = (1.0 - sqrt(1.0 - pow(2.0 * t, 2.0))) * 0.5
	else: u = (sqrt(1.0 - pow(-2.0 * t + 2.0, 2.0)) + 1.0) * 0.5
	return lerp(a.value, b.value, u)

func _interpolate_cubic(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	return lerp(a.value, b.value, t * t * t)

func _interpolate_quart(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	return lerp(a.value, b.value, t * t * t * t)

func _interpolate_quint(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	return lerp(a.value, b.value, pow(t, 5))

func _interpolate_elastic(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	var u: float
	if t == 0.0:
		u = 0.0
	elif t == 1.0:
		u = 1.0
	else:
		u = pow(2.0, -10.0 * t) * sin((10.0 * t - 0.75) * TAU / 3.0) + 1.0
	return lerp(a.value, b.value, u)

func _interpolate_bounce(time_a: float, time_b: float, a: CurveKey, b: CurveKey, t: float) -> float:
	var u: float
	if t < 1.0 / 2.75:
		u = 7.5625 * t * t
	elif t < 2.0 / 2.75:
		t -= 1.5 / 2.75
		u = 7.5625 * t * t + 0.75
	elif t < 2.5 / 2.75:
		t -= 2.25 / 2.75
		u = 7.5625 * t * t + 0.9375
	else:
		t -= 2.625 / 2.75
		u = 7.5625 * t * t + 0.984375
	return lerp(a.value, b.value, u)

func update_profile() -> void:
	keys.sort()
	keys_keys = keys.keys()
	
	var left_dir: Vector2 = Vector2.LEFT
	
	for index: int in keys.size():
		var key: float = keys_keys[index]
		var curve_key: CurveKey = keys[key]
		var coord: Vector2 = Vector2(key, curve_key.value)
		var right_dir: Vector2
		if index < keys_keys.size() - 1:
			var after_key: float = keys_keys[index + 1]
			right_dir = Vector2(after_key, keys[after_key].value) - coord
		else:
			right_dir = Vector2.RIGHT
		curve_key.set_left_control(curve_key.left_control, left_dir)
		curve_key.set_right_control(curve_key.right_control, right_dir)
		curve_key.set_interpolation_func(Callable(self, interpolation_indexer[curve_key.interpolation_mode]))
		left_dir = -right_dir
	
	if bakeable:
		baked.clear()
		if keys:
			for x: int in range(keys_keys[0], keys_keys[-1] + 1):
				baked[x] = sample(x)
	
	emit_res_changed()

# works only when keys start from .0 and ended to ctrlr_max_domain.
func create_image_texture() -> ImageTexture:
	var image: Image = Image.create_empty(ctrlr_max_domain, 1, false, Image.FORMAT_L8)
	for x: int in ctrlr_max_domain:
		var y: float = sample_func.call(x)
		image.set_pixel(x, 0, Color(y, y, y))
	return ImageTexture.create_from_image(image)

func duplicate_profile() -> CurveProfile:
	var new_keys: Dictionary[float, CurveKey] = keys.duplicate()
	for key: float in keys:
		var a: CurveKey = keys[key]
		var b: CurveKey = CurveKey.new_curve_key(a.value, a.left_control, a.right_control, a.control_mode, a.interpolation_mode)
		new_keys[key] = b
	var new_profile: CurveProfile = CurveProfile.new_profile_curve(new_keys, bakeable)
	return new_profile

