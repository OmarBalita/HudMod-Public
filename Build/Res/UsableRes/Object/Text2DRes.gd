class_name Text2DRes extends ObjectRes

func _init() -> void:
	set_res_id(&"Text2D")

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var text_2d:= Text2D.new()
	Scene2.instance_object_2d(parent_res, media_res, text_2d, layer_index, frame_in, root_layer_index)
	return text_2d

static func get_object_info() -> Dictionary[StringName, String]:
	return {&"title": "Text2D",
		&"description": "Text2D is a 2D writing system, characterized by its flexibility and the ability to modify the theme of each part."}
