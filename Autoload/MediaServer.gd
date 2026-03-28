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
	&"ImageClipRes": {sections = [&"Display2D", &"Image", &"Color", &"Transition"], clip_panel = ImageClipPanel},
	&"VideoClipRes": {sections = [&"Display2D", &"Image", &"Color", &"Transition", &"Sound"], clip_panel = VideoClipPanel},
	&"AudioClipRes": {sections = [&"Sound"], clip_panel = AudioClipPanel},
	&"Text2DClipRes": {sections = [&"Display2D", &"Text"]},
	&"Shape2DClipRes": {sections = [&"Display2D", &"Shape"]},
	&"Particles2DClipRes": {sections = [&"Display2D", &"Particles"]},
	&"Camera2DClipRes": {sections = [&"Display2D", &"Camera"]},
	&"Audio2DClipRes": {sections = [&"Display2D", &"Sound"], clip_panel = Audio2DClipPanel}
}

const THUMBNAIL_TARGET_WIDTH: int = 128
const TIMELINE_VIDEO_IMAGE_WIDTH: int = 64
const TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH: int = 256

const THUMBNAIL_DISCARD: Dictionary = {&"texture": IS.TEXTURE_X_MARK}

var thumbnails: Dictionary[StringName, Dictionary]
var timeline_video_textures: Dictionary[StringName, Dictionary]
var timeline_waveform_textures: Dictionary[StringName, Dictionary]

var editor_settings: AppEditorSettings = EditorServer.editor_settings

var not_saved_yet: Dictionary[String, Resource] = {}
var not_deleted_yet: Array[String] = []

func server_register_image(path: String, image: Image, ids_exists: PackedStringArray, id: String, thumbnail_path: String) -> void:
	if ids_exists.has(id): load_thumbnail(path, thumbnail_path, id)
	else: create_thumbnail_from_image(path, image, thumbnail_path, id)

func server_register_video(path: String, video_decoder: VideoDecoder, audio_stream: AudioStreamWAV, ids_exists: PackedStringArray, id: String, thumbnail_path: String, waveform_path: String) -> void:
	if ids_exists.has(id):
		load_thumbnail(path, thumbnail_path, id)
		load_waveform(path, waveform_path, id)
	else:
		create_thumbnail_from_video(path, video_decoder, thumbnail_path, id)
		create_timeline_waveform_textures_from_audio(path, audio_stream, waveform_path, id)

func server_register_audio(path: String, audio_stream: AudioStreamWAV, ids_exists: PackedStringArray, id: String, thumbnail_path: String, waveform_path: String) -> void:
	if ids_exists.has(id):
		load_thumbnail(path, thumbnail_path, id)
		load_waveform(path, waveform_path, id)
	else:
		create_thumbnail_from_audio(path, audio_stream, thumbnail_path, id)
		create_timeline_waveform_textures_from_audio(path, audio_stream, waveform_path, id)

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

func server_deregister_image(path: String, id: String, thumbnail_path: String) -> void:
	thumbnails.erase(path)
	store_not_deleted_thumbnail(thumbnail_path, id)

func server_deregister_video(path: String, id: String, thumbnail_path: String, waveform_path: String) -> void:
	thumbnails.erase(path)
	timeline_waveform_textures.erase(path)

func server_deregister_audio(path: String, id: String, thumbnail_path: String, waveform_path: String) -> void:
	thumbnails.erase(path)
	timeline_waveform_textures.erase(path)
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

func create_thumbnail_from_audio(key_as_path: StringName, audio: AudioStreamWAV, thumbnail_path: String, id: String) -> Dictionary:
	var thumbnail_image: Image = generate_waveform_image(audio, .0, INF, draw_waveform_line_thumbnail, Image.FORMAT_RGBA8, THUMBNAIL_TARGET_WIDTH, THUMBNAIL_TARGET_WIDTH, 2, 2, Color.TRANSPARENT)
	thumbnails[key_as_path] = {&"image": thumbnail_image, &"texture": ImageTexture.create_from_image(thumbnail_image)}
	store_not_saved_thumbnail(thumbnail_path, id, thumbnail_image)
	return thumbnails[key_as_path]

