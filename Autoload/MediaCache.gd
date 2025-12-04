extends Node

var type_get_indexer: Dictionary[int, Callable] = {
	0: get_image,
	1: get_video_info,
	2: get_audio
}

# images and audio stored one time and reused
@export var images: Dictionary[StringName, Image]
@export var textures: Dictionary[StringName, ImageTexture]
@export var videos_info: Dictionary[StringName, Dictionary]
@export var audio_stream_waves: Dictionary[StringName, AudioStreamWAV]
# videos and objects_ress stored many times for each MediaClipRes be on the timeline
@export var videos: Dictionary[MediaClipRes, Video]
#@export var objects_ress: Dictionary[MediaClipRes, UsableRes]

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

#func get_objects_ress() -> Dictionary[MediaClipRes, UsableRes]:
	#return objects_ress

func register_from_path(path: StringName) -> int:
	var type: int = MediaServer.get_media_type_from_path(path)
	match type:
		0: register_image(path)
		1: register_video_info(path)
		2: register_audio(path)
	return type

func register_image(path: StringName) -> void:
	var image: Image = Image.load_from_file(path)
	images[path] = image
	textures[path] = ImageTexture.create_from_image(image)
	MediaServer.create_thumbnail_from_image(path, image)

func register_video_info(path: StringName) -> void:
	var audio_stream: AudioStreamWAV = AudioStreamHelper.create_stream_from_path(path)
	videos_info[path] = {
		&"frame_count": 0,
		&"frame_rate": 0,
		&"resolution": Vector2i.ZERO,
		&"audio": audio_stream
	}
	MediaServer.create_thumbnail_from_video_path(path)
	MediaServer.create_timeline_waveform_textures_from_audio(path, audio_stream)

func register_audio(path: StringName) -> void:
	var audio_stream: AudioStreamWAV = AudioStreamHelper.create_stream_from_path(path)
	audio_stream_waves[path] = audio_stream
	MediaServer.create_thumbnail_from_audio(path, audio_stream)
	MediaServer.create_timeline_waveform_textures_from_audio(path, audio_stream)

func push_video(media_res: MediaClipRes, path: StringName) -> void:
	var video: Video = Video.new()
	video.open(path)
	videos[media_res] = video

func get_from_type(key_as_path: StringName, type: int) -> Variant:
	return type_get_indexer[type].call(key_as_path)

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







