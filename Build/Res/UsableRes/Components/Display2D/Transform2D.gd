class_name Transform2DComponent extends ComponentRes

func _init() -> void:
	super()
	set_res_id("Transform2D")
	register_props({
		position = Vector2.ZERO,
		rotation_degrees = .0,
		scale = Vector2.ONE,
		skew = .0,
		#enable_expression = false,
		#position_expression = "",
		#rotation_expression = "",
		#scale_expression = "",
		#skew_expression = ""
	})

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	var frame: int = EditorServer.frame
	#var is_expr_enabled: Callable = func() -> bool: return get_prop(&"enable_expression", frame)
	#var expr_cond: Array = [is_expr_enabled, [true]]
	return {
		position = CtrlrHelper.get_vec2_controller_args([], get_prop(&"position")),
		rotation_degrees = CtrlrHelper.get_float_controller_args([], false, get_prop(&"rotation_degrees"), -INF, INF, .001, .2),
		scale = CtrlrHelper.get_vec2_controller_args([], get_prop(&"scale")),
		skew = CtrlrHelper.get_float_controller_args([], false, get_prop(&"skew")),
		#enable_expression = CtrlrHelper.get_bool_controller_args([], is_expr_enabled.call()),
		#position_expression = CtrlrHelper.get_string_controller_args(expr_cond, get_prop(&"position_expression", frame)),
		#rotation_expression = CtrlrHelper.get_string_controller_args(expr_cond, get_prop(&"rotation_expression", frame)),
		#scale_expression = CtrlrHelper.get_string_controller_args(expr_cond, get_prop(&"scale_expression", frame)),
		#skew_expression = CtrlrHelper.get_string_controller_args(expr_cond, get_prop(&"skew_expression", frame))
	}