#func create_thumbnail_from_preset_media_res(key_as_path: StringName, preset_media_res: MediaClipRes, thumbnail_path: String, id: String) -> Dictionary:
	#var thumbnail_image: Image = await popup_shot_preset_media_res(preset_media_res)
	#thumbnails[key_as_path] = {&"image": thumbnail_image, &"texture": ImageTexture.create_from_image(thumbnail_image)}
	#save_thumbnail(thumbnail_image, thumbnail_path, id)
	#return thumbnails[key_as_path]

func create_timeline_video_textures_from_video_path(video_path: StringName) -> Array[Image]:
	return []

func get_timeline_video_textures() -> Array[Image]:
	return []

func get_timeline_video_textures_range(frame_start: int, frame_end: int) -> Array[int]:
	return [] # image_from_index, pixel_from_index, image_to_index, pixel_to_index

func create_timeline_waveform_textures_from_audio(key_as_path: StringName, audio: AudioStreamWAV, waveform_path: String, id: String) -> Array[Image]:
	if not audio:
		return []
	var waveform_images: Array[Image] = generate_waveform_images(audio, draw_waveform_line_timeline, ProjectServer2.fps, TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH, 64, 0, 1, Color.TRANSPARENT)
	var waveform_textures: Array = waveform_images.map(func(image: Image) -> ImageTexture: return ImageTexture.create_from_image(image))
	var total_width: int
	var waveform_port_path: String = str(waveform_path, id, "/")
	DirAccess.make_dir_recursive_absolute(waveform_port_path)
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

func get_media_default_length(media_type: int, key_as_path: StringName, default_length: float = editor_settings.media_clip_default_length) -> float:
	var media_length: float
	match media_type:
		ImportedClipRes.ImportedMediaType.MEDIA_TYPE_VIDEO:
			var video_info: Dictionary = MediaCache.get_video_info(key_as_path)
			media_length = video_info.frame_count * video_info.frame_rate
		
		ImportedClipRes.ImportedMediaType.MEDIA_TYPE_AUDIO:
			var audio_wav: AudioStreamWAV = MediaCache.get_audio(key_as_path)
			if audio_wav: media_length = MediaCache.get_audio(key_as_path).get_length()
		_:
			media_length = default_length
	return media_length

func get_media_default_from_and_length(media_res: MediaClipRes, default_from: int = -INF, default_length: int = INF) -> Vector2i:
	var result: Vector2i = Vector2i(default_from, default_length)
	
	if media_res is ImportedClipRes:
		
		var fps: int = ProjectServer2.fps
		var key_as_path: StringName = media_res.key_as_path
		
		match media_res.type:
			
			ImportedClipRes.ImportedMediaType.MEDIA_TYPE_VIDEO:
				var video_info: Dictionary = MediaCache.get_video_info(key_as_path)
				result = Vector2i(-1, video_info.frame_count * video_info.frame_rate * fps)
			
			ImportedClipRes.ImportedMediaType.MEDIA_TYPE_AUDIO:
				var audio_wav: AudioStreamWAV = MediaCache.get_audio(key_as_path)
				if audio_wav: result = Vector2i(-1, audio_wav.get_length() * fps)
	
	return result

# Written by Omar TOP and edited by Claude AI
func generate_waveform_images(stream: AudioStreamWAV, draw_func: Callable, pixels_per_second: int = 30, width: int = 512, height: int = 64, space_width: int = 0, line_width: int = 1, bg_color: Color = Color.TRANSPARENT) -> Array[Image]:
	var images: Array[Image]
	
	var length: float = stream.get_length()
	var pixels_per_length: int = length * pixels_per_second
	var images_count: int = pixels_per_length / float(width)
	var chunk_length: float = width / float(pixels_per_second)
	
	var pixels_remained: int = pixels_per_length % width
	
	for time: int in images_count:
		var second_from: float = time * chunk_length
		var second_to: float = second_from + chunk_length
		var image: Image = generate_waveform_image(stream, second_from, second_to, draw_func, Image.FORMAT_RGBA8, width, height, space_width, line_width, bg_color)
		images.append(image)
	
	if pixels_remained > 0:
		var length_remained: float = pixels_remained / float(pixels_per_second)
		images.append(generate_waveform_image(stream, length - length_remained, INF, draw_func, Image.FORMAT_RGBA8, pixels_remained, height, space_width, line_width, bg_color))
	
	return images

