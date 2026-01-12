extends Node

# images and audio stored one time and reused
@export var images: Dictionary[StringName, Image]
@export var textures: Dictionary[StringName, ImageTexture]
@export var videos_info: Dictionary[StringName, Dictionary]
@export var audio_stream_waves: Dictionary[StringName, AudioStreamWAV]
# videos and objects_ress stored many times for each MediaClipRes be on the timeline
@export var videos: Dictionary[MediaClipRes, Video]

func load_media_cache_from_file_system(file_system: DisplayFileSystemRes, thumbnail_path: String, waveform_path: String) -> void:
	var ids_exists: PackedStringArray = EditorServer.get_ids_from_pathes(DirAccess.get_files_at(thumbnail_path))
	file_system.loop_files_deep({}, func(path_or_name: StringName, file_info: Dictionary, info: Dictionary[StringName, Variant]) -> void:
		if file_info.type == "file":
			register_from_path(path_or_name, ids_exists, file_info.id, thumbnail_path, waveform_path)
	)

func get_images() -> Dictionary[StringName, Image]:
	return images

func get_textures() -> Dictionary[StringName, ImageTexture]:
	return textures

func get_audio_stream_waves() -> Dictionary[StringName, AudioStreamWAV]:
	return audio_stream_waves

func get_videos_info() -> Dictionary[StringName, Dictionary]:
	return videos_info

func get_videos() -> Dictionary[MediaClipRes, Video]:
	return videos

func register_from_path(path: StringName, ids_exists: PackedStringArray, id: String = "", thumbnail_path: String = "", waveform_path: String = "") -> int:
	var type: int = MediaServer.get_media_type_from_path(path)
	match type:
		0: register_image(path, ids_exists, id, thumbnail_path)
		1: register_video_info(path, ids_exists, id, thumbnail_path, waveform_path)
		2: register_audio(path, ids_exists, id, thumbnail_path, waveform_path)
	return type

func register_image(path: StringName, ids_exists: PackedStringArray, id: String, thumbnail_path: String) -> void:
	var image: Image = Image.load_from_file(path)
	images[path] = image
	textures[path] = ImageTexture.create_from_image(image)
	MediaServer.server_register_image(path, image, ids_exists, id, thumbnail_path)

func register_video_info(path: StringName, ids_exists: PackedStringArray, id: String, thumbnail_path: String, waveform_path: String) -> void:
	var audio_stream: AudioStreamWAV = AudioStreamHelper.create_stream_from_path(path)
	videos_info[path] = {
		&"frame_count": 0,
		&"frame_rate": 0,
		&"resolution": Vector2i.ZERO,
		&"audio": audio_stream
	}
	MediaServer.server_register_video(path, audio_stream, ids_exists, id, thumbnail_path, waveform_path)

func register_audio(path: StringName, ids_exists: PackedStringArray, id: String, thumbnail_path: String, waveform_path: String) -> void:
	var audio_stream: AudioStreamWAV = AudioStreamHelper.create_stream_from_path(path)
	audio_stream_waves[path] = audio_stream
	MediaServer.server_register_audio(path, audio_stream, ids_exists, id, thumbnail_path, waveform_path)

func push_video(media_res: MediaClipRes, path: StringName) -> void:
	var video: Video = Video.new()
	video.open(path)
	videos[media_res] = video

func get_image(key_as_path: StringName) -> Image:
	return images[key_as_path]

func get_texture(key_as_path: StringName) -> ImageTexture:
	return textures[key_as_path]

func get_video_info(path: StringName) -> Dictionary:
	return videos_info[path]

func get_audio(key_as_path: StringName) -> AudioStreamWAV:
	return audio_stream_waves[key_as_path]

func get_video(media_res: MediaClipRes) -> Video:
	return videos[media_res]
