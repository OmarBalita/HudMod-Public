extends Node

enum MediaTypes {
	IMAGE,
	VIDEO,
	AUDIO,
	EMPTY_OBJECT_2D,
	TEXT,
	DRAW,
	PARTICLES,
	CAMERA_2D,
	AUDIO_2D
}

const IMAGE_FORMAT_INDEXER: Dictionary[int, String] = {
	Image.FORMAT_L8: "FORMAT_L8",
	Image.FORMAT_LA8: "FORMAT_LA8",
	Image.FORMAT_R8: "FORMAT_R8",
	Image.FORMAT_RG8: "FORMAT_RG8",
	Image.FORMAT_RGB8: "FORMAT_RGB8",
	Image.FORMAT_RGBA8: "FORMAT_RGBA8",
	Image.FORMAT_RGBA4444: "FORMAT_RGBA4444",
	Image.FORMAT_RGB565: "FORMAT_RGB565",
	Image.FORMAT_RF: "FORMAT_RF",
	Image.FORMAT_RGF: "FORMAT_RGF",
	Image.FORMAT_RGBF: "FORMAT_RGBF",
	Image.FORMAT_RGBAF: "FORMAT_RGBAF",
	Image.FORMAT_RH: "FORMAT_RH",
	Image.FORMAT_RGH: "FORMAT_RGH",
	Image.FORMAT_RGBH: "FORMAT_RGBH",
	Image.FORMAT_RGBAH: "FORMAT_RGBAH",
	Image.FORMAT_RGBE9995: "FORMAT_RGBE9995",
	Image.FORMAT_DXT1: "FORMAT_DXT1",
	Image.FORMAT_DXT3: "FORMAT_DXT3",
	Image.FORMAT_DXT5: "FORMAT_DXT5",
	Image.FORMAT_RGTC_R: "FORMAT_RGTC_R",
	Image.FORMAT_RGTC_RG: "FORMAT_RGTC_RG",
	Image.FORMAT_BPTC_RGBA: "FORMAT_BPTC_RGBA",
	Image.FORMAT_BPTC_RGBF: "FORMAT_BPTC_RGBF",
	Image.FORMAT_BPTC_RGBFU: "FORMAT_BPTC_RGBFU",
	Image.FORMAT_ETC: "FORMAT_ETC",
	Image.FORMAT_ETC2_R11: "FORMAT_ETC2_R11",
	Image.FORMAT_ETC2_R11S: "FORMAT_ETC2_R11S",
	Image.FORMAT_ETC2_RG11: "FORMAT_ETC2_RG11",
	Image.FORMAT_ETC2_RG11S: "FORMAT_ETC2_RG11S",
	Image.FORMAT_ETC2_RGB8: "FORMAT_ETC2_RGB8",
	Image.FORMAT_ETC2_RGBA8: "FORMAT_ETC2_RGBA8",
	Image.FORMAT_ETC2_RGB8A1: "FORMAT_ETC2_RGB8A1",
	Image.FORMAT_ETC2_RA_AS_RG: "FORMAT_ETC2_RA_AS_RG",
	Image.FORMAT_DXT5_RA_AS_RG: "FORMAT_DXT5_RA_AS_RG",
	Image.FORMAT_ASTC_4x4: "FORMAT_ASTC_4x4",
	Image.FORMAT_ASTC_4x4_HDR: "FORMAT_ASTC_4x4_HDR",
	Image.FORMAT_ASTC_8x8: "FORMAT_ASTC_8x8",
	Image.FORMAT_ASTC_8x8_HDR: "FORMAT_ASTC_8x8_HDR",
	Image.FORMAT_MAX: "FORMAT_MAX"
}

const IMAGE_EXTENSIONS: PackedStringArray = [
	"png", "jpg", "jpeg", "bmp", "webp", "tga", "tif", "tiff",
	"svg", "hdr", "exr", "dds"
]
const VIDEO_EXTENSIONS: PackedStringArray = [
	"webm","mkv","flv","vob","ogv","ogg","mng","avi","mts","m2ts","ts","mov",
	"qt","wmv","yuv","rm","rmvb","viv","asf","amv","mp4","m4p","mp2","mpe",
	"mpv","mpg","mpeg","m2v","m4v","svi","3gp","3g2","mxf","roq","nsv","flv",
	"f4v","f4p","f4a","f4b"
]
const AUDIO_EXTENSIONS: PackedStringArray = ["wav", "ogg", "mp3", "flac", "opus"]
const MEDIA_EXTENSIONS: PackedStringArray = IMAGE_EXTENSIONS + VIDEO_EXTENSIONS + AUDIO_EXTENSIONS
const ARR_MEDIA_EXTENSIONS: Array[PackedStringArray] = [IMAGE_EXTENSIONS, VIDEO_EXTENSIONS, AUDIO_EXTENSIONS]

var object_clip_info: Dictionary[StringName, Dictionary] = {
	&"Display2DClipRes": {sections = [&"Display2D"]},
	&"ImageClipRes": {sections = [&"Display2D", &"Image", &"Color", &"Transition"], clip_panel = ImageClipPanel, color = Color("ffcb59"), icon = preload("res://Asset/Icons/Objects/image.png")},
	&"VideoClipRes": {sections = [&"Display2D", &"Image", &"Color", &"Transition", &"Sound"], clip_panel = VideoClipPanel, color = Color("7ae65c"), icon = preload("res://Asset/Icons/Objects/video.png")},
	&"AudioClipRes": {sections = [&"Sound"], clip_panel = AudioClipPanel, color = Color("62c4f5"), icon = preload("res://Asset/Icons/Objects/audio.png")},
	&"Text2DClipRes": {sections = [&"Display2D", &"Text"]},
	&"Shape2DClipRes": {sections = [&"Display2D", &"Shape"]},
	&"Particles2DClipRes": {sections = [&"Display2D", &"Particles"]},
	&"Camera2DClipRes": {sections = [&"Display2D", &"Camera"]},
	&"Audio2DClipRes": {sections = [&"Display2D", &"Sound"], clip_panel = Audio2DClipPanel}
}

const THUMBNAIL_TARGET_WIDTH: int = 128
const TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH: int = 2048

const THUMBNAIL_DISCARD: Dictionary = {&"texture": IS.TEXTURE_X_MARK}

var thumbnails: Dictionary[StringName, Dictionary]
var timeline_video_textures: Dictionary[StringName, Dictionary]
var timeline_waveform_textures: Dictionary[StringName, Dictionary]

var not_saved_yet: Dictionary[String, Resource] = {}
var not_deleted_yet: Array[String] = []


func _init() -> void:
	MediaHelper.SetWaveformGradient(EditorServer.editor_settings.media_explorer_waveform_gradient)


func clear_media_server() -> void:
	thumbnails.clear()
	timeline_video_textures.clear()
	timeline_waveform_textures.clear()
	not_saved_yet.clear()
	not_deleted_yet.clear()


func server_register_image(path: String, image: Image, ids_exists: PackedStringArray, id: String, thumbnail_path: String) -> void:
	if ids_exists.has(id): load_thumbnail(path, thumbnail_path, id)
	else: create_thumbnail_from_image(path, image, thumbnail_path, id)

func server_register_video(path: String, video_decoder: VideoDecoder, audio_data_res: MediaCache.AudioF32Data, ids_exists: PackedStringArray, id: String, thumbnail_path: String, waveform_path: String) -> void:
	
	if ids_exists.has(id):
		load_thumbnail(path, thumbnail_path, id)
	else:
		create_thumbnail_from_video(path, video_decoder, thumbnail_path, id)
	
	if DirAccess.dir_exists_absolute(waveform_path + "/" + id):
		load_waveform(path, waveform_path, id)
	else:
		if not audio_data_res:
			return
		var data_id: int = audio_data_res.get_instance_id()
		MediaHelper.PushAudioData(data_id, audio_data_res.get_data())
		create_timeline_waveform_textures_from_audio(path, audio_data_res, waveform_path, id)
		MediaHelper.FreeAudioData(data_id)

