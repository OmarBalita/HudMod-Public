class_name CurveSampler extends Object

static var curve_profiles: Array[Profile]

static var interpolation_indexer: Dictionary[Profile.InterpolationType, Dictionary] = {
	Profile.InterpolationType.INTERMITTENT: {t = 2, m = Callable()},
	Profile.InterpolationType.LINEAR: {t = 1, m = Callable()},
	Profile.InterpolationType.CUBIC_BEZIER_CURVE: {t = 1, m = Callable()},
	Profile.InterpolationType.LINEAR_INT: {t = 0, m = Callable()},
	Profile.InterpolationType.CUBIC_BEZIER_CURVE_INT: {t = 0, m = Callable()},
}

class Profile extends Resource:
	enum InterpolationType {
		INTERMITTENT,
		LINEAR,
		CUBIC_BEZIER_CURVE,
		LINEAR_INT,
		CUBIC_BEZIER_CURVE_INT
	}
	@export var interpolation_type: InterpolationType
	@export var keys: Dictionary[float, Variant]
	
	func _init(_interpolation_type: InterpolationType, _keys: Dictionary[float, Variant]) -> void:
		keys = _keys

static func create_profile(interp_type: Profile.InterpolationType, keys: Dictionary[float, Variant]) -> void:
	var profile:= Profile.new(interp_type, keys)
	curve_profiles.append(profile)