func generate_waveform_image(stream: AudioStreamWAV, second_from: float, second_to: float, draw_func: Callable, image_format: Image.Format, width: int, height: int, space_width: int, line_width: int, bg_color: Color = Color.BLACK) -> Image:
	var image: Image = Image.create_empty(width, height, false, image_format)
	image.fill(bg_color)
	
	if stream.format != AudioStreamWAV.FORMAT_16_BITS:
		printerr("Only 16-bit format is supported")
		return image
	
	var length: float = stream.get_length()
	var data: PackedByteArray = stream.data
	var data_size: int = data.size()
	
	var bytes_per_sample: int = 2
	var channels: int = 2 if stream.stereo else 1
	var sample_rate: int = stream.mix_rate
	
	var start_sample: int = int(second_from * sample_rate)
	var start_byte: int = start_sample * bytes_per_sample * channels
	
	second_to = min(length, second_to)
	var duration: float = second_to - second_from
	var total_samples: int = int(duration * sample_rate)
	var samples_per_pixel: int = max(1, (total_samples / width))
	
	space_width += line_width
	var lines_count: int = width / space_width
	
	var target_samples_count: int
	if samples_per_pixel < 500: target_samples_count = 250
	elif samples_per_pixel < 5_000: target_samples_count = 500
	elif samples_per_pixel < 50_000: target_samples_count = 750
	elif samples_per_pixel < 500_000: target_samples_count = 1_000
	else: target_samples_count = 1_500
	var samples_step: int = max(1, samples_per_pixel / target_samples_count)
	
	for x: int in lines_count:
		var pixel_x: int = x * space_width
		
		var sample_start: int = start_byte + (pixel_x * samples_per_pixel * bytes_per_sample * channels)
		
		var max_amplitude: float = .0
		
		for s: int in samples_per_pixel / samples_step:
			var index: int = sample_start + (s * samples_step * bytes_per_sample * channels)
			if index + 1 >= data_size:
				break
			
			var sample_value: float = absf(data.decode_s16(index) / 32768.)
			
			if channels == 2 and index + 3 < data_size:
				var sample_value2: float = absf(data.decode_s16(index + 2) / 32768.)
				sample_value = (sample_value + sample_value2) / 2.
			max_amplitude = maxf(max_amplitude, sample_value)
		
		draw_func.call(image, width, height, line_width, pixel_x, max_amplitude)
	
	image.generate_mipmaps()
	
	return image

func draw_waveform_line_thumbnail(image: Image, width: int, height: int, line_width: int, x: int, sample: float) -> void:
	var gradient: Gradient = editor_settings.media_explorer_waveform_gradient
	var offset: float = x / float(width)
	
	var height_half: int = height / 2
	var sample_height: int = int(sample * height)
	
	image.fill_rect(
		Rect2i(
			Vector2i(x, height_half - sample_height / 2.0),
			Vector2i(line_width, sample_height)
		),
		gradient.sample(offset)
	)

func draw_waveform_line_timeline(image: Image, width: int, height: int, line_width: int, x: int, sample: float) -> void:
	var offset: float = x / float(width)
	
	var height_half: int = height / 2
	var sample_height: int = int(sample * height)
	
	image.fill_rect(
		Rect2i(
			Vector2i(x, height_half - sample_height / 2.0),
			Vector2i(line_width, sample_height)
		),
		Color(Color.BLACK, .6)
	)



