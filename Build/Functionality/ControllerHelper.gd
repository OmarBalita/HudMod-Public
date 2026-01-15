class_name CtrlrHelper extends Object


static func get_option_controller_args(ui_cond: Array, options_keys: Array, default_id: int = 0, save_path: String = "") -> Dictionary[String, Variant]:
	var options_info = get_options_info_from_keys(options_keys)
	return {'options_info': options_info, "save_path": save_path, 'val': default_id, 'ui_cond': ui_cond}

static func get_bool_controller_args(ui_cond: Array, is_checked: bool = false) -> Dictionary[String, Variant]:
	return {'val': is_checked, 'ui_cond': ui_cond}

static func get_string_controller_args(ui_cond: Array, text: String = "", placeholder: String = "") -> Dictionary[String, Variant]:
	return {'placeholder': placeholder, 'val': text, 'ui_cond': ui_cond}

static func get_float_controller_args(ui_cond: Array, is_int: bool = false, curr_val: float = .0, min_val: float = -INF, max_val: float = INF, step: float = .01, spin_scale: float = .01, spin_magnet_step: float = 10.0) -> Dictionary[String, Variant]:
	return {'slider': false, 'spin_box': true, 'val': curr_val, 'min_val': min_val, 'max_val': max_val, 'step': step, 'spin_scale': spin_scale, 'spin_magnet_step': spin_magnet_step, "is_int": is_int, 'ui_cond': ui_cond}

static func get_vec2_controller_args(ui_cond: Array, curr_val: Vector2) -> Dictionary[String, Variant]:
	return {"val": curr_val, 'ui_cond': ui_cond}

static func get_vec3_controller_args(ui_cond: Array, curr_val: Vector3) -> Dictionary[String, Variant]:
	return {"val": curr_val, 'ui_cond': ui_cond}

static func get_color_controller_args(ui_cond: Array, color: Color = Color.BLACK) -> Dictionary[String, Variant]:
	return {'val': color, 'ui_cond': ui_cond}

static func get_list_controller_args(ui_cond: Array, list: Array = [], list_types: Array[String] = [], connections: Array[Signal] = [], can_add_element: bool = true, can_remove_element: bool = true, can_duplicate_element: bool = true, can_change_element_priority: bool = true) -> Dictionary[String, Variant]:
	return {'val': list, 'list_types': list_types, 'connections': connections, 'can_add_element': can_add_element, 'can_remove_element': can_remove_element, 'can_duplicate_element': can_duplicate_element, 'can_change_element_priority': can_change_element_priority, 'ui_cond': ui_cond}

static func get_color_range_controller_args(ui_cond: Array, color_range_res: ColorRangeRes) -> Dictionary[String, Variant]:
	return {'val': color_range_res, 'ui_cond': ui_cond}

#static func get_curve_controller_args(curve_res: CurveRes) -> Dictionary[String, Variant]:
	#return {}

static func get_res_controller_args(ui_cond: Array, res: UsableRes) -> Dictionary[String, Variant]:
	return {'val': res, 'ui_cond': ui_cond}


static func get_options_info_from_keys(keys: Array) -> Array[Dictionary]:
	var result: Array[Dictionary]
	for key in keys: result.append({text = key, icon = null})
	return result

static func get_ui_cond(cond_func: Callable = Callable(), needed_result: Array = []) -> Dictionary[String, Variant]:
	return {'ui_cond': [cond_func, needed_result]}
