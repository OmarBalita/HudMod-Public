class_name UsableRes extends Resource

signal res_initialized(res: UsableRes)
signal res_changed()

var res_id: StringName


func get_res_id() -> StringName:
	return res_id

func set_res_id(new_res_id: StringName) -> void:
	res_id = new_res_id

func _get_exported_parameters() -> Dictionary[String, Dictionary]:
	return {}




static func create_custom_edit(name: String, usable_res: UsableRes) -> Array[Control]:
	var exported_parameters = usable_res._get_exported_parameters()
	
	var edits_box_container = InterfaceServer.create_box_container(12, true)
	var edit_box_container = InterfaceServer.create_custom_edit_box(name, edits_box_container)
	usable_res.res_changed.connect(edit_box_container.emit_signal.bind('val_changed', usable_res))
	
	var ui_profile = UIProfile.new()
	var ui_conditions: Dictionary[Array, Array]
	
	for param_name: String in exported_parameters:
		var param_info = exported_parameters.get(param_name) as Dictionary
		var param_val = param_info.val
		
		var ui_cond_key: Array
		if param_info.ui_cond.size() == 2: # if ui_cond has two elements, one for cond_func and one for needed_result, example: [Callable() -> int, [1, 2]]
			ui_cond_key = param_info.ui_cond
		
		if param_info.val is Node:
			usable_res.res_changed.connect(param_info.update_func)
			edits_box_container.tree_exiting.connect(usable_res.res_changed.disconnect.bind(param_info.update_func))
			edits_box_container.add_child(param_info.val)
			continue
		
		var controllers = TypeServer.get_type_controllers_from_val(param_name, param_val, param_info)
		if controllers.size():
			var edit_box = InterfaceServer.get_edit_box_from(controllers)
			edit_box.val_changed.connect(
				func(new_val: Variant) -> void:
					usable_res.set(param_name, new_val)
					usable_res.res_changed.emit()
					ui_profile.update()
			)
			edits_box_container.add_child(edit_box)
			if ui_cond_key:
				if ui_conditions.has(ui_cond_key): ui_conditions[ui_cond_key].append(edit_box)
				else: ui_conditions[ui_cond_key] = [edit_box]
	
	ui_profile.set_ui_conditions(ui_conditions)
	ui_profile.update()
	
	return [edits_box_container]