func server_register_audio(path: String, audio_data_res: MediaCache.AudioF32Data, ids_exists: PackedStringArray, id: String, thumbnail_path: String, waveform_path: String) -> void:
	var data_id: int = audio_data_res.get_instance_id()
	MediaHelper.PushAudioData(data_id, audio_data_res.get_data())
	
	if ids_exists.has(id):
		load_thumbnail(path, thumbnail_path, id)
	else:
		create_thumbnail_from_audio(path, audio_data_res, thumbnail_path, id)
	
	if DirAccess.dir_exists_absolute(waveform_path + "/" + id):
		load_waveform(path, waveform_path, id)
	else:
		create_timeline_waveform_textures_from_audio(path, audio_data_res, waveform_path, id)
	
	MediaHelper.FreeAudioData(data_id)

func server_replace_media_path(from: String, to: String) -> void:
	if thumbnails.has(from):
		thumbnails[to] = thumbnails[from]
		thumbnails.erase(from)
	
	if timeline_video_textures.has(from):
		timeline_video_textures[to] = timeline_video_textures[from]
		timeline_video_textures.erase(from)
	
	if timeline_waveform_textures.has(from):
		timeline_waveform_textures[to] = timeline_waveform_textures[from]
		timeline_waveform_textures.erase(from)
	
	if not_saved_yet.has(from):
		not_saved_yet[to] = not_saved_yet[from]
		not_saved_yet.erase(from)
	
	if not_deleted_yet.has(from):
		not_deleted_yet.append(to)
		not_deleted_yet.erase(from)


func server_deregister_image(path: String, id: String, thumbnail_path: String, delete_images_on_disk: bool) -> void:
	thumbnails.erase(path)
	if delete_images_on_disk:
		DirAccessHelper.remove_directory_recursive(thumbnail_path + id + ".png")
	else:
		store_not_deleted_thumbnail(thumbnail_path, id)

func server_deregister_video(path: String, id: String, thumbnail_path: String, waveform_path: String, delete_images_on_disk: bool) -> void:
	thumbnails.erase(path)
	timeline_waveform_textures.erase(path)
	if delete_images_on_disk:
		DirAccessHelper.remove_directory_recursive(thumbnail_path + id + ".png")
		DirAccessHelper.remove_directory_recursive(waveform_path + id)
	else:
		store_not_deleted_thumbnail(thumbnail_path, id)
		store_not_deleted_dir(str(waveform_path, id))

func server_deregister_audio(path: String, id: String, thumbnail_path: String, waveform_path: String, delete_images_on_disk: bool) -> void:
	thumbnails.erase(path)
	timeline_waveform_textures.erase(path)
	if delete_images_on_disk:
		DirAccessHelper.remove_directory_recursive(thumbnail_path + id + ".png")
		DirAccessHelper.remove_directory_recursive(waveform_path + id)
	else:
		store_not_deleted_thumbnail(thumbnail_path, id)
		store_not_deleted_dir(str(waveform_path, id))

#func server_register_preset_media_res(path: String, preset_media_res: MediaClipRes, ids_exists: PackedStringArray, id: String, thumbnail_path: String) -> void:
	#if ids_exists.has(id):
		#load_thumbnail(path, thumbnail_path, id)
	#else:
		#create_thumbnail_from_preset_media_res(path, preset_media_res, thumbnail_path, id)

func load_thumbnail(media_path: String, thumbnail_path: String, id: String) -> void:
	var thumb_image: Image = Image.load_from_file(str(thumbnail_path, id, ".png"))
	var thumb_texture: ImageTexture = ImageTexture.create_from_image(thumb_image)
	thumbnails[StringName(media_path)] = {&"image": thumb_image, &"texture": thumb_texture}

func load_waveform(media_path: String, thumbnail_path: String, id: String) -> void:
	var waveform_port_path: String = str(thumbnail_path, id, "/")
	
	var waveform_images: Array[Image]
	var waveform_textures: Array[ImageTexture]
	var total_width: int
	
	for file_name: String in DirAccess.get_files_at(waveform_port_path):
		var waveform_image: Image = Image.load_from_file(str(waveform_port_path, file_name))
		if waveform_image == null: continue
		waveform_image.generate_mipmaps()
		waveform_images.append(waveform_image)
		waveform_textures.append(ImageTexture.create_from_image(waveform_image))
		total_width += waveform_image.get_width()
	
	timeline_waveform_textures[StringName(media_path)] = {&"textures": waveform_textures, &"total_width": total_width}

func save_not_saved_yet() -> void:
	for path: String in not_saved_yet:
		var res: Resource = not_saved_yet[path]
		DirAccess.make_dir_absolute(path.get_base_dir())
		if res is Image:
			res.save_png(path)
		elif res is AudioStreamWAV:
			res.save_to_wav(path)
		else:
			ResourceSaver.save(res, path, ResourceSaver.FLAG_COMPRESS)
	not_saved_yet.clear()

func store_not_saved_resource(full_path: String, res: Resource) -> void:
	not_saved_yet[full_path] = res

func store_not_saved_thumbnail(thumbnail_path: String, id: String, image: Image) -> void:
	not_saved_yet[str(thumbnail_path, id, ".png")] = image

func get_not_saved_resource(full_path: String) -> Resource:
	return not_saved_yet.get(full_path)

func delete_not_deleted_yet() -> void:
	for path: String in not_deleted_yet:
		var result: Error = DirAccess.remove_absolute(path)
		if result != OK:
			DirAccessHelper.remove_directory_recursive(path)
	not_deleted_yet.clear()

func store_not_deleted_resource(path: String) -> void:
	if not_saved_yet.has(path): not_saved_yet.erase(path)
	else: not_deleted_yet.append(path)

func store_not_deleted_thumbnail(thumbnail_path: String, id: String) -> void:
	store_not_deleted_resource(str(thumbnail_path, id, ".png"))

func store_not_deleted_dir(dir_path: String) -> void:
	var deleteable: PackedStringArray
	
	for path: String in not_saved_yet:
		if path.begins_with(dir_path):
			deleteable.append(path)
	
	for path: String in deleteable:
		not_saved_yet.erase(path)
	
	not_deleted_yet.append(dir_path)

func get_thumbnail(key_as_path: StringName) -> Dictionary:
	return thumbnails[key_as_path] if thumbnails.has(key_as_path) else THUMBNAIL_DISCARD

func create_thumbnail_from_image(key_as_path: StringName, image: Image, thumbnail_path: String, id: String) -> Dictionary:
	var result_image: Image
	var result_texture: ImageTexture
	
	if image.get_width() > THUMBNAIL_TARGET_WIDTH:
		var scale: float = THUMBNAIL_TARGET_WIDTH / float(image.get_width())
		var target_height: int = image.get_height() * scale
		
		result_image = image.duplicate(true)
		result_image.resize(THUMBNAIL_TARGET_WIDTH, target_height, Image.INTERPOLATE_LANCZOS)
		result_texture = ImageTexture.create_from_image(result_image)
		
		store_not_saved_thumbnail(thumbnail_path, id, result_image)
	
	else:
		result_image = image
		result_texture = MediaCache.get_texture(key_as_path)
	
	thumbnails[key_as_path] = {&"image": result_image, &"texture": result_texture}
	return thumbnails[key_as_path]

func create_thumbnail_from_video(key_as_path: StringName, video_decoder: VideoDecoder, thumbnail_path: String, id: String) -> Dictionary:
	if not video_decoder.seek_frame(video_decoder.get_total_frames_by_dur() / 2):
		return {}
	video_decoder.update_video_data(1.)
	var image: Image = Image.create_from_data(video_decoder.get_width(), video_decoder.get_height(), false, Image.FORMAT_RGB8, video_decoder.get_video_data())
	return create_thumbnail_from_image(key_as_path, image, thumbnail_path, id)

