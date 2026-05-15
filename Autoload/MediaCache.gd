#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
##  This program is free software: you can redistribute it and/or modify   ##
##  it under the terms of the GNU General Public License as published by   ##
##  the Free Software Foundation, either version 3 of the License, or      ##
##  (at your option) any later version.                                    ##
##                                                                         ##
##  This program is distributed in the hope that it will be useful,        ##
##  but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           ##
##  GNU General Public License for more details.                           ##
##                                                                         ##
##  You should have received a copy of the GNU General Public License      ##
##  along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
extends Node

enum LOAD_ERR {
	SUCCESS,
	LOAD_ERR_ALREADY_EXISTS,
	LOAD_ERR_CANT_OPEN,
	LOAD_ERR_INVALID_PATH
}
const LOAD_ERR_STR: PackedStringArray = [
	
]

@export var images: Dictionary[StringName, Image]
@export var textures: Dictionary[StringName, ImageTexture]
@export var video_contexts: Dictionary[StringName, VideoContext]
@export var audio_datas: Dictionary[StringName, AudioF32Data]
@export var preset_media_ress: Dictionary[StringName, MediaClipRes]

var default_audio_f32_data: AudioF32Data = AudioF32Data.new(PackedByteArray())


func _ready() -> void:
	EditorServer.editor_settings.settings_updated.connect(_on_editor_settings_settings_updated)


func load_media_cache_from_file_system(file_system: DisplayFileSystemRes) -> void:
	
	var thumb_path: String = file_system.thumbnail_path
	var waveform_path: String = file_system.waveform_path
	var ids_exists: PackedStringArray = EditorServer.get_ids_from_pathes(DirAccess.get_files_at(thumb_path))
	file_system.loop_files_deep({}, func(dir: Dictionary, path_or_name: StringName, file_info: Dictionary, info: Dictionary[StringName, Variant]) -> void:
		if file_info.type == "file":
			register_from_path(path_or_name, ids_exists, file_info.id, -1, thumb_path, waveform_path)
	)
	video_contexts_update_max_cache_size()

func images_has(key_as_path: StringName) -> bool: return images.has(key_as_path)
func video_contexts_has(key_as_path: StringName) -> bool: return video_contexts.has(key_as_path)
func audio_datas_has(key_as_path: StringName) -> bool: return audio_datas.has(key_as_path)
func preset_media_ress_has(key_as_path: StringName) -> bool: return preset_media_ress.has(key_as_path)

func get_images() -> Dictionary[StringName, Image]: return images
func get_textures() -> Dictionary[StringName, ImageTexture]: return textures
func get_audio_datas() -> Dictionary[StringName, AudioF32Data]: return audio_datas
func get_video_contexts() -> Dictionary[StringName, VideoContext]: return video_contexts
func get_preset_media_ress() -> Dictionary[StringName, MediaClipRes]: return preset_media_ress

func get_image(key_as_path: StringName) -> Image: return images.get(key_as_path)
func get_texture(key_as_path: StringName) -> ImageTexture: return textures.get(key_as_path)
func get_video_context(key_as_path: StringName) -> VideoContext: return video_contexts.get(key_as_path)
func get_audio_data(key_as_path: StringName) -> AudioF32Data: return audio_datas.get(key_as_path)
func get_preset_media_res(key_as_path: StringName) -> MediaClipRes: return preset_media_ress.get(key_as_path)

func register_from_path(path: StringName, ids_exists: PackedStringArray, id: String = "", media_type: int = -1, thumbnail_path: String = "", waveform_path: String = "") -> LOAD_ERR:
	if media_type == -1:
		media_type = MediaServer.get_media_type_from_path(path)
	
	if not FileAccess.file_exists(path) and media_type != -1:
		return LOAD_ERR.LOAD_ERR_INVALID_PATH
	
	match media_type:
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
	
	if video_contexts_has(path):
		return LOAD_ERR.LOAD_ERR_ALREADY_EXISTS
	
	var video_decoder: VideoDecoder = VideoDecoder.new()
	video_decoder.set_internal_enhance(false)
	video_decoder.set_video_path(path)
	
	for try_time: int in 5:
		
		if not video_decoder.open():
			continue
		
		var total_frames: int = video_decoder.get_total_frames_native()
		if total_frames < 1:
			total_frames = video_decoder.get_total_frames_by_timebase()
			if total_frames < 1:
				total_frames = video_decoder.get_total_frames_by_dur()
		
		var video_ctx: VideoContext = VideoContext.new()
		video_ctx.video_path = path
		video_ctx.resolution = video_decoder.get_resolution()
		video_ctx.duration = video_decoder.get_duration()
		video_ctx.fps = video_decoder.get_fps()
		video_ctx.total_frames = total_frames
		video_ctx.bit_depth = video_decoder.get_bit_depth()
		video_contexts[path] = video_ctx
		
		var streams_data: Array[PackedByteArray] = AudioHelper.create_data_from_path(path)
		var audio_data_res: AudioF32Data = null if streams_data.is_empty() else AudioF32Data.new(streams_data[0])
		
		audio_datas[path] = audio_data_res
		
		MediaServer.server_register_video(path, video_decoder, audio_data_res, ids_exists, id, thumbnail_path, waveform_path)
		
		return LOAD_ERR.SUCCESS
	
	return LOAD_ERR.LOAD_ERR_CANT_OPEN


