class_name Wave2DComponents extends ComponentRes

func _init() -> void:
	super()
	set_res_id("Wave2D")
	register_props({
		enable_x = false,
		enable_y = true,
		method = 0,
		speed = 10.0,
		domain = 100.0
	})

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	var frame: int = EditorServer.frame
	var ex:= func() -> bool: return get_prop(&"enable_x")
	var ey:= func() -> bool: return get_prop(&"enable_y")
	var enabled_cond: Array = [func() -> bool: return ex.call() or ey.call(), [true]]
	return {
		enable_x = CtrlrHelper.get_bool_controller_args([], ex.call()),
		enable_y = CtrlrHelper.get_bool_controller_args([], ey.call()),
		method = CtrlrHelper.get_option_controller_args(enabled_cond, ["Sin", "Cos"], get_prop(&"method")),
		speed = CtrlrHelper.get_float_controller_args(enabled_cond, false, get_prop(&"speed")),
		domain = CtrlrHelper.get_float_controller_args(enabled_cond, false, get_prop(&"domain"))
	}

func _process(frame: int) -> void:
	request_push_animations_result(frame)
	var method: Callable
	match get_prop(&"method"):
		0: method = sin
		1: method = cos
	var speed: float = get_prop(&"speed")
	var domain: float = get_prop(&"domain")
	var result: float = method.call(deg_to_rad(frame) * speed) * domain
	var submitted_result: Vector2
	if get_prop(&"enable_x"):
		submitted_result.x = result
	if get_prop(&"enable_y"):
		submitted_result.y = result
	submit_stacked_value(&"position", submitted_result)