func create_thumbnail_from_audio(key_as_path: StringName, audio_data_res: MediaCache.AudioF32Data, thumbnail_path: String, id: String) -> Dictionary:
	var thumbnail_image: Image = MediaHelper.GenerateWaveformImage(audio_data_res.get_instance_id(), .0, INF, Image.FORMAT_RGBA8, THUMBNAIL_TARGET_WIDTH, THUMBNAIL_TARGET_WIDTH, 2, 2, 0, Color.TRANSPARENT)
	thumbnails[key_as_path] = {&"image": thumbnail_image, &"texture": ImageTexture.create_from_image(thumbnail_image)}
	store_not_saved_thumbnail(thumbnail_path, id, thumbnail_image)
	return thumbnails[key_as_path]

func create_timeline_video_textures_from_video_path(video_path: StringName) -> Array[Image]:
	return []

func get_timeline_video_textures() -> Array[Image]:
	return []

func get_timeline_video_textures_range(frame_start: int, frame_end: int) -> Array[int]:
	return [] # image_from_index, pixel_from_index, image_to_index, pixel_to_index

func create_timeline_waveform_textures_from_audio(key_as_path: StringName, audio_data_res: MediaCache.AudioF32Data, waveform_path: String, id: String) -> Array[Image]:
	var waveform_images: Array[Image] = await generate_waveform_images(audio_data_res, 1, ProjectServer2.fps, TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH, 64, 0, 1, Color.TRANSPARENT)
	var waveform_textures: Array = waveform_images.map(func(image: Image) -> ImageTexture: return ImageTexture.create_from_image(image))
	var total_width: int
	var waveform_port_path: String = str(waveform_path, id, "/")
	
	for index: int in waveform_images.size():
		var image: Image = waveform_images[index]
		var image_path: String = str(waveform_port_path, index, ".png")
		not_saved_yet[image_path] = image
		total_width += image.get_width()
	timeline_waveform_textures[key_as_path] = {&"textures": waveform_textures, &"total_width": total_width}
	
	return waveform_images

func get_timeline_waveform_textures(key_as_path: StringName) -> Dictionary:
	return timeline_waveform_textures[key_as_path]

func get_timeline_waveform_texture_index(frame_in: int) -> Vector2i:
	return Vector2i(
		frame_in / TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH,
		frame_in % TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH
	)


# Written by Omar TOP and edited by Claude AI
func generate_waveform_images(audio_data_res: MediaCache.AudioF32Data, draw_method_idx: int, pixels_per_second: int = 30, width: int = 512, height: int = 64, space_width: int = 0, line_width: int = 1, bg_color: Color = Color.TRANSPARENT) -> Array[Image]:
	
	var audio_id: int = audio_data_res.get_instance_id()
	
	var length: float = audio_data_res.get_length()
	var pixels_per_length: int = length * pixels_per_second
	var images_count: int = pixels_per_length / float(width)
	var chunk_length: float = width / float(pixels_per_second)
	
	var images: Array[Image]
	images.resize(images_count)
	
	var pixels_remained: int = pixels_per_length % width
	
	const GROUP_SIZE: int = 4
	
	for start_idx: int in range(0, images_count, GROUP_SIZE):
		var curr_group_size: int = min(GROUP_SIZE, images_count - start_idx)
		var group_task_id: int = WorkerThreadPool.add_group_task(generate_waveform_image_at.bind(start_idx, images, audio_id, draw_method_idx, width, height, space_width, line_width, bg_color, chunk_length), curr_group_size, -1, true)
		WorkerThreadPool.wait_for_group_task_completion(group_task_id)
	
	if pixels_remained > 0:
		var length_remained: float = pixels_remained / float(pixels_per_second)
		images.append(MediaHelper.GenerateWaveformImage(audio_id, length - length_remained, INF, Image.FORMAT_L8, pixels_remained, height, space_width, line_width, draw_method_idx, bg_color))
	
	return images

func generate_waveform_image_at(idx: int, start_idx: int, images: Array[Image], audio_id: int, draw_method_idx: int, width: int, height: int, space_width: int, line_width: int, bg_color: Color, chunk_length: float) -> void:
	idx += start_idx
	var second_from: float = idx * chunk_length
	var second_to: float = second_from + chunk_length
	images[idx] = MediaHelper.GenerateWaveformImage(audio_id, second_from, second_to, Image.FORMAT_L8, width, height, space_width, line_width, draw_method_idx, bg_color)

#func generate_waveform_image(stream: AudioStreamWAV, second_from: float, second_to: float, draw_func: Callable, image_format: Image.Format, width: int, height: int, space_width: int, line_width: int, bg_color: Color = Color.BLACK) -> Image:
	#var image: Image = Image.create_empty(width, height, false, image_format)
	#image.fill(bg_color)
	#
	#if stream.format != AudioStreamWAV.FORMAT_16_BITS:
		#printerr("Only 16-bit format is supported")
		#return image
	#
	#var length: float = stream.get_length()
	#var data: PackedByteArray = stream.data
	#var data_size: int = data.size()
	#
	#var bytes_per_sample: int = 2
	#var channels: int = 2 if stream.stereo else 1
	#var sample_rate: int = stream.mix_rate
	#
	#var start_sample: int = int(second_from * sample_rate)
	#var start_byte: int = start_sample * bytes_per_sample * channels
	#
	#second_to = minf(length, second_to)
	#var duration: float = second_to - second_from
	#var total_samples: int = int(duration * sample_rate)
	#var samples_per_pixel: int = maxi(1, (total_samples / width))
	#
	#space_width += line_width
	#var lines_count: int = width / space_width
	#
	#var target_samples_count: int
	#if samples_per_pixel < 500: target_samples_count = 250
	#elif samples_per_pixel < 5_000: target_samples_count = 500
	#elif samples_per_pixel < 50_000: target_samples_count = 750
	#elif samples_per_pixel < 500_000: target_samples_count = 1_000
	#else: target_samples_count = 1_500
	#var samples_step: int = maxi(1, samples_per_pixel / target_samples_count)
	#
	#for x: int in lines_count:
		#var pixel_x: int = x * space_width
		#
		#var sample_start: int = start_byte + (pixel_x * samples_per_pixel * bytes_per_sample * channels)
		#
		#var max_amplitude: float = .0
		#
		#for s: int in samples_per_pixel / samples_step:
			#var index: int = sample_start + (s * samples_step * bytes_per_sample * channels)
			#if index + 1 >= data_size:
				#break
			#
			#var sample_value: float = absf(data.decode_s16(index) / 32768.)
			#
			#if channels == 2 and index + 3 < data_size:
				#var sample_value2: float = absf(data.decode_s16(index + 2) / 32768.)
				#sample_value = (sample_value + sample_value2) / 2.
			#
			#max_amplitude = maxf(max_amplitude, sample_value)
		#
		#draw_func.call(image, width, height, line_width, pixel_x, max_amplitude)
	#
	#image.generate_mipmaps()
	#
	#return image
#
#func draw_waveform_line_thumbnail(image: Image, width: int, height: int, line_width: int, x: int, sample: float) -> void:
	#var gradient: Gradient = editor_settings.media_explorer_waveform_gradient
	#var offset: float = x / float(width)
	#
	#var height_half: int = height / 2
	#var sample_height: int = int(sample * height)
	#
	#image.fill_rect(
		#Rect2i(
			#Vector2i(x, height_half - sample_height / 2.0),
			#Vector2i(line_width, sample_height)
		#),
		#gradient.sample(offset)
	#)
