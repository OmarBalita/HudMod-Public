#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name ComponentRes extends UsableRes

signal ready(owner: MediaClipRes)
signal ready_from_loader(owner: MediaClipRes)

var owner: MediaClipRes: set = _set_owner

@export var forced: bool = false
@export var enabled: bool = true: set = _set_enabled
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
	_update_parent_here()

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

func _set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled
	if owner: owner.emit_clip_res_changed()

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


func _get_gizmos() -> Array[Callable]:
	return []

func _gizmos_input(event: InputEvent, info: Dictionary[StringName, Variant]) -> bool:
	return false


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

func _update_parent_here() -> void:
	if owner: owner.update()

func set_prop_and_emit(property_key: StringName, property_val: Variant) -> void:
	super(property_key, property_val)
	if not owner.has_animation(self, property_key): return
	owner.request_animation_keyframe(self, property_key, property_val, null, false)


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

func owner_update_my_controller(frame: int) -> void:
	owner.update_specific_controllers_by_animations(self, frame)

func request_animation_keyframe(usable_res: UsableRes, property_key: StringName, property_val: Variant, frame: Variant = null, can_remove: bool = true) -> void:
	owner.request_animation_keyframe(usable_res, property_key, property_val, frame, can_remove)

