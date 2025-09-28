class_name OffsetComponent extends ComponentRes

func _init() -> void:
	set_res_id("Offset")
	register_properties({
		centered = true,
		offset = Vector2.ZERO,
		flip_h = false,
		flip_v = false
	})

func _get_exported_parameters() -> Dictionary[StringName, Dictionary]:
	var frame: int = EditorServer.frame
	return {
		centered = CtrlrHelper.get_bool_controller_args([], get_prop(&"centered", frame)),
		offset = CtrlrHelper.get_vec2_controller_args([], get_prop(&"offset", frame)),
		flip_h = CtrlrHelper.get_bool_controller_args([], get_prop(&"flip_h", frame)),
		flip_v = CtrlrHelper.get_bool_controller_args([], get_prop(&"flip_v", frame))
	}

