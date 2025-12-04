class_name Camera2DRes extends ObjectRes

func _init() -> void:
	set_res_id(&"Camera2D")


func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var camera_2d:= Camera2D.new()
	Scene2.instance_object_2d(parent_res, media_res, camera_2d, layer_index, frame_in, root_layer_index)
	return camera_2d

