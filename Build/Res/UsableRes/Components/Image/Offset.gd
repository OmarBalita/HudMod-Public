class_name OffsetComponent extends ComponentRes

func _init() -> void:
	super()
	set_res_id("Offset")
	register_props({
		centered = true,
		offset = Vector2.ZERO,
		flip_h = false,
		flip_v = false
	})

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	var frame: int = EditorServer.frame
	return {
		centered = CtrlrHelper.get_bool_controller_args([], get_prop(&"centered")),
		offset = CtrlrHelper.get_vec2_controller_args([], get_prop(&"offset")),
		flip_h = CtrlrHelper.get_bool_controller_args([], get_prop(&"flip_h")),
		flip_v = CtrlrHelper.get_bool_controller_args([], get_prop(&"flip_v"))
	}

