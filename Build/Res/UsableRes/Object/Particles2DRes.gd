class_name Particles2DRes extends ObjectRes

func _init() -> void:
	set_res_id(&"Particles2D")

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var particles_2d:= Particles2D.new()
	Scene2.instance_object_2d(parent_res, media_res, particles_2d, layer_index, frame_in, root_layer_index)
	return particles_2d
