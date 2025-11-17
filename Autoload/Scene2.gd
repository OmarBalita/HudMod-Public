extends Node

@export var curr_nodes: Dictionary[MediaClipRes, Node]

func instance_sprite() -> Sprite2D:
	var sprite:= Sprite2D.new()
	return sprite

func instance_video_viewer() -> VideoViewer:
	var video_viewer:= VideoViewer.new()
	return video_viewer

func instance_audio_stream_player() -> AudioStreamPlayer:
	var audio_player:= AudioStreamPlayer.new()
	return audio_player

func instance_node() -> void:
	pass

func free_node() -> void:
	pass