#
#func draw_waveform_line_timeline(image: Image, width: int, height: int, line_width: int, x: int, sample: float) -> void:
	#var offset: float = x / float(width)
	#
	#var height_half: int = height / 2
	#var sample_height: int = int(sample * height)
	#
	#image.fill_rect(
		#Rect2i(
			#Vector2i(x, height_half - sample_height / 2.0),
			#Vector2i(line_width, sample_height)
		#),
		#Color(Color.BLACK, .6)
	#)


class ClipPanel extends Panel:
	
	@onready var box_container: BoxContainer = IS.create_box_container(0, true, {})
	@onready var info_container: BoxContainer = IS.create_box_container(8, false, {})
	@onready var thumbnail_rect: TextureRect
	@onready var select_panel: SelectPanel = SelectPanel.new(self)
	
	static var timeline: TimeLine2
	
	var is_graph_editor_opened: bool = false
	var graph_editors: Dictionary[UsableRes, Dictionary]
	var graph_editors_expanded: Array[bool]
	
	var layer_idx: int
	var frame: int
	var clip_res: MediaClipRes
	
	var has_clips: bool
	
	var button_event: InputEventMouseButton
	
	
	func _init(_clip_res: MediaClipRes) -> void:
		clip_res = _clip_res
	
	func _ready() -> void:
		
		clip_res.comp_keyframe_added.connect(_on_comp_keyframe_added)
		clip_res.comp_keyframe_removed.connect(_on_comp_keyframe_removed)
		
		update_has_clips()
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_ready_ui()
		_update_ui()
	
	func _gui_input(event: InputEvent) -> void:
		
		if EditorServer.picking_clip:
			return
		
		match timeline.edit_mode_btn.selected_id:
			0: _gui_input_select_mode(event)
			1: _gui_input_split_mode(event)
			2: _gui_input_slip_mode(event)
	
	func _draw() -> void:
		
		if has_clips:
			draw_polygon(PackedVector2Array([
				size, size - Vector2(30.0, .0), size - Vector2(.0, 30.0),
			]), PackedColorArray([Color(.0,.0,.0,.6)]))
		
		if get_global_rect().has_point(get_global_mouse_position()):
			
			var target_frame: int = timeline.get_snapped_frame_from_mouse_pos()
			var xpos: float = timeline.get_display_pos_from_frame(target_frame) + (timeline.global_position.x - global_position.x)
			var size_h: Vector2 = size / 2.
			
			match timeline.edit_mode_btn.selected_id:
				1:
					draw_line(Vector2(xpos, .0), Vector2(xpos, size.y), Color.RED, 2., true)
				2:
					draw_polygon(PackedVector2Array([
						Vector2(xpos - 20., size_h.y),
						Vector2(xpos, size_h.y - 10.),
						Vector2(xpos + 20., size_h.y),
						Vector2(xpos, size_h.y + 10.)
					]), [Color.DODGER_BLUE])
	
	func _gui_input_select_mode(event: InputEvent) -> void:
		
		if select_panel.mouse_default_cursor_shape == CursorShape.CURSOR_HSIZE:
			return
		
		if event is InputEventMouseButton:
			
			var pressed: bool = event.is_pressed()
			button_event = event
			
			if pressed:
				pass
			
			else:
				match event.button_index:
					
					MOUSE_BUTTON_LEFT:
						
						_select(event.alt_pressed, not event.ctrl_pressed and not timeline.layers_body.is_moving_clips())
						_try_release()
					
					MOUSE_BUTTON_RIGHT:
						
						var layers_body: TimeLine2.LayersSelectContainer = timeline.layers_body
						if layers_body.clips_moving:
							layers_body.end_clips_moving(true)
						else:
							_select(false, not event.ctrl_pressed and not layers_body.is_val_selected(layer_idx, frame))
							layers_body.popup_options_menu(layers_body._get_menu_options() + layers_body.clips_menu)
		
		elif event is InputEventMouseMotion:
			
			if _is_left_press_event(button_event):
				_try_drag(event)
	
	func _gui_input_split_mode(event: InputEvent) -> void:
		
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				timeline.opened_clip_res.split_clips([Vector2i(layer_idx, frame)], timeline.get_snapped_frame_from_mouse_pos(), true, true)
		
		elif event is InputEventMouseMotion:
			queue_redraw()
	
	func _gui_input_slip_mode(event: InputEvent) -> void:
		
		if event is InputEventMouseButton:
			button_event = event
			if button_event.is_pressed():
				set_meta(&"start_from", clip_res.from)
			else:
				remove_meta(&"start_from")
		
		elif event is InputEventMouseMotion:
			
			if _is_left_press_event(button_event):
				clip_res.from = get_meta(&"start_from", 0) - (event.position.x - button_event.position.x) / timeline.displ_frame_size
				select_panel.update_spacial_frames()
				_update_ui()
			
			queue_redraw()
	
	func _select(delete: bool, preclear: bool) -> void:
		timeline.layers_body.manage_val(layer_idx, frame, delete, preclear)
		timeline.layers_body.emit_selected_changed()
	
	func _try_drag(event: InputEventMouseMotion) -> void:
		
		var layers_body: TimeLine2.LayersSelectContainer = timeline.layers_body
		
		if timeline.edit_mode_btn.get_selected_id() != TimeLine2.EditMode.MODE_SELECT:
			return
		
		var delta: float = (event.position - button_event.position).length()
		
		var frame: int = timeline.get_frame_from_mouse_pos()
		
		if layers_body.clips_moving:
			
			var event_glob_pos: Vector2 = event.global_position
			var target_layer_idx: int = -1
			var insert_dir: int = 0
			var max_layer_idx: int = timeline.layers.size() - 1
			
			if event_glob_pos.y > timeline.get_layer_from_idx(0).global_position.y:
				target_layer_idx = 0
			elif event_glob_pos.y < timeline.get_layer_from_idx(max_layer_idx).global_position.y:
				target_layer_idx = max_layer_idx
			else:
				for layer_res: LayerRes in timeline.layers:
					var _layer: Layer2 = timeline.layers[layer_res]
					var _layer_rect: Rect2 = _layer.get_global_rect()
					if _layer_rect.has_point(event_glob_pos):
						target_layer_idx = _layer.layer_idx
						if event_glob_pos.y < _layer_rect.position.y + 15.:
							insert_dir = 1
						elif event_glob_pos.y > _layer_rect.position.y + _layer_rect.size.y - 15.:
							insert_dir = -1
						break
			
			layers_body.move_clips(target_layer_idx, insert_dir, frame)
		
		else:
			if delta > timeline.layers_body.control_drag_dist:
				_select(false, false)
				layers_body.start_clips_moving(layer_idx, frame)
	
	func _try_release() -> void:
		if timeline.layers_body.is_moving_clips(): timeline.layers_body.end_clips_moving(false)
	
	func update_has_clips() -> void:
		has_clips = clip_res.has_clips()
	
	func _ready_ui() -> void:
		
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		
		clip_contents = true
		info_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var thumbnail: Texture2D = _get_ui_thumbnail()
		if thumbnail:
			thumbnail_rect = IS.create_texture_rect(thumbnail, {})
			thumbnail_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			thumbnail_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			thumbnail_rect.custom_minimum_size.x = 64.
			info_container.add_child(thumbnail_rect)
		
		var name: String = _get_ui_name()
		if name:
			var name_label:= IS.create_name_label(name)
			name_label.label_settings = null
			name_label.add_theme_font_size_override("font_size", 14)
			name_label.add_theme_color_override("font_color", Color(1.,1.,1.,.8))
			name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			IS.expand(name_label, true, true)
			info_container.add_child(name_label)
		
		box_container.add_child(info_container)
		add_child(box_container)
		
		select_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(select_panel)
	
	func _update_ui() -> void:
		pass
	
	func _update_ui_transform() -> void:
		pass
	
	func _update_selection(selection: bool) -> void:
		select_panel.visible = selection
	
	func _get_ui_name() -> String:
		return clip_res.get_display_name()
	
	func _get_ui_thumbnail() -> Texture2D:
		return clip_res.get_thumbnail()
	
	func update_spacial_frames() -> void:
		select_panel.update_spacial_frames()
	
	func update_spacial_frames_and_update_timeline() -> void:
		update_spacial_frames()
		timeline.update_clips_spacial_frames()
		timeline.update_spacial_frames()
	
	func open_graph_editor() -> void:
		close_graph_editor()
		
		var comps: Dictionary[String, Array] = clip_res.components
		
		var index: int
		
		for section_key: String in comps.keys():
			var section_comps: Array = comps[section_key]
			
			for comp_res: ComponentRes in section_comps:
				var anims: Dictionary[UsableRes, Dictionary] = comp_res.animations
				
				for usable_res: UsableRes in anims:
					var animated_props: Dictionary = anims[usable_res]
					var usable_res_port: Dictionary[StringName, Category] = graph_editors.get_or_add(usable_res, {} as Dictionary[StringName, Category])
					
					for prop_key: StringName in animated_props:
						
						var anim_res: AnimationRes = animated_props[prop_key]
						
						if not AnimationRes.funcs_indexer.has(anim_res.value_type):
							continue
						
						var graph_category:= IS.create_category(true, str(comp_res.get_classname(), ":", prop_key), Color.TRANSPARENT, Vector2(.0, 250.), false)
						var graph_editor:= CurveController.new()
						
						var minmax_vals: Vector2 = anim_res.find_minmax_vals()
						var length: float = minmax_vals.y - minmax_vals.x
						
						if length in [.0, -INF, INF]:
							minmax_vals.x = -10.
							minmax_vals.y = 10.
							length = minmax_vals.y - minmax_vals.x
						
						var length_square: float = length * 2.
						
						graph_editor.custom_minimum_size.y = 200.
						graph_editor.curves_profiles = anim_res.profiles
						graph_editor.min_domain = clip_res.from
						graph_editor.max_domain = clip_res.from + clip_res.length
						graph_editor.min_val = minmax_vals.x
						graph_editor.max_val = minmax_vals.y
						graph_editor.zoom_max = length_square
						graph_editor.draw_val_step = maxi(1, snappedi(length_square / 10, 1))
						graph_editor.draw_y_small_step = graph_editor.draw_val_step
						graph_editor.draw_y_big_step = graph_editor.draw_y_small_step * 2
						
						graph_editor.mouse_entered.connect(_on_graph_editor_mouse_entered.bind(graph_editor))
						graph_editor.mouse_exited.connect(_on_graph_editor_mouse_exited.bind(graph_editor))
						graph_editor.keys_editing.connect(_on_graph_editor_keys_editing)
						
						graph_category.add_content(graph_editor)
						box_container.add_child(graph_category)
						
						IS.set_margin_settings(graph_category.content_margin_container, 2, 2, 0, 2)
						graph_category.content_color = Color.BLACK
						
						IS.expand(graph_editor, true, true)
						graph_category.mouse_filter = Control.MOUSE_FILTER_STOP
						graph_category.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
						graph_category.is_expanded = graph_editors_expanded.size() - 1 >= index and graph_editors_expanded[index]
						graph_category.expand_changed.connect(_on_graph_category_expand_changed)
						
						usable_res_port[prop_key] = graph_category
						
						index += 1
		
		select_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		is_graph_editor_opened = true
		
		_on_playback_server_position_changed(PlaybackServer.position)
		PlaybackServer.position_changed.connect(_on_playback_server_position_changed)
	
	func close_graph_editor() -> void:
		
		for usable_res: UsableRes in graph_editors:
			var usable_res_port: Dictionary[StringName, Category] = graph_editors[usable_res]
			for prop_key: StringName in usable_res_port:
				usable_res_port[prop_key].queue_free()
		
		graph_editors.clear()
		is_graph_editor_opened = false
		
		select_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		
		PlaybackServer.position_changed.disconnect(_on_playback_server_position_changed)
	
	func _on_comp_keyframe_added(comp: ComponentRes, usable_res: UsableRes, prop_key: StringName, prop_val: Variant, frame: int) -> void: update_spacial_frames_and_update_timeline()
	func _on_comp_keyframe_removed(comp: ComponentRes, usable_res: UsableRes, prop_key: StringName, frame: int) -> void: update_spacial_frames_and_update_timeline()
	
	func _on_mouse_entered() -> void:
		EditorServer.media_clips_focused.append(self)
	
	func _on_mouse_exited() -> void:
		EditorServer.media_clips_focused.erase(self)
		queue_redraw()
	
	func _on_graph_editor_mouse_entered(graph_editor: CurveController) -> void:
		EditorServer.graph_editors_focused.append(graph_editor)
	
	func _on_graph_editor_mouse_exited(graph_editor: CurveController) -> void:
		EditorServer.graph_editors_focused.erase(graph_editor)
	
	func _on_graph_category_expand_changed() -> void:
		var layer_res: LayerRes = timeline.opened_clip_res.get_layer(layer_idx)
		var layer: Layer2 = timeline.get_layer(layer_res)
		
		for frame: int in layer.clips:
			layer.get_clip(frame).size.y = layer_res.custom_size
		
		await get_tree().process_frame
		layer.update_size()
		layer.update_clips_transform()
	
	func _on_graph_editor_keys_editing() -> void: update_spacial_frames_and_update_timeline()
	
	func _on_playback_server_position_changed(new_frame: int) -> void:
		var new_local_frame: int = new_frame - clip_res.clip_pos + clip_res.from
		for usable_res: UsableRes in graph_editors:
			var usable_res_port: Dictionary[StringName, Category] = graph_editors[usable_res]
			for prop_key: StringName in usable_res_port:
				usable_res_port[prop_key].content_container.get_child(0).set_cursor_pos(new_local_frame)
	
	static func _is_left_press_event(event: InputEventMouseButton) -> bool:
		return event != null and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
	
	class SelectPanel extends Panel:
		
		const STYLE_SELECTED: StyleBoxFlat = preload("uid://kkroptu2c0c1")
		const KEYFRAME_SIZE: Vector2 = Vector2(24., 24.)
		const _DRAG_IDX_KEY: StringName = &"drag_idx"
		
		var owner_as_clip: ClipPanel
		
		var spacial_frames: PackedInt32Array
		
		var button_event: InputEventMouseButton
		
		var drag_start_poss: Vector3i
		var drag_limits: Vector2
		var drag_target_poss: Vector3i
		
		func get_spacial_frames() -> PackedInt32Array:
			return spacial_frames
		
		func set_spacial_frames(new_val: PackedInt32Array) -> void:
			spacial_frames = new_val
		
		func clear_spacial_frames() -> void:
			spacial_frames.clear()
		
		func update_spacial_frames() -> void:
			clear_spacial_frames()
			var clip_res: MediaClipRes = owner_as_clip.clip_res
			clip_res.loop_components_animations_keys({},
				func(pos: int, curve_key: CurveKey, info: Dictionary[StringName, Variant]) -> void:
					if pos >= clip_res.from and pos <= clip_res.from + clip_res.length:
						pos -= clip_res.from
						if not spacial_frames.has(pos):
							spacial_frames.append(pos)
			)
			queue_redraw()
		
		func _init(_owner_as_clip: ClipPanel) -> void:
			owner_as_clip = _owner_as_clip
			
			IS.set_base_panel_settings(self, STYLE_SELECTED)
			modulate.a = .7
		
		func _ready() -> void:
			visibility_changed.connect(_on_visiblity_changed)
		
		func _gui_input(event: InputEvent) -> void:
			
			var drag_idx: int = get_meta(_DRAG_IDX_KEY, 0)
			
			if event is InputEventMouseButton:
				
				button_event = event
				
				match event.button_index:
					MOUSE_BUTTON_LEFT:
						
						if event.is_pressed():
							match drag_idx:
								1: _init_drag_left()
								2: _init_drag_right()
						
						else:
							match drag_idx:
								1: _end_drag_left()
								2: _end_drag_right()
			
			elif event is InputEventMouseMotion:
				
				if ClipPanel._is_left_press_event(button_event):
					if drag_idx == 1:
						_drag_left(event)
					elif drag_idx == 2:
						_drag_right(event)
				
				else:
					if event.position.x < 10.:
						set_meta(_DRAG_IDX_KEY, 1)
					elif event.position.x > size.x - 10.:
						set_meta(_DRAG_IDX_KEY, 2)
					else:
						remove_meta(_DRAG_IDX_KEY)
						mouse_default_cursor_shape = Control.CURSOR_ARROW
						return
					mouse_default_cursor_shape = Control.CURSOR_HSIZE
		
		func _draw() -> void:
			
			var displ_frame_size: float = EditorServer.time_line2.displ_frame_size
			var keyframe_tex: CompressedTexture2D = IS.TEXTURE_KEYFRAME
			var keyframe_h: float = keyframe_tex.get_height()
			
			var ypos: float = owner_as_clip.info_container.size.y / 2. - 10.
			
			for frame: int in spacial_frames:
				var xpos: float = frame * displ_frame_size - 14.
				var pos: Vector2 = Vector2(xpos, ypos)
				draw_texture_rect(keyframe_tex, Rect2(pos, KEYFRAME_SIZE), false)
		
		
		static func is_edit_multiple() -> bool:
			return ClipPanel.timeline.edit_multiple_btn.get_selected_id() == 1
		
		func format_frame_when_drag(frame: int) -> int:
			var clip_res: MediaClipRes = owner_as_clip.clip_res
			var min_frame: float = drag_start_poss.x - (drag_start_poss.y - clip_res.get_min_from())
			var max_frame: float = drag_start_poss.x + drag_start_poss.z - 1
			return floori(clampf(frame, maxf(min_frame, drag_limits.x), max_frame))
		
		
		func _init_drag_left() -> void:
			
			ClipPanel.timeline.edges_nav_horizontal = true
			
			if is_edit_multiple():
				
				var selected: Dictionary[int, Dictionary] = ClipPanel.timeline.layers_body.selected
				
				for layer_idx: int in selected:
					var port: Dictionary = selected[layer_idx]
					var layer: Layer2 = ClipPanel.timeline.get_layer_from_idx(layer_idx)
					for frame: int in port:
						layer.get_clip(frame).select_panel._init_drag()
						layer.lock_clip(frame)
			
			else:
				_init_drag()
				ClipPanel.timeline.get_layer_from_idx(owner_as_clip.layer_idx).lock_clip(owner_as_clip.frame)
			
			_drag_left(button_event)
		
		func _init_drag_right() -> void:
			
			ClipPanel.timeline.edges_nav_horizontal = true
			
			if is_edit_multiple():
				
				var selected: Dictionary[int, Dictionary] = ClipPanel.timeline.layers_body.selected
				
				for layer_idx: int in selected:
					var port: Dictionary = selected[layer_idx]
					var layer: Layer2 = ClipPanel.timeline.get_layer_from_idx(layer_idx)
					for frame: int in port:
						layer.get_clip(frame).select_panel._init_drag()
			
			else:
				_init_drag()
			
			_drag_right(button_event)
		
		func _init_drag() -> void:
			var clip_res: MediaClipRes = owner_as_clip.clip_res
			var layer_res: LayerRes = ClipPanel.timeline.opened_clip_res.get_layer(owner_as_clip.layer_idx)
			
			drag_start_poss = Vector3i(
				owner_as_clip.frame,
				clip_res.from,
				clip_res.length
			)
			drag_limits = Vector2(
				layer_res.get_left_limit_at(owner_as_clip.frame),
				layer_res.get_right_limit_at(owner_as_clip.frame + clip_res.length)
			)
		
		func _drag_left(event: InputEventMouse) -> void:
			
			__drag_left(button_event, event)
			var frame_delta: int = drag_target_poss.x - drag_start_poss.x
			
			if is_edit_multiple():
				
				var selected: Dictionary[int, Dictionary] = ClipPanel.timeline.layers_body.selected
				
				for layer_idx: int in selected:
					var port: Dictionary = selected[layer_idx]
					var layer: Layer2 = ClipPanel.timeline.get_layer_from_idx(layer_idx)
					for frame: int in port:
						var select_panel: SelectPanel = layer.get_locked_clip(frame).select_panel
						select_panel._update_target_poss_by_delta(frame_delta)
						select_panel._owner_as_clip_update_ui()
						select_panel.update_spacial_frames()
			else:
				_update_target_poss_by_delta(frame_delta)
				_owner_as_clip_update_ui()
				update_spacial_frames()
		
		func _drag_right(event: InputEventMouse) -> void:
			
			var clips_forupdate: Array[Vector2i]
			
			__drag_right(button_event, event)
			var length_delta: int = owner_as_clip.clip_res.length - drag_start_poss.z
			
			if is_edit_multiple():
				
				var selected: Dictionary[int, Dictionary] = ClipPanel.timeline.layers_body.selected
				
				for layer_idx: int in selected:
					var port: Dictionary = selected[layer_idx]
					var layer: Layer2 = ClipPanel.timeline.get_layer_from_idx(layer_idx)
					for frame: int in port:
						var clip: ClipPanel = layer.get_clip(frame)
						var select_panel: SelectPanel = clip.select_panel
						clip.clip_res.length = minf(select_panel.drag_start_poss.z + length_delta, select_panel.drag_limits.y - select_panel.drag_start_poss.x)
						clips_forupdate.append(Vector2i(layer_idx, frame))
			else:
				owner_as_clip.clip_res.length = minf(drag_start_poss.z + length_delta, drag_limits.y - drag_start_poss.x)
				clips_forupdate.append(Vector2i(owner_as_clip.layer_idx, owner_as_clip.frame))
			
			ClipPanel.timeline.update_clips(clips_forupdate)
		
		func __drag_left(button_event: InputEventMouseButton, event: InputEventMouse) -> void:
			
			var frame: int = owner_as_clip.frame
			var frame_delta: int = (event.global_position.x - button_event.global_position.x) / ClipPanel.timeline.displ_frame_size
			
			var target_frame: int = drag_start_poss.x + frame_delta
			var snapped_frame: int = ClipPanel.timeline.snap_frame(target_frame, false, false)
			var snap_by_start_delta: int = snapped_frame - drag_start_poss.x
			
			_update_target_poss(snapped_frame, drag_start_poss.y + snap_by_start_delta, drag_start_poss.z - snap_by_start_delta)
			_owner_as_clip_update_ui()
		
		func __drag_right(button_event: InputEventMouseButton, event: InputEventMouse) -> void:
			
			var frame: int = owner_as_clip.frame
			var frame_delta: int = (event.position.x - button_event.position.x) / ClipPanel.timeline.displ_frame_size
			
			var target_length: int = drag_start_poss.z + frame_delta
			var snapped_frame: int = ClipPanel.timeline.snap_frame(target_length + frame, false, false)
			var snap_delta: int = snapped_frame - target_length
			
			owner_as_clip.clip_res.length = minf(target_length - frame + snap_delta, drag_limits.y - drag_start_poss.x)
		
		func _end_drag_left() -> void:
			
			ClipPanel.timeline.edges_nav_horizontal = false
			
			var coords_fordelete: Array[Vector2i]
			var clips_foradd: Dictionary[Vector2i, MediaClipRes]
			
			if is_edit_multiple():
				
				var selected: Dictionary[int, Dictionary] = ClipPanel.timeline.layers_body.selected
				
				for layer_idx: int in selected:
					var port: Dictionary = selected[layer_idx]
					var layer: Layer2 = ClipPanel.timeline.get_layer_from_idx(layer_idx)
					for frame: int in port:
						
						var clip: ClipPanel = layer.get_locked_clip(frame)
						layer.unlock_clip(frame)
						
						var target_coord: Vector2i = Vector2i(layer_idx, clip.select_panel.drag_target_poss.x)
						coords_fordelete.append(Vector2i(layer_idx, frame))
						clips_foradd[target_coord] = clip.clip_res
			
			else:
				var layer_idx: int = owner_as_clip.layer_idx
				
				var layer: Layer2 = ClipPanel.timeline.get_layer_from_idx(layer_idx)
				layer.unlock_clip(drag_start_poss.x)
				
				coords_fordelete.append(Vector2i(layer_idx, drag_start_poss.x))
				clips_foradd[Vector2i(layer_idx, drag_target_poss.x)] = owner_as_clip.clip_res
			
			var opened_clip_res: MediaClipRes = ProjectServer2.opened_clip_res_path.back()
			opened_clip_res.remove_clips(coords_fordelete)
			opened_clip_res.add_clips_by_coords(clips_foradd)
			
			ClipPanel.timeline.layers_body.select_vals_by_method(
				func(port_idx: int, port_obj: Object, idx: int, metadata: Dictionary) -> bool:
					return clips_foradd.has(Vector2i(port_idx, idx)), false
			)
		
		func _end_drag_right() -> void:
			ClipPanel.timeline.edges_nav_horizontal = false
			ProjectServer2.project_res.root_clip_res.update_root_length()
			ClipPanel.timeline.update_when_clips_changed()
		
		func _update_target_poss_by_delta(delta: int) -> void:
			var clip_res: MediaClipRes = owner_as_clip.clip_res
			
			var frame: int = drag_start_poss.x + delta
			var formated_frame: int = format_frame_when_drag(frame)
			var format_delta: int = formated_frame - frame
			
			owner_as_clip.frame = formated_frame
			clip_res.from = drag_start_poss.y + delta + format_delta
			clip_res.length = drag_start_poss.z - delta - format_delta
			
			drag_target_poss = Vector3i(owner_as_clip.frame, clip_res.from, clip_res.length)
		
		func _update_target_poss(frame: int, from: int, length: int) -> void:
			
			var clip_res: MediaClipRes = owner_as_clip.clip_res
			
			owner_as_clip.frame = format_frame_when_drag(frame)
			clip_res.from = from
			clip_res.length = length
			
			drag_target_poss = Vector3i(owner_as_clip.frame, clip_res.from, clip_res.length)
		
		func _owner_as_clip_update_ui() -> void:
			
			var clips_body: Control = ClipPanel.timeline.get_layer_from_idx(owner_as_clip.layer_idx).clips_body
			var displ_start_pos: float = ClipPanel.timeline.get_display_pos_from_frame(owner_as_clip.frame, clips_body)
			var displ_end_pos: float = ClipPanel.timeline.get_display_pos_from_frame(owner_as_clip.frame + owner_as_clip.clip_res.length, clips_body)
			
			owner_as_clip.position.x = displ_start_pos
			owner_as_clip.size.x = displ_end_pos - displ_start_pos
			owner_as_clip._update_ui()
		
		func _on_visiblity_changed() -> void:
			mouse_default_cursor_shape = Control.CURSOR_ARROW

