@icon("res://Asset/Icons/Objects/camera-2d.png")
class_name Camera2DRes extends Object2DRes

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var camera_2d:= Camera2D.new()
	Scene2.instance_object_2d(parent_res, media_res, camera_2d, layer_index, frame_in, root_layer_index)
	return camera_2d

static func get_object_info() -> Dictionary[StringName, String]:
	return {&"title": "Camera2D",
		&"description": "Camera2D can be a game changer for the editor,
		allowing you to add a camera clip with different properties to any part of the timeline you want."}
