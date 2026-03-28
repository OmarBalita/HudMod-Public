class_name CurveSampler extends Object

static var curve_profiles: Array[CurveProfile]

static func create_profile(keys: Dictionary[int, CurveKey]) -> CurveProfile:
	var profile:= CurveProfile.new_curve_profile(keys)
	curve_profiles.append(profile)
	return profile

static func free_profile(profile: CurveProfile) -> void:
	curve_profiles.erase(profile)
	profile.free()

