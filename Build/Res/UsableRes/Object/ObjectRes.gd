class_name ObjectRes extends UsableRes

func _init() -> void:
	set_res_id(&"Object")

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	return null

static func get_object_info() -> Dictionary[StringName, String]:
	return {&"title": "ObjectRes",
		&"description": ""}

