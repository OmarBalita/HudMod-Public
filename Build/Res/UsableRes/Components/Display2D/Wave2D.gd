class_name Wave2DComponents extends ComponentRes

func _init() -> void:
	set_res_id("Wave2D")
	register_properties({
		enable_x = false,
		enable_y = true,
		method = 0,
		speed = 10.0,
		domain = 100.0
	})

func _get_exported_parameters() -> Dictionary[StringName, Dictionary]:
	var frame: int = EditorServer.frame
	var ex:= func() -> bool: return get_prop(&"enable_x", frame)
	var ey:= func() -> bool: return get_prop(&"enable_y", frame)
	var enabled_cond: Array = [func() -> bool: return ex.call() or ey.call(), [true]]
	return {
		enable_x = CtrlrHelper.get_bool_controller_args([], ex.call()),
		enable_y = CtrlrHelper.get_bool_controller_args([], ey.call()),
		method = CtrlrHelper.get_option_controller_args(enabled_cond, ["Sin", "Cos"], get_prop(&"method", frame)),
		speed = CtrlrHelper.get_float_controller_args(enabled_cond, false, get_prop(&"speed", frame)),
		domain = CtrlrHelper.get_float_controller_args(enabled_cond, false, get_prop(&"domain", frame))
	}

func _process(node: Node, frame: int) -> void:
	var method: Callable
	match get_prop(&"method", frame):
		0: method = sin
		1: method = cos
	var speed: float = get_prop(&"speed", frame)
	var domain: float = get_prop(&"domain", frame)
	var result: float = method.call(deg_to_rad(frame) * speed) * domain
	if get_prop(&"enable_x", frame):
		node.position.x = result
	if get_prop(&"enable_y", frame):
		node.position.y = result












