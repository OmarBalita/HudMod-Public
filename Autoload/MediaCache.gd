extends Node

enum LOAD_ERR {
	SUCCESS,
	LOAD_ERR_ALREADY_EXISTS,
	LOAD_ERR_CANT_OPEN,
	LOAD_ERR_INVALID_PATH
}
const LOAD_ERR_STR: PackedStringArray = [
	
]

# images and audio stored one time and reused
@export var images: Dictionary[StringName, Image]
@export var textures: Dictionary[StringName, ImageTexture]
@export var videos_info: Dictionary[StringName, Dictionary]
@export var audio_stream_waves: Dictionary[StringName, AudioStreamWAV]
@export var preset_media_ress: Dictionary[StringName, MediaClipRes]
# videos stored many times for each MediaClipRes be on the timeline
@export var videos: Dictionary[MediaClipRes, Video]

func load_media_cache_from_file_system(file_system: DisplayFileSystemRes) -> void:
	var thumb_path: String = file_system.thumbnail_path
	var waveform_path: String = file_system.waveform_path
	var ids_exists: PackedStringArray = EditorServer.get_ids_from_pathes(DirAccess.get_files_at(thumb_path))
	file_system.loop_files_deep({}, func(dir: Dictionary, path_or_name: StringName, file_info: Dictionary, info: Dictionary[StringName, Variant]) -> void:
		if file_info.type == "file":
			register_from_path(path_or_name, ids_exists, file_info.id, thumb_path, waveform_path)
	)

func images_has(key_as_path: StringName) -> bool: return images.has(key_as_path)
func videos_info_has(key_as_path: StringName) -> bool: return videos_info.has(key_as_path)
func audio_stream_waves_has(key_as_path: StringName) -> bool: return audio_stream_waves.has(key_as_path)
func preset_media_ress_has(key_as_path: StringName) -> bool: return preset_media_ress.has(key_as_path)

func get_images() -> Dictionary[StringName, Image]: return images
func get_textures() -> Dictionary[StringName, ImageTexture]: return textures
func get_audio_stream_waves() -> Dictionary[StringName, AudioStreamWAV]: return audio_stream_waves
func get_videos_info() -> Dictionary[StringName, Dictionary]: return videos_info
func get_videos() -> Dictionary[MediaClipRes, Video]: return videos
func get_preset_media_ress() -> Dictionary[StringName, MediaClipRes]: return preset_media_ress

func get_image(key_as_path: StringName) -> Image: return images.get(key_as_path)
func get_texture(key_as_path: StringName) -> ImageTexture: return textures.get(key_as_path)
func get_video_info(path: StringName) -> Dictionary: return videos_info.get(path)
func get_audio(key_as_path: StringName) -> AudioStreamWAV: return audio_stream_waves.get(key_as_path)
func get_preset_media_res(key_as_path: StringName) -> MediaClipRes: return preset_media_ress.get(key_as_path)
func get_video(media_res: MediaClipRes) -> Video: return videos[media_res]

func register_from_path(path: StringName, ids_exists: PackedStringArray, id: String = "", thumbnail_path: String = "", waveform_path: String = "") -> LOAD_ERR:
	if not FileAccess.file_exists(path):
		return LOAD_ERR.LOAD_ERR_INVALID_PATH
	var type: int = MediaServer.get_media_type_from_path(path)
	match type:
		0: return register_image(path, ids_exists, id, thumbnail_path)
		1: return register_video_info(path, ids_exists, id, thumbnail_path, waveform_path)
		2: return register_audio(path, ids_exists, id, thumbnail_path, waveform_path)
		_: return register_preset_media_res(path, ids_exists, thumbnail_path, waveform_path)

func register_image(path: StringName, ids_exists: PackedStringArray, id: String, thumbnail_path: String) -> LOAD_ERR:
	if images_has(path):
		return LOAD_ERR.LOAD_ERR_ALREADY_EXISTS
	var image: Image = Image.load_from_file(path)
	if image == null:
		return LOAD_ERR.LOAD_ERR_CANT_OPEN
	images[path] = image
	textures[path] = ImageTexture.create_from_image(image)
	if image: MediaServer.server_register_image(path, image, ids_exists, id, thumbnail_path)
	return LOAD_ERR.SUCCESS

