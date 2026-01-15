class_name Text2DRes extends ObjectRes

signal on_update_data()
signal on_update_lines_positions()
signal on_update_characters()

enum PivotPosition {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	CENTER_LEFT,
	CENTER,
	CENTER_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT
}

enum TextAlignment {
	LEFT,
	CENTER,
	RIGHT
}

func _init() -> void:
	super()
	set_res_id(&"Text2D")
	
	register_prop(&"text", "", &"update_data")
	
	register_prop(&"text_slices", [TextSliceRes.new()] as Array[TextSliceRes])
	register_prop(&"lines_data", [LineData.new()] as Array[LineData])
	
	register_prop(&"tracking", .0, &"update_characters")
	register_prop(&"lines_spacing", .0, &"update_lines_positions")
	
	register_prop(&"text_alignment", TextAlignment.LEFT, &"update_lines_positions")
	register_prop(&"pivot_position", PivotPosition.CENTER, &"update_lines_positions")

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var text_2d:= Text2D.new(self)
	Scene2.instance_object_2d(parent_res, media_res, text_2d, layer_index, frame_in, root_layer_index)
	return text_2d

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"text": CtrlrHelper.get_string_controller_args([], get_prop(&"text")),
		
		&"text_slices": CtrlrHelper.get_list_controller_args([], get_prop(&"text_slices")),
		&"lines_data": CtrlrHelper.get_list_controller_args([], get_prop(&"lines_data")),
		
		&"tracking": CtrlrHelper.get_float_controller_args([], false, get_prop(&"tracking"), -INF, INF),
		&"lines_spacing": CtrlrHelper.get_float_controller_args([], false, get_prop(&"lines_spacing"), -INF, INF),
		
		&"text_alignment": CtrlrHelper.get_option_controller_args([], ["Left", "Center", "Right"], get_prop(&"text_alignment")),
		&"pivot_position": CtrlrHelper.get_option_controller_args([], [
			"TOP_LEFT", "TOP_CENTER", "TOP_RIGHT",
			"CENTER_LEFT", "CENTER", "CENTER_RIGHT",
			"BOTTOM_LEFT", "BOTTOM_CENTER", "BOTTOM_RIGHT"
		], get_prop(&"pivot_position")),
	}


func update_data(val: Variant) -> void:
	on_update_data.emit()

func update_lines_positions(val: Variant) -> void:
	on_update_lines_positions.emit()

func update_characters(val: Variant) -> void:
	on_update_characters.emit()
