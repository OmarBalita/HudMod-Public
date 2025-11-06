class_name UsableRes extends Resource

signal res_initialized(res: UsableRes)
signal res_changed()

@export var res_id: StringName = &""
@export var properties: Dictionary[StringName, Dictionary] = {}
# {&"property": {"v": Variant(), "s": Callable(), "g": Callable()}}
@export var use_global_variables_as_properties: bool = true:
	set(val):
		use_global_variables_as_properties = val
		if val:
			get_prop_func = get
			set_prop_func = set
		else:
			get_prop_func = _get_prop
			set_prop_func = _set_prop

var get_prop_func: Callable = get
var set_prop_func: Callable = set



func get_res_id() -> StringName:
	return res_id

func set_res_id(new_res_id: StringName) -> void:
	res_id = new_res_id

func _get_prop_default(property_key: StringName) -> Variant:
	return properties[property_key].v

func _set_prop_default(property_key: StringName, property_val: Variant) -> void:
	properties[property_key].v = property_val

func _get_prop(property_key: StringName) -> Variant:
	return call(properties[property_key].g, property_key)

func _set_prop(property_key: StringName, property_val: Variant) -> void:
	call(properties[property_key].s, property_key, property_val)

func get_prop(property_key: StringName) -> Variant:
	return get_prop_func.call(property_key)

func set_prop(property_key: StringName, property_val: Variant) -> void:
	set_prop_func.call(property_key, property_val)

func set_and_emit_prop(property_key: StringName, property_val: Variant) -> void:
	set_prop_func.call(property_key, property_val)
	res_changed.emit()

func register_prop(property_key: StringName, property_val: Variant, set_func: StringName = "_set_prop_default", get_func: StringName = "_get_prop_default") -> void:
	properties[property_key] = {"v": property_val, "s": set_func, "g": get_func}

func register_props(_properties: Dictionary[StringName, Variant]) -> void:
	for property_key: StringName in _properties:
		var property_default_val: Variant = _properties.get(property_key)
		register_prop(property_key, property_default_val)


func loop_prop(method: Callable) -> void:
	for property_name: StringName in properties:
		var property_val: Variant = get_prop(property_name)
		method.call(property_name, property_val)

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {}

static func create_custom_edit(name: String, usable_res: UsableRes) -> Array[Control]:
	var exported_parameters = usable_res._get_exported_props()
	
	var edits_box_container:= IS.create_box_container(12, true)
	var edit_box_container:= IS.create_custom_edit_box(name, edits_box_container)
	edits_box_container.set_meta("owner", edit_box_container)
	#usable_res.res_changed.connect(edit_box_container.emit_signal.bind('val_changed', usable_res))
	
	var properties_controllers: Dictionary[StringName, IS.EditBoxContainer] = {}
	EditorServer.set_usable_res_controllers(usable_res, edit_box_container, properties_controllers)
	edit_box_container.tree_exited.connect(EditorServer.clear_usable_res_controllers.bind(usable_res))
	
	var ui_profile: UIProfile = UIProfile.new()
	var ui_conditions: Dictionary[Array, Array]
	
	for param_name: String in exported_parameters:
		var param_info: Dictionary = exported_parameters.get(param_name)
		var param_val: Variant = param_info.val
		
		var ui_cond_key: Array
		# if ui_cond has two elements
		# one for cond_func and one for needed_result
		# example: [Callable() -> int, [1, 2]]
		if param_info.ui_cond.size() == 2:
			ui_cond_key = param_info.ui_cond
		
		if param_info.val is Node:
			usable_res.res_changed.connect(param_info.update_func)
			edits_box_container.tree_exiting.connect(usable_res.res_changed.disconnect.bind(param_info.update_func))
			edits_box_container.add_child(param_info.val)
			continue
		
		var controllers = TypeServer.get_type_controllers_from_val(param_name, param_val, param_info)
		if controllers.size():
			var edit_box: IS.EditBoxContainer = IS.get_edit_box_from(controllers)
			properties_controllers[param_name] = edit_box
			
			edit_box.val_changed.connect(
				func(new_val: Variant) -> void:
					usable_res.set_and_emit_prop(param_name, new_val)
					#usable_res.res_changed.emit()
					ui_profile.update()
			)
			edit_box.keyframe_sended.connect(
				func(param_usable_res: UsableRes, param_key: StringName, param_new_val: Variant) -> void:
					if param_usable_res == null:
						param_usable_res = usable_res
					if param_key.is_empty():
						param_key = param_name
					edit_box_container.keyframe_sended.emit(
						param_usable_res, param_key, param_new_val
					)
			)
			edits_box_container.add_child(edit_box)
			if ui_cond_key:
				if ui_conditions.has(ui_cond_key): ui_conditions[ui_cond_key].append(edit_box)
				else: ui_conditions[ui_cond_key] = [edit_box]
	
	ui_profile.set_ui_conditions(ui_conditions)
	ui_profile.update()
	
	return [edits_box_container]