func register_audio(path: StringName, ids_exists: PackedStringArray, id: String, thumbnail_path: String, waveform_path: String) -> LOAD_ERR:
	if not FileAccess.file_exists(path): return LOAD_ERR.LOAD_ERR_INVALID_PATH
	
	if audio_datas_has(path):
		return LOAD_ERR.LOAD_ERR_ALREADY_EXISTS
	
	var streams_data: Array[PackedByteArray] = AudioHelper.create_data_from_path(path)
	
	if streams_data.is_empty():
		return LOAD_ERR.LOAD_ERR_CANT_OPEN
	
	var audio_data: PackedByteArray = streams_data[0]
	var audio_data_res:= AudioF32Data.new(audio_data)
	audio_datas[path] = audio_data_res
	
	MediaServer.server_register_audio(path, audio_data_res, ids_exists, id, thumbnail_path, waveform_path)
	
	return LOAD_ERR.SUCCESS

func register_preset_media_res(path: StringName, ids_exists: PackedStringArray, id: String, thumbnail_path: String) -> LOAD_ERR:
	
	if preset_media_ress_has(path):
		return LOAD_ERR.LOAD_ERR_ALREADY_EXISTS
	
	var preset_media_res: Resource = ResourceLoader.load(path)
	
	if not preset_media_res:
		preset_media_res = MediaServer.get_not_saved_resource(path)
		
		if not preset_media_res:
			return LOAD_ERR.LOAD_ERR_CANT_OPEN
	
	if preset_media_res is not MediaClipRes:
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
			video_contexts[to] = video_contexts[from]
		
		2:
			audio_datas[to] = audio_datas[from]
			audio_datas.erase(from)
		
		_:
			preset_media_ress[to] = preset_media_ress[from]
			preset_media_ress.erase(from)
	
	MediaServer.server_replace_media_path(from, to)


func deregister_from_path(path: StringName, id: String, thumbnail_path: String, waveform_path: String, delete_images_on_disk: bool = false) -> void:
	match MediaServer.get_media_type_from_path(path):
		0: deregister_image(path, id, thumbnail_path, delete_images_on_disk)
		1: deregister_video(path, id, thumbnail_path, waveform_path, delete_images_on_disk)
		2: deregister_audio(path, id, thumbnail_path, waveform_path, delete_images_on_disk)
		_: deregister_preset_media_res(path, id, thumbnail_path, waveform_path)


func deregister_image(path: StringName, id: String, thumbnail_path: String, delete_images_on_disk: bool = false) -> void:
	MediaServer.server_deregister_image(path, id, thumbnail_path, delete_images_on_disk)
	images.erase(path)
	textures.erase(path)

func deregister_video(path: StringName, id: String, thumbnail_path: String, waveform_path: String, delete_images_on_disk: bool = false) -> void:
	MediaServer.server_deregister_video(path, id, thumbnail_path, waveform_path, delete_images_on_disk)
	video_contexts.erase(path)

func deregister_audio(path: StringName, id: String, thumbnail_path: String, waveform_path: String, delete_images_on_disk: bool = false) -> void:
	MediaServer.server_deregister_audio(path, id, thumbnail_path, waveform_path, delete_images_on_disk)
	audio_datas.erase(path)

func deregister_preset_media_res(path: StringName, id: String, thumbnail_path: String, waveform_path: String) -> void:
	preset_media_ress.erase(path)



func clear_all_cache() -> void:
	images.clear()
	textures.clear()
	video_contexts.clear()
	audio_datas.clear()
	preset_media_ress.clear()
	MediaServer.clear_media_server()


