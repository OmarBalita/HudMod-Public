@icon("res://Asset/Icons/Objects/empty-object-2d.png")
class_name Object2DRes extends ObjectRes

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var node_2d:= Node2D.new()
	Scene2.instance_object_2d(parent_res, media_res, node_2d, layer_index, frame_in, root_layer_index)
	return node_2d

static func get_object_category_name() -> StringName: return &"Object2D"
static func get_object_info() -> Dictionary[StringName, String]:
	return {
		&"title": "Object2D",
		&"description": "The Object2D is simply an object with 2D properties; it can be moved, rotated, and resized.
		It's useful because it can be used as a pointer or drawn on."
	}

