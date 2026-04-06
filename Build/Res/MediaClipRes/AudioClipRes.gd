@icon("res://Asset/Icons/Objects/audio.png")
class_name AudioClipRes extends MediaClipRes

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
	&"title": "Audio",
	&"description": ""
}
func get_display_name() -> String: return str("Audio:", stream.get_file())
func get_thumbnail() -> Texture2D: return MediaServer.get_thumbnail(stream).texture

func get_min_from() -> float: return .0
func get_max_length() -> float:
	return audio_stream.get_length() * ProjectServer2.fps if audio_stream else +INF

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {&"stream": export(string_args(stream))}

func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	var player:= AudioStreamPlayer.new()
	player.stream = audio_stream
	player.bus = PlaybackServer.root_layer_get_bus_unique_name(root_layer_idx)
	return player

func enter(node: Node) -> void:
	super(node)
	Scene2.add_stream_player(self)

func exit(node: Node) -> void:
	super(node)
	Scene2.remove_stream_player(self)