func video_contexts_clear_video_decoders() -> void:
	for key_as_path: StringName in video_contexts:
		video_contexts[key_as_path].clear_video_decoders()

func video_contexts_clear_frames() -> void:
	for key_as_path: StringName in video_contexts:
		video_contexts[key_as_path].clear_frames()

func video_contexts_update_max_cache_size() -> void:
	
	var size_remained: int = EditorServer.editor_settings.performance.video_max_frame_cache
	var size_per_video: int = size_remained / maxi(1, video_contexts.size())
	
	for path: StringName in video_contexts:
		
		var ctx: VideoContext = video_contexts[path]
		var video_total_frames: int = ctx.total_frames
		var max_cache_size: int = mini(size_per_video, video_total_frames)
		ctx.max_cache_size = max_cache_size
		
		size_remained -= max_cache_size


class VideoContext extends Resource:
	
	@export var video_path: String
	@export var resolution: Vector2i
	@export var duration: float
	@export var fps: float
	@export var total_frames: int
	@export var bit_depth: int
	
	@export var video_decoders: Array[VideoDecoder]
	
	@export var max_cache_size: int:
		set(val):
			max_cache_size = maxi(10, val)
			clear_excess_frames()
	@export var cache: Dictionary = {}
	@export var frames: PackedInt32Array
	
	func get_resolution() -> Vector2i: return resolution
	func get_duration() -> float: return duration
	func get_fps() -> float: return fps
	func get_total_frames() -> int: return total_frames
	func get_bit_depth() -> int: return bit_depth
	
	func set_resolution(new_val: Vector2i) -> void: resolution = new_val
	func set_duration(new_val: float) -> void: duration = new_val
	func set_fps(new_val: float) -> void: fps = new_val
	func set_total_frames(new_val: int) -> void: total_frames = new_val
	func set_bit_depth(new_val: int) -> void: bit_depth = new_val
	
	func request_video_decoder() -> VideoDecoder:
		if video_decoders.is_empty():
			var new_one: VideoDecoder = VideoDecoder.new()
			new_one.set_video_path(video_path)
			new_one.set_internal_enhance(EditorServer.use_high_quality())
			new_one.open()
			return new_one
		else:
			return video_decoders.pop_back()
	
	func push_video_decoder_front(video_decoder: VideoDecoder) -> void:
		video_decoders.insert(0, video_decoder)
	
	func clear_video_decoders() -> void:
		video_decoders.clear()
	
	func has_frame(frame: int) -> bool: return frames.has(frame)
	func get_frame(frame: int) -> Array[Texture2D]: return cache.get(frame, [] as Array[Texture2D])
	func push_frame(frame: int, frame_textures: Array[Texture2D]) -> void:
		cache[frame] = frame_textures
		if cache.size() >= max_cache_size:
			var oldest_frame: int = frames[0]
			cache.erase(oldest_frame)
			frames.remove_at(0)
		frames.append(frame)
	func clear_frames() -> void: cache.clear(); frames.clear()
	func clear_excess_frames() -> void:
		var excess_frames_count: int = maxi(0, frames.size() - max_cache_size)


class AudioF32Data extends Resource:
	
	const CHANNELS: int = 2
	const SAMPLE_RATE: int = 48000
	const BYTES_PER_SAMPLE = 4 # float32 = 4bytes
	const BYTES_PER_FRAME: int = 4 * 2
	
	@export var data: PackedByteArray:
		set(val):
			data = val
			length = data.size() / float(BYTES_PER_FRAME * SAMPLE_RATE)
	
	@export var length: float
	
	func _init(_data: PackedByteArray) -> void:
		data = _data
	
	func get_data() -> PackedByteArray: return data
	func set_data(new_data: PackedByteArray) -> void: data = new_data
	
	func get_length() -> float: return length
	func set_length(new_val: float) -> void: length = new_val
	
	func extract_frame_samples(frame: int) -> PackedByteArray:
		
		var samples_per_frame: int = SAMPLE_RATE / ProjectServer2.fps
		var bytes_per_video_frame: int = samples_per_frame * BYTES_PER_FRAME
		
		var start: int = frame * bytes_per_video_frame
		var size: int = bytes_per_video_frame
		
		if start >= data.size():
			return PackedByteArray()
		
		return data.slice(start, start + size)


func _on_editor_settings_settings_updated() -> void:
	video_contexts_update_max_cache_size()