class ClipPanel extends PanelContainer:
	
	const STYLE_SELECTED: StyleBoxFlat = preload("uid://kkroptu2c0c1")
	
	@onready var margin_container: MarginContainer = IS.create_margin_container(4, 4, 4, 4)
	@onready var control: Control = IS.create_empty_control(.0, .0)
	@onready var box_container: BoxContainer = IS.create_box_container(4, true, {})
	@onready var info_container: BoxContainer = IS.create_box_container(8, false, {})
	@onready var thumbnail_rect: TextureRect
	@onready var select_panel: Panel = IS.create_panel(STYLE_SELECTED, {modulate = Color(1., 1., 1., .75)})
	
	var is_graph_editor_opened: bool = false
	var graph_editors: Dictionary[UsableRes, Dictionary]
	var graph_editors_expanded: Array[bool]
	
	var layer_idx: int
	var frame: int
	var clip_res: MediaClipRes
	
	var has_clips: bool
	
	var event_startpos: Vector2
	
	func _init(_clip_res: MediaClipRes) -> void:
		clip_res = _clip_res
	
	func _ready() -> void:
		update_has_clips()
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_ready_ui()
		_update_ui()
	
	func _gui_input(event: InputEvent) -> void:
		
		if event is InputEventMouseButton:
			var pressed: bool = event.is_pressed()
			if pressed:
				event_startpos = event.position
			else:
				match event.button_index:
					MOUSE_BUTTON_LEFT:
						select(event.alt_pressed, not event.ctrl_pressed)
					MOUSE_BUTTON_RIGHT:
						var layers_body: TimeLine2.LayersSelectContainer = EditorServer.time_line2.layers_body
						select(false, not event.ctrl_pressed and not layers_body.is_val_selected(layer_idx, frame))
						layers_body.popup_options_menu(layers_body._get_menu_options() + layers_body.clips_menu)
	
	func _draw() -> void:
		if has_clips:
			draw_polygon(PackedVector2Array([
				size, size - Vector2(30.0, .0), size - Vector2(.0, 30.0),
			]), PackedColorArray([Color(.0,.0,.0,.6)]))
	
	func select(delete: bool, preclear: bool) -> void:
		var layers_select_cont: TimeLine2.LayersSelectContainer = EditorServer.time_line2.layers_body
		layers_select_cont.manage_val(layer_idx, frame, delete, preclear)
		layers_select_cont.emit_selected_changed()
	
	func update_has_clips() -> void:
		has_clips = clip_res.has_clips()
	
	func _ready_ui() -> void:
		
		clip_contents = true
		control.clip_contents = true
		info_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var thumbnail: Texture2D = _get_ui_thumbnail()
		if thumbnail:
			thumbnail_rect = IS.create_texture_rect(thumbnail, {})
			thumbnail_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			thumbnail_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			IS.expand(thumbnail_rect)
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
		control.add_child(box_container)
		margin_container.add_child(control)
		add_child(margin_container)
		
		select_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		select_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	
	func open_graph_editor() -> void:
		close_graph_editor()
		
		margin_container.add_theme_constant_override(&"margin_left", 0)
		margin_container.add_theme_constant_override(&"margin_right", 0)
		
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
						
						graph_category.add_content(graph_editor)
						box_container.add_child(graph_category)
						
						IS.set_margin_settings(graph_category.content_margin_container, 0, 0, 0, 0)
						graph_category.content_color = Color.BLACK
						
						IS.expand(graph_editor, true, true)
						graph_category.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
						graph_category.is_expanded = graph_editors_expanded.size() - 1 >= index and graph_editors_expanded[index]
						graph_category.expand_changed.connect(_on_graph_category_expand_changed)
						
						usable_res_port[prop_key] = graph_category
						
						index += 1
		
		is_graph_editor_opened = true
		
		EditorServer.frame_changed.connect(_on_editor_server_frame_changed)
	
	func close_graph_editor() -> void:
		margin_container.add_theme_constant_override(&"margin_left", 4)
		margin_container.add_theme_constant_override(&"margin_right", 4)
		
		for usable_res: UsableRes in graph_editors:
			var usable_res_port: Dictionary[StringName, Category] = graph_editors[usable_res]
			for prop_key: StringName in usable_res_port:
				usable_res_port[prop_key].queue_free()
		
		graph_editors.clear()
		is_graph_editor_opened = false
		_on_editor_server_frame_changed(EditorServer.frame)
		
		EditorServer.frame_changed.disconnect(_on_editor_server_frame_changed)
	
	func _on_graph_editor_mouse_entered(graph_editor: CurveController) -> void:
		EditorServer.graph_editors_focused.append(graph_editor)
	
	func _on_graph_editor_mouse_exited(graph_editor: CurveController) -> void:
		EditorServer.graph_editors_focused.erase(graph_editor)
	
	func _on_graph_category_expand_changed() -> void:
		var timeline: TimeLine2 = EditorServer.time_line2
		var layer_res: LayerRes = timeline.opened_clip_res.get_layer(layer_idx)
		var layer: Layer2 = timeline.get_layer(layer_res)
		
		for frame: int in layer.clips:
			layer.get_clip(frame).control.size.y = layer_res.custom_size
		
		await get_tree().process_frame
		timeline.get_layer(layer_res).update_size()
	
	func _on_editor_server_frame_changed(new_frame: int) -> void:
		var new_local_frame: int = new_frame - clip_res.clip_pos + clip_res.from
		for usable_res: UsableRes in graph_editors:
			var usable_res_port: Dictionary[StringName, Category] = graph_editors[usable_res]
			for prop_key: StringName in usable_res_port:
				usable_res_port[prop_key].content_container.get_child(0).set_cursor_pos(new_local_frame)

