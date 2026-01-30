@icon("res://Asset/Icons/Objects/particles-2d.png")
class_name Particles2DRes extends Object2DRes

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var particles_2d:= Particles2D.new()
	Scene2.instance_object_2d(parent_res, media_res, particles_2d, layer_index, frame_in, root_layer_index)
	return particles_2d

static func get_object_info() -> Dictionary[StringName, String]:
	return {&"title": "Particles2D",
		&"description": "Particles2D is used to create diverse visual effects using the Particle System."}

static func get_object_section() -> StringName: return &"Particles"