class ImageClipPanel extends ClipPanel:
	
	func _ready() -> void:
		super()
		add_theme_stylebox_override(&"panel", preload("uid://d0sgurvxit0n2"))

class VideoClipPanel extends ClipPanel:
	
	@onready var waveform_box_container: WaveformBoxContainer
	
	var texture_rects: Dictionary[int, TextureRect]
	
	var update_method: Callable = _update_none
	var update_transform_method: Callable = _update_none
	
	func _ready() -> void:
		super()
		add_theme_stylebox_override(&"panel", preload("uid://bnc4n8cvuae5s"))
	
	func _ready_ui() -> void:
		if (clip_res as VideoClipRes).audio_data_res:
			waveform_box_container = WaveformBoxContainer.new()
			add_child(waveform_box_container)
			update_method = __update_ui
			update_transform_method = __update_ui_transform
		super()
		thumbnail_rect.modulate.a = .8
	
	func _update_ui() -> void:
		update_method.call()
		update_transform_method.call()
	
	func _update_ui_transform() -> void:
		update_transform_method.call()
		super()
	
	func __update_ui() -> void:
		waveform_box_container.update_ui(clip_res.video, clip_res.from, clip_res.length)
	
	func __update_ui_transform() -> void:
		var waveform_transform: Vector2 = waveform_box_container.calculate_transform(size, clip_res.length)
		waveform_box_container.position.x = waveform_transform.x
		waveform_box_container.size.x = waveform_transform.y
	
	static func _update_none() -> void:
		pass
	
	func _on_mouse_entered() -> void:
		super()
		thumbnail_rect.modulate.a = .4
	
	func _on_mouse_exited() -> void:
		super()
		thumbnail_rect.modulate.a = .8

