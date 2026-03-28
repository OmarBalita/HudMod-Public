class_name ComponentRes extends UsableRes

signal ready(owner: MediaClipRes)
signal ready_from_loader(owner: MediaClipRes)

var owner: MediaClipRes: set = _set_owner

@export var animations: Dictionary[UsableRes, Dictionary]
# Animating Resources for each value stored like that {
	#UsableRes.new(): {&"property_key": AnimationRes.new()},
	#...
#}
@export var forced: bool = false
@export var enabled: bool = true:
	set(val):
		enabled = val
		emit_res_changed()
@export var method_type: MethodType = 1:
	set(val):
		if owner and method_type != val:
			emit_res_changed()
		method_type = val

var captured_props: Dictionary[int, Dictionary]

func until_ready() -> void:
	if not owner: await ready

func emit_res_changed() -> void:
	super()
	_process_parent_here()

func get_owner() -> MediaClipRes:
	return owner

func set_owner(new_owner: MediaClipRes) -> void:
	owner = new_owner
	ready.emit(new_owner)

func set_owner_from_loader(new_owner: MediaClipRes) -> void:
	owner = new_owner
	ready.emit(new_owner)
	ready_from_loader.emit(new_owner)

func _set_owner(new_owner: MediaClipRes) -> void:
	owner = new_owner

func get_forced() -> bool:
	return forced

func set_forced(new_forced: bool) -> void:
	forced = new_forced

func get_enabled() -> bool:
	return enabled

func set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled

func has_method_type() -> bool: return true

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
	pass

func _postprocess(frame: int) -> void:
	pass

func _apply_custom_stacked_values(frame: int, dict: Dictionary[StringName, Array]) -> void:
	pass

func _exit() -> void:
	pass

func _delete() -> void:
	_exit()

#func _update() -> void:
	#update_animations = false
	#owner.process(owner.curr_frame)
	#update_animations = true

func _process_parent_here() -> void:
	if owner and owner.curr_node: owner.process_here()


func has_captured_props(idx: int) -> bool:
	return captured_props.has(idx)

func release_captured_props(idx: int) -> Dictionary[StringName, Variant]:
	return captured_props[idx]

func put_captured_props(idx: int, props_dict: Dictionary[StringName, Variant]) -> void:
	captured_props[idx] = props_dict

func capture_props(props: Array[StringName]) -> Dictionary[StringName, Variant]:
	var props_dict: Dictionary[StringName, Variant] = {}
	for prop_key: StringName in props:
		props_dict[prop_key] = get_prop(prop_key)
	return props_dict

## return how much of props are different, if all are different returns -1
func compare_captured_props(idx: int, forwhat: Dictionary[StringName, Variant]) -> int:
	if not has_captured_props(idx):
		return 0
	
	var captured_props:= release_captured_props(idx)
	var diff_count: int
	
	for prop_key: StringName in captured_props:
		if captured_props[prop_key] != forwhat[prop_key]:
			diff_count += 1
	
	if diff_count == captured_props.size():
		return -1
	else:
		return diff_count

func apply_stacked_value(stacked_values: Dictionary[StringName, Array], key: StringName, value: Variant) -> void:
	stacked_values.get_or_add(key, []).append([value, method_type])

func submit_stacked_value(key: StringName, value: Variant) -> void:
	owner.add_stacked_value(key, value, method_type)

func submit_stacked_value_with_custom_method(key: StringName, value: Variant, custom_method: MethodType = MethodType.SET) -> void:
	owner.add_stacked_value(key, value, custom_method)

func submit_stacked_values(stacked_values: Dictionary[StringName, Variant]) -> void:
	for key: StringName in stacked_values:
		owner.add_stacked_value(key, stacked_values[key], method_type)

func loop_animations(frame: float, method: Callable) -> void:
	frame += owner.from
	for usable_res: UsableRes in animations.keys():
		var usable_res_section: Dictionary = animations.get(usable_res)
		for property_key: StringName in usable_res_section.keys():
			var anim_res: AnimationRes = usable_res_section.get(property_key)
			method.call(usable_res, anim_res, property_key, frame)

func sample_or_get(usable_res: UsableRes, prop_key: StringName, frame: int) -> Variant:
	return get_animation(usable_res, prop_key).sample(frame) if has_animation(usable_res, prop_key) else usable_res.get(prop_key)

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
			profile.res_changed.connect(_process_parent_here)
		owner.comp_animation_res_added.emit(self, usable_res, property_key, anim_res)
		owner.shared_data_clear()
	return res_section.get(property_key)

func remove_animation_absolute(usable_res: UsableRes, property_key: StringName) -> void:
	var res_section: Variant = animations.get(usable_res)
	if res_section is Dictionary:
		res_section.erase(property_key)
		owner.comp_animation_res_removed.emit(self, usable_res, property_key)
		owner.shared_data_clear()
		if res_section.size() == 0:
			animations.erase(res_section)

func request_animation_keyframe(usable_res: UsableRes, property_key: StringName, property_val: Variant, frame: Variant = null, can_remove: bool = true) -> void:
	frame = owner.get_frame_or_curr_frame(frame)
	var anim_res: AnimationRes = make_animation_absolute(usable_res, property_key, typeof(property_val))
	var is_remove_request: bool = can_remove and anim_res.has_key(frame)
	if is_remove_request: remove_animation_keyframe(usable_res, property_key, frame)
	else: add_animation_keyframe(usable_res, property_key, property_val, frame)
	EditorServer.set_usable_res_property_controller_keyframe_method(usable_res, property_key, not is_remove_request)

func add_animation_keyframe(usable_res: UsableRes, property_key: StringName, property_val: Variant, frame: int) -> void:
	get_animation(usable_res, property_key).add_key(frame, property_val)
	owner.comp_keyframe_added.emit(self, usable_res, property_key, property_val, frame)
	owner.shared_data_clear()

func remove_animation_keyframe(usable_res: UsableRes, property_key: StringName, frame: int) -> void:
	var anim_res: AnimationRes = get_animation(usable_res, property_key)
	anim_res.remove_key(frame)
	if not anim_res.has_any_key():
		remove_animation_absolute(usable_res, property_key)
	owner.comp_keyframe_removed.emit(self, usable_res, property_key, frame)
	owner.shared_data_clear()

func _receive_new_val(edit_box_container: IS.EditBoxContainer, usable_res: UsableRes, param_key: StringName, param_new_val: Variant) -> void:
	if has_animation(usable_res, param_key):
		request_animation_keyframe(usable_res, param_key, param_new_val, null, false)

func _receive_keyframe(edit_box_container: IS.EditBoxContainer, usable_res: UsableRes, param_key: StringName, param_new_val: Variant) -> void:
	request_animation_keyframe(usable_res, param_key, param_new_val)

