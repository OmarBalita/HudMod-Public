class_name VisibilityBasicsComponent extends ComponentRes

func _init() -> void:
	set_res_id("VisibilityBasics")
	register_properties({
		visible = true,
		modulate = Color.WHITE,
		self_modulate = Color.WHITE,
		top_level = false,
		clip_children = 0
	})

func _get_exported_parameters() -> Dictionary[StringName, Dictionary]:
	var frame: int = EditorServer.get_frame()
	return {
		visible = CtrlrHelper.get_bool_controller_args([], get_prop(&"visible", frame)),
		modulate = CtrlrHelper.get_color_controller_args([], get_prop(&"modulate", frame)),
		self_modulate = CtrlrHelper.get_color_controller_args([], get_prop(&"self_modulate", frame)),
		top_level = CtrlrHelper.get_bool_controller_args([], get_prop(&"top_level", frame)),
		clip_children = CtrlrHelper.get_option_controller_args([], ["Disabled", "Clip Only", "Clip and Draw"], get_prop(&"clip_children", frame))
	}

