@icon("res://Asset/Icons/Objects/audio.png")
class_name Audio2DClipRes extends Display2DClipRes

@export var stream: String:
	set(val):
		stream = val
		if MediaCache.audio_stream_waves_has(stream):
			audio_stream = MediaCache.get_audio(stream)

var audio_stream: AudioStreamWAV:
	set(val):
		audio_stream = val
		if curr_node:
			curr_node.stream = audio_stream

static func get_properties_section() -> StringName: return &"Sound"
static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
	&"title": "Audio2D",
	&"description": ""
}

func get_min_from() -> float: return .0
func get_max_length() -> float:
	return audio_stream.get_length() * ProjectServer.fps if audio_stream else +INF

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {&"stream": export(string_args(stream))} as Dictionary[StringName, ExportInfo].merged(super())

func init_node(layer_idx: int, frame_in: int) -> Node:
	var player:= AudioStreamPlayer2D.new()
	player.bus = ProjectServer.get_bus_name_from_layer_index(layer_idx)
	return player

func _process_comps(frame: int) -> void:
	super(frame)

