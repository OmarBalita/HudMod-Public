class_name ComponentRes extends UsableRes

enum MethodType {
	SET,
	ADD,
	SUB,
	MULTIPLY,
	DIVIDE
}

@export var owner: MediaClipRes:
	set(val):
		owner = val
		if owner:
			_update()
			if not res_changed.is_connected(_update):
				res_changed.connect(_update)

@export var animations: Dictionary[UsableRes, Dictionary]
# Animating Resources for each value stored like that {
	#UsableRes.new(): {&"property_key": AnimationRes.new()},
	#...
#}

@export var method_type: MethodType = 1:
	set(val):
		method_type = val
		if owner and method_type != val:
			_update()

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

func duplicate_component_res() -> ComponentRes:
	var dupl_comp_res: ComponentRes = duplicate(true)
	
	var dupl_anims:= animations.duplicate(true)
	if animations.has(self):
		var dupl_anims_port: Dictionary = animations.get(self)
		for anim_key: StringName in dupl_anims_port:
			dupl_anims_port[anim_key] = dupl_anims_port[anim_key].duplicate_anim_res()
		dupl_anims[dupl_comp_res] = dupl_anims_port
		dupl_anims.erase(self)
	dupl_comp_res.animations = dupl_anims
	
	return dupl_comp_res

func _enter() -> void:
	pass

func _process(frame: int) -> void:
	loop_prop(submit_stacked_value)

func _exit() -> void:
	pass

func _update() -> void:
	update_animations = false
	owner.process(owner.curr_frame)
	update_animations = true

func _update_and_animate() -> void:
	owner.process(owner.curr_frame)


func submit_stacked_value(key: StringName, value: Variant) -> void:
	owner.add_stacked_value(key, value, method_type)

func receive_stacked_values_key_result(key: StringName) -> Variant:
	return owner.get_stacked_values_key_result(key)

func request_push_animations_result(frame: float) -> void:
	if update_animations:
		push_animations_result(frame)

func loop_animations(frame: float, method: Callable) -> void:
	frame += owner.from
	for usable_res: UsableRes in animations.keys():
		var usable_res_section: Dictionary = animations.get(usable_res)
		for property_key: StringName in usable_res_section.keys():
			var anim_res: AnimationRes = usable_res_section.get(property_key)
			method.call(usable_res, anim_res, property_key, frame)

func push_animation_result_func(usable_res: UsableRes, anim_res: AnimationRes, property_key: StringName, frame: int) -> void:
	usable_res.set_prop(property_key, anim_res.sample(frame))

func update_controller_func(usable_res: UsableRes, anim_res: AnimationRes, property_key: StringName, frame: int) -> void:
	var property_has_keyframe: bool = has_animation_keyframe(usable_res, property_key, frame)
	EditorServer.update_usable_res_property_controller(usable_res, property_key, anim_res.sample(frame), property_has_keyframe)

func push_animations_result(frame: float) -> void:
	loop_animations(frame, push_animation_result_func)

func update_controllers(frame: float) -> void:
	loop_animations(frame, update_controller_func)


func get_animation(usable_res: UsableRes, property_key: StringName) -> AnimationRes:
	return animations[usable_res][property_key]

func has_animation(usable_res: UsableRes, property_key: StringName) -> bool:
	return animations.has(usable_res) and animations[usable_res].has(property_key)

func has_animation_keyframe(usable_res: UsableRes, property_key: StringName, frame: int) -> bool:
	if not has_animation(usable_res, property_key): return false
	return animations[usable_res][property_key].has_key(frame)

func make_animation_absolute(usable_res: UsableRes, property_key: StringName, property_type: int) -> AnimationRes:
	var res_section: Dictionary = animations.get_or_add(usable_res, {})
	if not res_section.has(property_key):
		var anim_res: AnimationRes = AnimationRes.new()
		anim_res.set_value_type(property_type)
		anim_res.update_profiles()
		res_section[property_key] = anim_res
		for profile: CurveProfile in anim_res.profiles:
			profile.profile_updated.connect(_update_and_animate)
		owner.comp_animation_res_added.emit(self, usable_res, property_key, anim_res)
	return res_section.get(property_key)

func remove_animation_absolute(usable_res: UsableRes, property_key: StringName) -> void:
	var res_section: Variant = animations.get(usable_res)
	if res_section is Dictionary:
		res_section.erase(property_key)
		owner.comp_animation_res_removed.emit(self, usable_res, property_key)
		if res_section.size() == 0:
			animations.erase(res_section)

func request_animation_keyframe(usable_res: UsableRes, property_key: StringName, property_val: Variant, frame: Variant = null, can_remove: bool = true) -> void:
	frame = owner.get_frame_or_curr_frame(frame)
	var anim_res: AnimationRes = make_animation_absolute(usable_res, property_key, TypeServer.get_type_from_value(property_val))
	var is_remove_request: bool = can_remove and anim_res.has_key(frame)
	if is_remove_request: remove_animation_keyframe(usable_res, property_key, frame)
	else: add_animation_keyframe(usable_res, property_key, property_val, frame)
	EditorServer.set_usable_res_property_controller_keyframe_method(usable_res, property_key, not is_remove_request)

func add_animation_keyframe(usable_res: UsableRes, property_key: StringName, property_val: Variant, frame: int) -> void:
	get_animation(usable_res, property_key).add_key(frame, property_val)
	owner.comp_keyframe_added.emit(self, usable_res, property_key, property_val, frame)

func remove_animation_keyframe(usable_res: UsableRes, property_key: StringName, frame: int) -> void:
	var anim_res: AnimationRes = get_animation(usable_res, property_key)
	anim_res.remove_key(frame)
	if not anim_res.has_any_key():
		remove_animation_absolute(usable_res, property_key)
	owner.comp_keyframe_removed.emit(self, usable_res, property_key, frame)

func send_new_val(edit_box_container: IS.EditBoxContainer, usable_res: UsableRes, param_key: StringName, param_new_val: Variant) -> void:
	if has_animation(usable_res, param_key):
		request_animation_keyframe(usable_res, param_key, param_new_val, null, false)

func send_keyframe(edit_box_container: IS.EditBoxContainer, usable_res: UsableRes, param_key: StringName, param_new_val: Variant) -> void:
	request_animation_keyframe(usable_res, param_key, param_new_val)