class AudioClipPanel extends ClipPanel:
	
	@onready var waveform_box_container:= WaveformBoxContainer.new()
	
	func _ready() -> void:
		super()
		add_theme_stylebox_override(&"panel", preload("uid://djbj0r563olrv"))
	
	func _ready_ui() -> void:
		add_child(waveform_box_container)
		super()
	
	func _get_ui_thumbnail() -> Texture2D:
		var thumb: Texture2D = clip_res.get_thumbnail()
		return thumb if thumb == IS.TEXTURE_X_MARK else null
	
	func _update_ui() -> void:
		waveform_box_container.update_ui(clip_res.stream, clip_res.from, clip_res.length)
		_update_ui_transform()
	
	func _update_ui_transform() -> void:
		var waveform_transform: Vector2 = waveform_box_container.calculate_transform(size, clip_res.length)
		waveform_box_container.position.x = waveform_transform.x
		waveform_box_container.size.x = waveform_transform.y
		super()

class ObjectClipPanel extends ClipPanel:
	
	func _ready() -> void:
		super()
		thumbnail_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumbnail_rect.custom_minimum_size.x = 50.
		add_theme_stylebox_override(&"panel", preload("uid://dxxh6guqix0k"))

class Audio2DClipPanel extends ObjectClipPanel:
	
	@onready var waveform_box_container:= WaveformBoxContainer.new()
	
	func _ready_ui() -> void:
		add_child(waveform_box_container)
		super()
	
	func _update_ui() -> void:
		waveform_box_container.update_ui(clip_res.stream, clip_res.from, clip_res.length)
		_update_ui_transform()
	
	func _update_ui_transform() -> void:
		var waveform_transform: Vector2 = waveform_box_container.calculate_transform(size, clip_res.length)
		waveform_box_container.position.x = waveform_transform.x
		waveform_box_container.size.x = waveform_transform.y
		super()

