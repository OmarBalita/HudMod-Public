class_name Audio2DRes extends ObjectRes

func _init() -> void:
	set_res_id(&"Audio2D")

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var audio_player_2d:= AudioStreamPlayer2D.new()
	Scene2.instance_object_2d(parent_res, media_res, audio_player_2d, layer_index, frame_in, root_layer_index)
	return audio_player_2d

static func get_object_info() -> Dictionary[StringName, String]:
	return {&"title": "Audio2D",
		&"description": "Audio2D allows you not only to play sounds, but also to modify the source of the sound by changing the location of the Audio2D."}
