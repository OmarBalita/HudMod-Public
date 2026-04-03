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
@export var videos_cache: Dictionary[StringName, VideoCache]


func _ready() -> void:
	EditorServer.editor_settings.settings_updated.connect(_on_editor_settings_settings_updated)


func load_media_cache_from_file_system(file_system: DisplayFileSystemRes) -> void:
	var thumb_path: String = file_system.thumbnail_path
	var waveform_path: String = file_system.waveform_path
	var ids_exists: PackedStringArray = EditorServer.get_ids_from_pathes(DirAccess.get_files_at(thumb_path))
	file_system.loop_files_deep({}, func(dir: Dictionary, path_or_name: StringName, file_info: Dictionary, info: Dictionary[StringName, Variant]) -> void:
		if file_info.type == "file":
			register_from_path(path_or_name, ids_exists, file_info.id, thumb_path, waveform_path)
	)
	update_videos_cache_max_cache_size()

func images_has(key_as_path: StringName) -> bool: return images.has(key_as_path)
func videos_info_has(key_as_path: StringName) -> bool: return videos_info.has(key_as_path)
func audio_stream_waves_has(key_as_path: StringName) -> bool: return audio_stream_waves.has(key_as_path)
func preset_media_ress_has(key_as_path: StringName) -> bool: return preset_media_ress.has(key_as_path)

func get_images() -> Dictionary[StringName, Image]: return images
func get_textures() -> Dictionary[StringName, ImageTexture]: return textures
func get_audio_stream_waves() -> Dictionary[StringName, AudioStreamWAV]: return audio_stream_waves
func get_videos_info() -> Dictionary[StringName, Dictionary]: return videos_info
func get_preset_media_ress() -> Dictionary[StringName, MediaClipRes]: return preset_media_ress

func get_image(key_as_path: StringName) -> Image: return images.get(key_as_path)
func get_texture(key_as_path: StringName) -> ImageTexture: return textures.get(key_as_path)
func get_video_info(path: StringName) -> Dictionary: return videos_info.get(path)
func get_audio(key_as_path: StringName) -> AudioStreamWAV: return audio_stream_waves.get(key_as_path)
func get_preset_media_res(key_as_path: StringName) -> MediaClipRes: return preset_media_ress.get(key_as_path)

func register_from_path(path: StringName, ids_exists: PackedStringArray, id: String = "", thumbnail_path: String = "", waveform_path: String = "") -> LOAD_ERR:
	if not FileAccess.file_exists(path):
		return LOAD_ERR.LOAD_ERR_INVALID_PATH
	var type: int = MediaServer.get_media_type_from_path(path)
	
	match type:
		0: return register_image(path, ids_exists, id, thumbnail_path)
		1: return register_video(path, ids_exists, id, thumbnail_path, waveform_path)
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

func register_video(path: StringName, ids_exists: PackedStringArray, id: String, thumbnail_path: String, waveform_path: String) -> LOAD_ERR:
	
	if videos_info_has(path):
		return LOAD_ERR.LOAD_ERR_ALREADY_EXISTS
	
	var audio_stream: AudioStreamWAV = AudioStreamHelper.create_stream_from_path(path)
	var video_decoder: VideoDecoder = VideoDecoder.new()
	video_decoder.set_internal_enhance(false)
	video_decoder.set_video_path(path)
	
	if not video_decoder.open():
		return LOAD_ERR.LOAD_ERR_CANT_OPEN
	
	var total_frames: int = video_decoder.get_total_frames_native()
	if total_frames < 1:
		total_frames = video_decoder.get_total_frames_by_timebase()
		if total_frames < 1:
			total_frames = video_decoder.get_total_frames_by_dur()
	
	videos_info[path] = {
		&"resolution": video_decoder.get_resolution(),
		&"duration": video_decoder.get_duration(),
		&"fps": video_decoder.get_fps(),
		&"total_frames": total_frames,
		&"bit_depth": video_decoder.get_bit_depth()
	}
	videos_cache[path] = VideoCache.new()
	audio_stream_waves[path] = audio_stream
	
	MediaServer.server_register_video(path, video_decoder, audio_stream, ids_exists, id, thumbnail_path, waveform_path)
	
	video_decoder.close()
	
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
		1: deregister_video(path, id, thumbnail_path, waveform_path)
		2: deregister_audio(path, id, thumbnail_path, waveform_path)
		_: deregister_preset_media_res(path, id, thumbnail_path, waveform_path)


func deregister_image(path: StringName, id: String, thumbnail_path: String) -> void:
	MediaServer.server_deregister_image(path, id, thumbnail_path)
	images.erase(path)
	textures.erase(path)

func deregister_video(path: StringName, id: String, thumbnail_path: String, waveform_path: String) -> void:
	MediaServer.server_deregister_video(path, id, thumbnail_path, waveform_path)
	videos_info.erase(path)
	videos_cache.erase(path)

func deregister_audio(path: StringName, id: String, thumbnail_path: String, waveform_path: String) -> void:
	MediaServer.server_deregister_audio(path, id, thumbnail_path, waveform_path)
	audio_stream_waves.erase(path)

func deregister_preset_media_res(path: StringName, id: String, thumbnail_path: String, waveform_path: String) -> void:
	preset_media_ress.erase(path)



func get_video_cache(path: StringName) -> VideoCache:
	return videos_cache[path]

func get_frame_from_video_cache(path: StringName, frame: int) -> Array[Texture2D]:
	return videos_cache[path].get_frame(frame)

func push_frame_to_video_cache(path: StringName, frame: int, textures: Array[Texture2D]) -> void:
	if videos_cache.has(path):
		videos_cache[path].push_frame(frame, textures)

func clear_video_cache_frames(path: StringName) -> void:
	videos_cache[path].clear_frames()

func update_videos_cache_max_cache_size() -> void:
	
	var size_remained: int = EditorServer.editor_settings.video_max_frame_cache
	var size_per_video: int = size_remained / maxi(1, videos_info.size())
	
	for path: StringName in videos_cache:
		
		var video_total_frames: int = get_video_info(path).total_frames
		var video_cache: VideoCache = videos_cache[path]
		var max_cache_size: int = mini(size_per_video, video_total_frames)
		video_cache.max_cache_size = max_cache_size
		
		size_remained -= max_cache_size


class VideoCache extends Resource:
	
	@export var max_cache_size: int:
		set(val):
			max_cache_size = maxi(50, val)
			clear_excess_frames()
	
	@export var cache: Dictionary = {}
	
	@export var frames: PackedInt32Array
	
	func has_frame(frame: int) -> bool:
		return frames.has(frame)
	
	func get_frame(frame: int) -> Array[Texture2D]:
		return cache.get(frame, [] as Array[Texture2D])
	
	func push_frame(frame: int, frame_textures: Array[Texture2D]) -> void:
		cache[frame] = frame_textures
		
		if cache.size() >= max_cache_size:
			var oldest_frame: int = frames[0]
			cache.erase(oldest_frame)
			frames.remove_at(0)
		
		frames.append(frame)
	
	func clear_frames() -> void:
		cache.clear()
	
	func clear_excess_frames() -> void:
		var excess_frames_count: int = maxi(0, frames.size() - max_cache_size)



func _on_editor_settings_settings_updated() -> void:
	update_videos_cache_max_cache_size()