class WaveformBoxContainer extends BoxContainer:
	
	static var shader_material: ShaderMaterial = _init_shader_material()
	
	static func _init_shader_material() -> ShaderMaterial:
		var sm:= ShaderMaterial.new()
		sm.shader = preload("res://UI&UX/Shader/ShaderWaveforms.gdshader")
		return sm
	
	static func set_pixelate_scale(scale: float = .0) -> void:
		shader_material.set_shader_parameter(&"pixelate_scale", scale)
	
	var texture_rects: Dictionary[int, TextureRect]
	
	var curr_waveform_textures_total_width: float
	var curr_waveform_start_index: Vector2i
	var curr_waveform_end_index: Vector2i
	
	func _init() -> void:
		material = shader_material
		IS.describe_box_container(self, 0, false)
	
	func update_ui(audio_key_as_path: String, frame_in: int, length: int) -> void:
		
		if not MediaServer.timeline_waveform_textures.has(audio_key_as_path):
			return
		
		var waveform_start_index: Vector2i = MediaServer.get_timeline_waveform_texture_index(frame_in)
		var waveform_end_index: Vector2i = MediaServer.get_timeline_waveform_texture_index(frame_in + length)
		
		var waveform_textures_info: Dictionary = MediaServer.get_timeline_waveform_textures(audio_key_as_path)
		var waveform_textures: Array = waveform_textures_info.textures
		
		if waveform_textures.is_empty():
			return
		
		var ranged_waveform_textures: Array = waveform_textures.slice(waveform_start_index.x, waveform_end_index.x)
		
		for index: int in texture_rects.keys():
			if index < waveform_start_index.x or index > waveform_end_index.x:
				texture_rects[index].queue_free()
				texture_rects.erase(index)
		
		var curr_total_width: float
		
		for texture: ImageTexture in ranged_waveform_textures:
			curr_total_width += texture.get_width()
		
		if waveform_end_index.y:
			var last_texture_index: int = waveform_start_index.x + ranged_waveform_textures.size()
			var last_waveform_texture: ImageTexture = waveform_textures.get(last_texture_index)
			curr_total_width += last_waveform_texture.get_width()
		
		var texture_ratio: float = TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH / curr_total_width
		for index: int in range(waveform_start_index.x, waveform_end_index.x):
			var texture: ImageTexture = waveform_textures[index]
			if not texture_rects.has(index):
				texture_rects[index] = _push_waveform_texture_rect(texture)
			texture_rects[index].size_flags_stretch_ratio = texture_ratio
		
		if waveform_end_index.y:
			var last_texture_index: int = waveform_start_index.x + ranged_waveform_textures.size()
			var last_waveform_texture: ImageTexture = waveform_textures.get(last_texture_index)
			var last_texture_ratio: float = last_waveform_texture.get_width() / curr_total_width
			if not texture_rects.has(last_texture_index):
				texture_rects[last_texture_index] = _push_waveform_texture_rect(last_waveform_texture)
			texture_rects[last_texture_index].size_flags_stretch_ratio = last_texture_ratio
		
		texture_rects.sort()
		
		for time: int in texture_rects.size():
			var index: int = texture_rects.keys()[time]
			var texture_rect: TextureRect = texture_rects[index]
			texture_rect.use_parent_material = true
			move_child(texture_rect, time)
		
		curr_waveform_textures_total_width = curr_total_width
		curr_waveform_start_index = waveform_start_index
		curr_waveform_end_index = waveform_end_index
	
	func calculate_transform(size: Vector2, curr_length: int) -> Vector2:
		var length_ratio: float = size.x / curr_length
		var textures_total_size: float = curr_waveform_textures_total_width * length_ratio
		var waveform_start_offset: float = curr_waveform_start_index.y * length_ratio
		
		return Vector2(
			-waveform_start_offset,
			textures_total_size
		)
	
	func _push_waveform_texture_rect(texture: ImageTexture) -> Control:
		var texture_rect: TextureRect = IS.create_texture_rect(texture, {})
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(texture_rect)
		return texture_rect