func register_video_info(path: StringName, ids_exists: PackedStringArray, id: String, thumbnail_path: String, waveform_path: String) -> LOAD_ERR:
	if videos_info_has(path):
		return LOAD_ERR.LOAD_ERR_ALREADY_EXISTS
	var audio_stream: AudioStreamWAV = AudioStreamHelper.create_stream_from_path(path)
	videos_info[path] = {
		&"frame_count": 0,
		&"frame_rate": 0,
		&"resolution": Vector2i.ZERO,
		&"audio": audio_stream
	}
	MediaServer.server_register_video(path, audio_stream, ids_exists, id, thumbnail_path, waveform_path)
	return LOAD_ERR.SUCCESS

func register_audio(path: StringName, ids_exists: PackedStringArray, id: String, thumbnail_path: String, waveform_path: String) -> LOAD_ERR:
	if audio_stream_waves_has(path):
		return LOAD_ERR.LOAD_ERR_ALREADY_EXISTS
	var audio_stream: AudioStreamWAV = AudioStreamHelper.create_stream_from_path(path)
	if audio_stream == null:
		return LOAD_ERR.LOAD_ERR_CANT_OPEN
	audio_stream_waves[path] = audio_stream
	MediaServer.server_register_audio(path, audio_stream, ids_exists, id, thumbnail_path, waveform_path)
	return LOAD_ERR.SUCCESS

func register_preset_media_res(path: StringName, ids_exists: PackedStringArray, id: String, thumbnail_path: String) -> LOAD_ERR:
	if preset_media_ress_has(path):
		return LOAD_ERR.LOAD_ERR_ALREADY_EXISTS
	
	var preset_media_res: Resource = ResourceLoader.load(path)
	if preset_media_res is not MediaClipRes:
		return LOAD_ERR.LOAD_ERR_CANT_OPEN
	
	if not preset_media_res:
		preset_media_res = MediaServer.get_not_saved_resource(path)
		if not preset_media_ress:
			return LOAD_ERR.LOAD_ERR_CANT_OPEN
	
	preset_media_ress[path] = preset_media_res
	return LOAD_ERR.SUCCESS

func push_video(media_res: MediaClipRes, path: StringName) -> void:
	var video: Video = Video.new()
	video.open(path)
	videos[media_res] = video

func replace_path(from: StringName, to: StringName) -> void:
	match MediaServer.get_media_type_from_path(from):
		0:
			images[to] = images[from]
			textures[to] = textures[from]
			images.erase(from)
			textures.erase(from)
		
		1:
			videos_info[to] = videos_info[from]
			videos_info.erase(from)
		
		2:
			audio_stream_waves[to] = audio_stream_waves[from]
			audio_stream_waves.erase(from)
		
		_:
			preset_media_ress[to] = preset_media_ress[from]
			preset_media_ress.erase(from)
	
	MediaServer.server_replace_media_path(from, to)


func deregister_from_path(path: StringName, id: String, thumbnail_path: String, waveform_path: String) -> void:
	match MediaServer.get_media_type_from_path(path):
		0: deregister_image(path, id, thumbnail_path)
		1: deregister_video_info(path, id, thumbnail_path, waveform_path)
		2: deregister_audio(path, id, thumbnail_path, waveform_path)
		_: deregister_preset_media_res(path, id, thumbnail_path, waveform_path)


func deregister_image(path: StringName, id: String, thumbnail_path: String) -> void:
	MediaServer.server_deregister_image(path, id, thumbnail_path)
	images.erase(path)
	textures.erase(path)

func deregister_video_info(path: StringName, id: String, thumbnail_path: String, waveform_path: String) -> void:
	MediaServer.server_deregister_video(path, id, thumbnail_path, waveform_path)
	videos_info.erase(path)

func deregister_audio(path: StringName, id: String, thumbnail_path: String, waveform_path: String) -> void:
	MediaServer.server_deregister_audio(path, id, thumbnail_path, waveform_path)
	audio_stream_waves.erase(path)

func deregister_preset_media_res(path: StringName, id: String, thumbnail_path: String, waveform_path: String) -> void:
	preset_media_ress.erase(path)





