@icon("res://Asset/Icons/Objects/shape-2d.png")
class_name Shape2DRes extends Object2DRes

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var shape_2d:= Shape2DObject.new()
	Scene2.instance_object_2d(parent_res, media_res, shape_2d, layer_index, frame_in, root_layer_index)
	return shape_2d

static func get_object_section() -> StringName: return &"Shape2D"