class ImageClipPanel extends ClipPanel:
	
	func _ready() -> void:
		super()
		add_theme_stylebox_override(&"panel", preload("uid://d0sgurvxit0n2"))

class VideoClipPanel extends ClipPanel:
	
	@onready var waveform_box_container:= WaveformBoxContainer.new()
	
	var texture_rects: Dictionary[int, TextureRect]
	
	func _ready() -> void:
		super()
		add_theme_stylebox_override(&"panel", preload("uid://bnc4n8cvuae5s"))
	
	func _ready_ui() -> void:
		add_child(waveform_box_container)
		super()
		thumbnail_rect.modulate.a = .9
	
	func _update_ui() -> void:
		
		waveform_box_container.update_ui(clip_res.video, clip_res.from, clip_res.length)
		_update_ui_transform()
	
	func _update_ui_transform() -> void:
		var waveform_transform: Vector2 = waveform_box_container.calculate_transform(size, clip_res.length)
		waveform_box_container.position.x = waveform_transform.x
		waveform_box_container.size.x = waveform_transform.y
		super()

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
		var clip_res: MediaClipRes = clip_res
		
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
		var audio_key_as_path: String = clip_res.stream
		
		waveform_box_container.update_ui(audio_key_as_path, clip_res.from, clip_res.length)
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
	var audio_stream: AudioStreamWAV = MediaCache.get_audio(key_as_path)
	
	var duration: float = snapped(audio_stream.get_length(), .001)
	var sample_rate: int = audio_stream.mix_rate
	var channels_str: String
	var channels_int: int
	
	if audio_stream.stereo:
		channels_str = "Stereo"
		channels_int = 2
	else:
		channels_str = "Mono"
		channels_int = 1
	
	var bitrate: int = int(sample_rate * channels_int * 16 / 1000)
	
	return get_file_main_info(key_as_path).merged({
		&"title": "Audio",
		&"duration": "%s s" % duration,
		&"sample_rate": "%s Hz" % sample_rate,
		&"channels": channels_str,
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


func create_media_res_tree(root_res: MediaClipRes) -> Tree:
	var tree: Tree = IS.create_tree()
	var root_item: TreeItem = tree.create_item()
	root_item.set_text(0, root_res.get_display_name())
	root_item.set_icon(0, root_res.get_thumbnail())
	_tree_children_of(root_res, tree, root_item)
	return tree

func _tree_children_of(parent_res: MediaClipRes, tree: Tree, parent_tree_item: TreeItem) -> void:
	var children: Dictionary[int, Dictionary] = parent_res.get_children()
	for layer_index: int in children:
		var layer_children: Dictionary = children[layer_index].media_clips
		for frame_in: int in layer_children:
			var media_res: MediaClipRes = layer_children[frame_in]
			var tree_item: TreeItem = tree.create_item(parent_tree_item)
			tree_item.set_text(0, media_res.get_display_name())
			tree_item.set_icon(0, media_res.get_thumbnail())
			_tree_children_of(media_res, tree, tree_item)

# Get Media Type

func get_media_type_from_path(path: String) -> MediaTypes:
	var extension = path.get_file().get_extension()
	var media_type: int = -1
	for i: PackedStringArray in ARR_MEDIA_EXTENSIONS:
		media_type += 1
		if extension in i:
			return media_type
	return -1

func is_media_type_preset(path: String) -> bool:
	return path.get_extension() in ["res", "tres"]
