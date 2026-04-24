@icon("res://Asset/Icons/Objects/audio.png")
class_name AudioClipRes extends MediaClipRes

@export var stream: String:
	set(val):
		stream = val
		var has_stream: bool = MediaCache.audio_datas_has(stream)
		is_opening = has_stream
		if has_stream:
			audio_data_res = MediaCache.get_audio_data(stream)
		else:
			audio_data_res = MediaCache.default_audio_f32_data

var is_opening: bool
var audio_data_res: MediaCache.AudioF32Data = MediaCache.default_audio_f32_data

static func get_properties_section() -> StringName: return &"Sound"
static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
	&"title": "Audio",
	&"description": ""
}
func get_display_name() -> String: return str("Audio:", stream.get_file())
func get_thumbnail() -> Texture2D: return MediaServer.get_thumbnail(stream).texture

func get_min_from() -> float: return .0
func get_max_length() -> float:
	return audio_data_res.get_length() * ProjectServer2.fps if is_opening else +INF

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {&"stream": export(string_args(stream))}

func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	
	var player:= CustomAudioStreamPlayer.new()
	player.set_data(audio_data_res.get_data())
	player.bus = PlaybackServer.root_layer_get_bus_unique_name(root_layer_idx)
	return player

func enter(node: Node) -> void:
	super(node)
	Scene2.add_stream_player(self)

func exit(node: Node) -> void:
	super(node)
	Scene2.remove_stream_player(self)

func check_for_paths(paths_for_check: PackedStringArray) -> PackedStringArray:
	return [] if paths_for_check.has(stream) else [stream]

func format_paths(paths_for_format: Dictionary[String, String]) -> void:
	if paths_for_format.has(stream): stream = paths_for_format[stream]

func erase_paths(paths_for_erase: PackedStringArray) -> void:
	if paths_for_erase.has(stream): stream = ""

func update_paths() -> void:
	stream = stream
