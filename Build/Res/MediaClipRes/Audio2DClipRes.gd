@icon("res://Asset/Icons/Objects/audio.png")
class_name Audio2DClipRes extends Display2DClipRes

@export var stream: String:
	set(val):
		stream = val
		if MediaCache.audio_datas_has(stream):
			audio_data_res = MediaCache.get_audio_data(stream)
		else:
			audio_data_res = MediaCache.default_audio_f32_data

var audio_data_res: MediaCache.AudioF32Data = MediaCache.default_audio_f32_data

static func get_properties_section() -> StringName: return &"Sound"
static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
	&"title": "Audio2D",
	&"description": ""
}

func get_min_from() -> float: return .0
func get_max_length() -> float:
	return audio_data_res.get_length() * ProjectServer2.fps if audio_data_res else +INF

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {&"stream": export(string_args(stream))} as Dictionary[StringName, ExportInfo].merged(super())

func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	var player:= AudioStreamPlayer2D.new()
	player.bus = PlaybackServer.root_layer_get_bus_unique_name(root_layer_idx)
	return _init_node2d(root_layer_idx, layer_idx, layer_res, frame, player)

func enter(node: Node) -> void:
	super(node)
	Scene2.add_stream_player(self)

func _process_comps(frame: int) -> void:
	super(frame)

func exit(node: Node) -> void:
	super(node)
	Scene2.remove_stream_player(self)

func check_for_paths(paths_for_check: PackedStringArray) -> PackedStringArray:
	return [] if paths_for_check.has(stream) else [stream]

func format_paths(paths_for_format: Dictionary[String, String]) -> void:
	if paths_for_format.has(stream): stream = paths_for_format[stream]

func update_paths() -> void:
	stream = stream


