@icon("res://Asset/Icons/Objects/audio-2d.png")
class_name Audio2DRes extends Object2DRes

@export var stream: DisplayFileSystemPath = DisplayFileSystemPath.new_sys_path(2):
	set(val):
		stream = val
		stream.res_changed.connect(try_change_stream)

@export var volume_db: float = .0
@export var pitch_scale: float = 1.
	#set(val):
		#
		#var pitch_ratio: float = pitch_scale / val
		#pitch_scale = val
		#
		#var target_length: int = owner.length / get_max_length() / pitch_scale
		#
		#if owner:
			#owner._emit_media_clip_res_updated(
				#owner.from,
				#owner.length * pitch_ratio
			#)

@export var max_distance: int = 2000
@export var attenuation: float = 1.
@export var panning_strength: float = 1.

func _init() -> void:
	stream.res_changed.connect(try_change_stream)

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var audio_player_2d:= AudioStreamPlayer2D.new()
	audio_player_2d.stream = MediaCache.get_audio(stream.disk_path)
	Scene2.instance_object_2d(parent_res, media_res, audio_player_2d, layer_index, frame_in, root_layer_index)
	return audio_player_2d

static func get_object_info() -> Dictionary[StringName, String]:
	return {
		&"title": "Audio2D",
		&"description": "Audio2D allows you not only to play sounds, but also to modify the source of the sound by changing the location of the Audio2D."
	}

static func get_object_section() -> StringName: return &"Sound"

func get_min_from() -> float:
	return 0 if curr_stream_exists() else -INF

func get_max_length() -> float:
	return MediaServer.get_media_default_length(2, stream.get_disk_path()) * ProjectServer.fps if curr_stream_exists() else INF

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"stream": export([stream]),
		&"volume_db": export(float_args(volume_db, -80., 24.)),
		&"pitch_scale": export(float_args(pitch_scale, .01, 1_000.)),
		&"max_distance": export(int_args(max_distance, 1, +INF)),
		&"attenuation": export(float_args(attenuation, .0, 1_000_000)),
		&"panning_strength": export(float_args(panning_strength, .0, +INF))
	}

func _exported_props_controllers_created(props_controllers: Dictionary[StringName, Control]) -> void:
	var pitch_scale_ctrlr: FloatController = props_controllers.pitch_scale.controller
	pitch_scale_ctrlr.change_value_when_drag = false

func _process(frame: int) -> void:
	submit_stacked_values({
		&"volume_db": volume_db,
		&"pitch_scale": pitch_scale,
		&"max_distance": max_distance,
		&"attenuation": attenuation,
		&"panning_strength": panning_strength
	})

func format_path(paths_for_format: Dictionary[String, String]) -> void:
	stream.format_path(paths_for_format)

func curr_stream_exists() -> bool:
	return stream != null and MediaCache.audio_stream_waves_has(stream.get_disk_path())

func try_change_stream() -> void:
	if owner:
		owner.call_node_method_if(&"set", [&"stream", MediaCache.get_audio(stream.disk_path)])
		owner._emit_media_clip_res_updated()

func duplicate_component_res() -> ComponentRes:
	var dupl_res: Audio2DRes = super()
	dupl_res.stream.update_disk_path()
	return dupl_res