func get_file_main_info(path: StringName, get_more_meta_func: Callable = Callable()) -> Dictionary[StringName, String]:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	
	var file_size_as_kb: float = snappedf(file.get_length() / 1024.0, .001)
	
	var meta: Dictionary[StringName, String] = {
		&"file_name": path.get_file(),
		&"file_path": path,
		&"file_size": str(file_size_as_kb, " KB"),
	}
	if get_more_meta_func.is_valid():
		meta.merge(get_more_meta_func.call(file))
	
	file.close()
	return meta

func get_imported_file_info(key_as_path: StringName, type: int) -> Dictionary[StringName, String]:
	var result: Dictionary[StringName, String]
	match type:
		0: result = get_image_file_info(key_as_path)
		1: result = get_video_file_info(key_as_path)
		2: result = get_audio_file_info(key_as_path)
	return result

func get_image_file_info(key_as_path: StringName) -> Dictionary[StringName, String]:
	var image: Image = MediaCache.get_image(key_as_path)
	if not image:
		return {&"title": "Image"}
	
	var width: int = image.get_width()
	var height: int = image.get_height()
	var format_int: Image.Format = image.get_format()
	
	return get_file_main_info(key_as_path).merged({
		&"title": "Image",
		&"extension": key_as_path.get_extension(),
		&"resolution": "(%s x %s)" % [width, height],
		&"total_pixels": str(width * height),
		&"image_format": IMAGE_FORMAT_INDEXER.get(format_int),
		&"memory_size": str(image.get_data().size() / 1024.0, " KB"),
		&"has_mipmaps": str(image.has_mipmaps()),
		&"is_empty": str(image.is_empty())
	})

func get_audio_file_info(key_as_path: StringName) -> Dictionary[StringName, String]:
	var audio_data_res: MediaCache.AudioF32Data = MediaCache.get_audio_data(key_as_path)
	
	const SAMPLE_RATE: int = MediaCache.AudioF32Data.SAMPLE_RATE
	var duration: float = snapped(audio_data_res.get_length(), .001)
	var bitrate: int = int(SAMPLE_RATE * 2 * 16 / 1000)
	
	return get_file_main_info(key_as_path).merged({
		&"title": "Audio",
		&"duration": "%s s" % duration,
		&"sample_rate": "%s Hz" % SAMPLE_RATE,
		&"channels": "Stereo",
		&"bitrate": "%s Kbps" % bitrate,
	})

func get_video_file_info(key_as_path: StringName) -> Dictionary[StringName, String]:
	var info: Dictionary = MediaCache.get_video_info(key_as_path)
	var res: Vector2i = info.resolution
	var result: Dictionary[StringName, String] = get_file_main_info(key_as_path).merged({
		&"title": "Video",
		&"resolution": "(%s x %s)" % [res.x, res.y],
		&"frame_pixels": str(res.x * res.y),
		&"duration": "%s s" % info.duration,
		&"fps": "%s fps" % info.fps,
		&"total_frames": "%s frame" % info.total_frames,
		&"bit_depth": str(info.bit_depth, "-bit"),
	})
	return result


func create_clip_res_tree(root_res: MediaClipRes) -> Tree:
	var tree: Tree = IS.create_tree()
	var root_item: TreeItem = tree.create_item()
	root_item.set_text(0, root_res.get_display_name())
	root_item.set_icon(0, root_res.get_thumbnail())
	_tree_children_of(root_res, tree, root_item)
	return tree

func _tree_children_of(parent_res: MediaClipRes, tree: Tree, parent_tree_item: TreeItem) -> void:
	var layers: Array[LayerRes] = parent_res.layers
	
	for layer_idx: int in layers.size():
		var layer: LayerRes = layers[layer_idx]
		var clips: Dictionary[int, MediaClipRes] = layer.get_clips()
		for frame: int in clips:
			var clip_res: MediaClipRes = clips[frame]
			var tree_item: TreeItem = tree.create_item(parent_tree_item)
			tree_item.set_text(0, clip_res.get_display_name())
			tree_item.set_icon(0, clip_res.get_thumbnail())
			_tree_children_of(clip_res, tree, tree_item)

# Get Media Type

func get_media_type_from_path(path: String) -> MediaTypes:
	var extension = path.get_file().get_extension()
	var media_type: int = -1
	for i: PackedStringArray in ARR_MEDIA_EXTENSIONS:
		media_type += 1
		if extension in i:
			return media_type
	return -1

func get_media_classname_from_type(type: MediaTypes) -> StringName:
	match type:
		0: return &"ImageClipRes"
		1: return &"VideoClipRes"
		2: return &"AudioClipRes"
	return &""

func is_media_type_preset(path: String) -> bool:
	return path.get_extension() in ["res", "tres"]



