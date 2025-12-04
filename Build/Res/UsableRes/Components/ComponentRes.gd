class_name ComponentRes extends UsableRes

enum MethodType {
	SET,
	ADD,
	SUB,
	MULTIPLY,
	DIVID
}

@export var owner: MediaClipRes:
	set(val):
		owner = val
		if owner:
			_update()
			res_changed.connect(func() -> void: print("res_changed emited"))
			res_changed.connect(_update)

@export var animations: Dictionary[UsableRes, Dictionary]
# Animating Resources for each value stored like that {
	#UsableRes.new(): {&"property_key": AnimationRes.new()},
	#...
#}

@export var method_type: MethodType = 1:
	set(val):
		if owner and method_type != val:
			_update()
		method_type = val

var update_animations: bool = true


func _init() -> void:
	use_global_variables_as_properties = false

func get_owner() -> MediaClipRes:
	return owner

func set_owner(new_owner: MediaClipRes) -> void:
	owner = new_owner

func get_method_type() -> MethodType:
	return method_type

func set_method_type(new_method_type: MethodType) -> void:
	method_type = new_method_type

func _enter() -> void:
	pass

func _process(frame: int) -> void:
	#printt("process frame:", frame)
	request_push_animations_result(frame)
	loop_prop(submit_stacked_value)

func _exit() -> void:
	pass

func _update() -> void:
	update_animations = false
	owner.process(owner.curr_frame)
	update_animations = true


func submit_stacked_value(key: StringName, value: Variant) -> void:
	owner.add_stacked_value(key, value, method_type)

func receive_stacked_values_key_result(key: StringName) -> Variant:
	return owner.get_stacked_values_key_result(key)


func request_push_animations_result(frame: float) -> void:
	if update_animations:
		push_animations_result(frame)

func push_animations_result(frame: float) -> void:
	for usable_res: UsableRes in animations.keys():
		var res_section: Dictionary = animations.get(usable_res)
		for property_key: StringName in res_section.keys():
			var anim_res: AnimationRes = res_section.get(property_key)
			var property_anim_val: Variant = anim_res.sample(frame)
			var property_has_keyframe: bool = has_animation_keyframe(usable_res, property_key, frame)
			usable_res.set_prop(property_key, property_anim_val)
			EditorServer.update_usable_res_property_controller(usable_res, property_key, property_anim_val, property_has_keyframe)


func get_animation(usable_res: UsableRes, property_key: StringName) -> AnimationRes:
	return animations[usable_res][property_key]

func has_animation_keyframe(usable_res: UsableRes, property_key: StringName, frame: Variant = null) -> bool:
	frame = owner.get_frame_or_curr_frame(frame)
	return animations[usable_res][property_key].has_key(frame)

func make_animation_absolute(usable_res: UsableRes, property_key: StringName, property_type: int) -> AnimationRes:
	var res_section: Dictionary = animations.get_or_add(usable_res, {})
	return res_section.get_or_add(property_key, AnimationRes.new(property_type))

func remove_animation_absolute(usable_res: UsableRes, property_key: StringName) -> void:
	var res_section: Variant = animations.get(usable_res)
	if res_section is Dictionary:
		res_section.erase(property_key)
		if res_section.size() == 0:
			animations.erase(res_section)

func request_animation_keyframe(usable_res: UsableRes, property_key: StringName, property_val: Variant, frame: Variant = null) -> void:
	frame = owner.get_frame_or_curr_frame(frame)
	var anim_res: AnimationRes = make_animation_absolute(usable_res, property_key, TypeServer.get_type_from_value(property_val))
	var has_key: bool = anim_res.has_key(frame)
	if has_key: remove_animation_keyframe(usable_res, property_key, frame)
	else: add_animation_keyframe(usable_res, property_key, property_val, frame)
	EditorServer.set_usable_res_property_controller_keyframe_method(usable_res, property_key, not has_key)

func add_animation_keyframe(usable_res: UsableRes, property_key: StringName, property_val: Variant, frame: int) -> void:
	if owner.is_frame_exists(frame): get_animation(usable_res, property_key).add_key(frame, property_val)

func remove_animation_keyframe(usable_res: UsableRes, property_key: StringName, frame: int) -> void:
	var anim_res: AnimationRes = get_animation(usable_res, property_key)
	anim_res.remove_key(frame)
	if anim_res.keys.size() == 0:
		remove_animation_absolute(usable_res, property_key)







