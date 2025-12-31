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

var imported_clip_info: Dictionary[int, Dictionary] = {
	0: {default_name = "Image", sections = [&"Display2D", &"Image", &"Color", &"Transition"], clip_panel = ImageClipPanel},
	1: {default_name = "Video", sections = [&"Display2D", &"Image", &"Color", &"Transition", &"Sound"], clip_panel = VideoClipPanel},
	2: {default_name = "Audio", sections = [&"Sound"], clip_panel = AudioClipPanel},
}

var object_clip_info: Dictionary[StringName, Dictionary] = {
	&"EmptyObject2D": {sections = [&"Display2D"]},
	&"Text2D": {sections = [&"Display2D", &"Transition", &"Text"], },
	&"Draw": {sections = [&"Display2D", &"Color", &"Draw"]},
	&"Particles2D": {sections = [&"Display2D", &"Particles"]},
	&"Camera2D": {sections = [&"Display2D", &"Camera"]},
	&"Audio2D": {sections = [&"Display2D", &"Sound"]},
}

const THUMBNAIL_TARGET_WIDTH: int = 128
const TIMELINE_VIDEO_IMAGE_WIDTH: int = 64
const TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH: int = 256

var thumbnails: Dictionary[StringName, Dictionary]
var timeline_video_textures: Dictionary[StringName, Dictionary]
var timeline_waveform_textures: Dictionary[StringName, Dictionary]

@onready var editor_settings: AppEditorSettings = EditorServer.editor_settings


func create_thumbnail_from_image(key_as_path: StringName, image: Image) -> Dictionary:
	var result_image: Image
	var result_texture: ImageTexture
	
	if image.get_width() > THUMBNAIL_TARGET_WIDTH:
		var scale: float = THUMBNAIL_TARGET_WIDTH / float(image.get_width())
		var target_height: int = image.get_height() * scale
		
		result_image = image.duplicate(true)
		result_image.resize(THUMBNAIL_TARGET_WIDTH, target_height, Image.INTERPOLATE_LANCZOS)
		result_texture = ImageTexture.create_from_image(result_image)
	
	else:
		result_image = image
		result_texture = MediaCache.get_texture(key_as_path)
	
	thumbnails[key_as_path] = {&"image": result_image, &"texture": result_texture}
	return thumbnails[key_as_path]

func create_thumbnail_from_video_path(video_path: StringName) -> Dictionary:
	return {}

func create_thumbnail_from_audio(key_as_path: StringName, audio: AudioStreamWAV) -> Dictionary:
	var thumbnail_image: Image = generate_waveform_image(audio, .0, INF, draw_waveform_line_thumbnail, Image.FORMAT_RGBA8, THUMBNAIL_TARGET_WIDTH, THUMBNAIL_TARGET_WIDTH, 2, 2, Color.TRANSPARENT)
	var thumbnail_texture: ImageTexture = ImageTexture.create_from_image(thumbnail_image)
	thumbnails[key_as_path] = {&"image": thumbnail_image, &"texture": thumbnail_texture}
	return thumbnails[key_as_path]

func get_thumbnail(key_as_path: StringName) -> Dictionary:
	return thumbnails[key_as_path]

func create_timeline_video_textures_from_video_path(video_path: StringName) -> Array[Image]:
	return []

func get_timeline_video_textures() -> Array[Image]:
	return []

func get_timeline_video_textures_range(frame_start: int, frame_end: int) -> Array[int]:
	return [] # image_from_index, pixel_from_index, image_to_index, pixel_to_index

func create_timeline_waveform_textures_from_audio(key_as_path: StringName, audio: AudioStreamWAV) -> Array[Image]:
	var waveform_images: Array[Image] = generate_waveform_images(audio, draw_waveform_line_timeline, ProjectServer.fps, TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH, 64, 0, 1, Color.TRANSPARENT)
	var waveform_textures: Array = waveform_images.map(func(image: Image) -> ImageTexture: return ImageTexture.create_from_image(image))
	var total_width: int
	for image: Image in waveform_images:
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
			media_length = MediaCache.get_audio(key_as_path).get_length()
		_: media_length = default_length
	return media_length

func get_media_default_from_and_length(media_res: MediaClipRes, default_from: int = -INF, default_length: int = INF) -> Vector2i:
	var result: Vector2i = Vector2i(default_from, default_length)
	if media_res is ImportedClipRes:
		var fps: int = ProjectServer.fps
		var key_as_path: StringName = media_res.key_as_path
		match media_res.type:
			ImportedClipRes.ImportedMediaType.MEDIA_TYPE_VIDEO:
				var video_info: Dictionary = MediaCache.get_video_info(key_as_path)
				result = Vector2i(-1, video_info.frame_count * video_info.frame_rate * fps)
			ImportedClipRes.ImportedMediaType.MEDIA_TYPE_AUDIO:
				result = Vector2i(-1, MediaCache.get_audio(key_as_path).get_length() * fps)
	return result

# Written by Omar TOP and edited by Claude AI
func generate_waveform_images(stream: AudioStreamWAV, draw_func: Callable, pixels_per_second: int = 30, width: int = 512, height: int = 64, space_width: int = 0, line_width: int = 1, bg_color: Color = Color.TRANSPARENT) -> Array[Image]:
	var images: Array[Image]
	
	var length: float = stream.get_length()
	var pixels_per_length: int = length * pixels_per_second
	var images_count: int = pixels_per_length / float(width)
	var chunk_length: float = width / float(pixels_per_second)
	
	var pixels_remained: int = pixels_per_length % width
	
	# إنشاء الصور الكاملة
	for time: int in images_count:
		var second_from: float = time * chunk_length
		var second_to: float = second_from + chunk_length
		var image: Image = generate_waveform_image(stream, second_from, second_to, draw_func, Image.FORMAT_RGBA8, width, height, space_width, line_width, bg_color)
		images.append(image)
	
	# إضافة الصورة الأخيرة فقط إذا كان هناك بكسلات متبقية
	if pixels_remained > 0:
		var length_remained: float = pixels_remained / float(pixels_per_second)
		images.append(generate_waveform_image(stream, length - length_remained, INF, draw_func, Image.FORMAT_RGBA8, pixels_remained, height, space_width, line_width, bg_color))
	
	return images

func generate_waveform_image(stream: AudioStreamWAV, second_from: float, second_to: float, draw_func: Callable, image_format: Image.Format, width: int, height: int, space_width: int, line_width: int, bg_color: Color = Color.BLACK) -> Image:
	var image: Image = Image.create_empty(width, height, false, image_format)
	image.fill(bg_color)
	
	# تحقق من أن التنسيق هو 16-bit
	if stream.format != AudioStreamWAV.FORMAT_16_BITS:
		push_error("Only 16-bit format is supported")
		return image
	
	var length: float = stream.get_length()
	var data: PackedByteArray = stream.data
	var data_size: int = data.size()
	
	var bytes_per_sample: int = 2 # 16-bit = 2 bytes
	var channels: int = 2 if stream.stereo else 1
	var sample_rate: int = stream.mix_rate
	
	# حساب موقع البداية في البيانات
	var start_sample: int = int(second_from * sample_rate)
	var start_byte: int = start_sample * bytes_per_sample * channels
	
	# حساب عدد العينات للفترة المطلوبة
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
		
		# حساب موقع البداية لهذا البكسل
		var sample_start: int = start_byte + (pixel_x * samples_per_pixel * bytes_per_sample * channels)
		
		# إيجاد القيمة القصوى من العينات المخصصة لهذا البكسل
		var max_amplitude: float = 0.0
		
		for s: int in samples_per_pixel / samples_step:
			var index: int = sample_start + (s * samples_step * bytes_per_sample * channels)
			if index + 1 >= data_size:
				break
			
			var sample_value: float = abs(data.decode_s16(index) / 32768.0)
			
			# إذا كان ستيريو، خذ متوسط القناتين
			if channels == 2 and index + 3 < data_size:
				var sample_value2: float = abs(data.decode_s16(index + 2) / 32768.0)
				sample_value = (sample_value + sample_value2) / 2.0
			max_amplitude = max(max_amplitude, sample_value)
		
		draw_func.call(image, width, height, line_width, pixel_x, max_amplitude)
	
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
	#var sample_height: int = int(sample * height)
	#for y: int in sample_height:
		#if y > height - 5: color = editor_settings.media_clip_waveform_high_color
		#elif y < height - 10: color = editor_settings.media_clip_waveform_low_color
		#else: color = editor_settings.media_clip_waveform_medium_color
		#for time: int in line_width:
			#image.set_pixel(x + time, height - y - 1, Color(Color.BLACK, .6))
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

class ClipPanel extends Panel:
	
	var owner_as_media_clip: MediaClip
	var is_graph_editor_opened: bool = false
	var has_clips: bool
	
	var curr_frame_in: int
	var curr_length: int
	var custom_height: float
	
	var margin_container: MarginContainer = IS.create_margin_container(8, 8, 8, 8)
	var box_container: BoxContainer = IS.create_box_container(0, true, {})
	var info_container: BoxContainer = IS.create_box_container(8, false, {})
	var thumbnail_rect: TextureRect
	var graph_editors: Dictionary[UsableRes, Dictionary]
	var graph_editors_expanded: Array[bool]
	
	func _init(_owner_as_media_clip: MediaClip) -> void:
		set_owner_as_media_clip(_owner_as_media_clip)
	
	func _ready() -> void:
		has_clips = owner_as_media_clip.clip_res.has_clips()
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		self.set_mouse_filter(Control.MOUSE_FILTER_PASS)
		_ready_ui()
		_update_ui()
	
	func _draw() -> void:
		if has_clips:
			draw_polygon(PackedVector2Array([
				size, size - Vector2(30.0, .0), size - Vector2(.0, 30.0),
			]), PackedColorArray([Color(.0,.0,.0,.6)]))
	
	func _ready_ui() -> void:
		info_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var thumbnail: Texture2D = _get_ui_thumbnail()
		if thumbnail:
			thumbnail_rect = IS.create_texture_rect(thumbnail, {})
			thumbnail_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			thumbnail_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			thumbnail_rect.custom_minimum_size.x = MediaServer.THUMBNAIL_TARGET_WIDTH
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
		margin_container.add_child(box_container)
		add_child(margin_container)
	
	func _update_ui(frame_in: int = -1, length: int = -1) -> void:
		curr_frame_in = frame_in
		curr_length = length
	
	func _update_ui_transform() -> void:
		await get_tree().process_frame
		var offset: float = max(8, EditorServer.time_line.global_position.x - global_position.x + 298.0)
		info_container.position.x = offset
	
	func _get_ui_thumbnail() -> Texture2D:
		return null
	
	func _get_ui_name() -> String:
		return owner_as_media_clip.clip_res.key_as_path.get_file()
	
	func get_owner_as_media_clip() -> MediaClip:
		return owner_as_media_clip
	func set_owner_as_media_clip(new_val: MediaClip) -> void:
		owner_as_media_clip = new_val
	
	func open_graph_editor() -> void:
		close_graph_editor()
		
		margin_container.add_theme_constant_override(&"margin_left", 0)
		margin_container.add_theme_constant_override(&"margin_right", 0)
		
		var media_res: MediaClipRes = owner_as_media_clip.clip_res
		var comps: Dictionary[String, Array] = media_res.components
		
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
						
						var graph_category:= IS.create_category(true, str(comp_res.get_res_id(), ":", prop_key), Color.TRANSPARENT, Vector2(.0, 250.0), false)
						var graph_editor:= CurveController.new()
						
						graph_editor.curves_profiles = anim_res.profiles
						graph_editor.min_domain = media_res.from
						graph_editor.max_domain = media_res.from + media_res.length
						graph_editor.keys_editing.connect(owner_as_media_clip.focus_panel.update_displayed_keys.bind(true))
						
						graph_category.add_content(graph_editor)
						box_container.add_child(graph_category)
						
						IS.expand(graph_editor, true, true)
						graph_category.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
						graph_category.is_expanded = graph_editors_expanded.size() - 1 >= index and graph_editors_expanded[index]
						graph_category.expand_changed.connect(update_custom_height)
						
						usable_res_port[prop_key] = graph_category
						
						index += 1
		
		is_graph_editor_opened = true
		update_custom_height()
		
		EditorServer.frame_changed.connect(_on_editor_server_frame_changed)
	
	func close_graph_editor() -> void:
		margin_container.add_theme_constant_override(&"margin_left", 8)
		margin_container.add_theme_constant_override(&"margin_right", 8)
		
		for usable_res: UsableRes in graph_editors:
			var usable_res_port: Dictionary[StringName, Category] = graph_editors[usable_res]
			for prop_key: StringName in usable_res_port:
				usable_res_port[prop_key].queue_free()
		
		graph_editors.clear()
		is_graph_editor_opened = false
		update_custom_height(false)
		_on_editor_server_frame_changed(EditorServer.frame)
		
		EditorServer.frame_changed.disconnect(_on_editor_server_frame_changed)
	
	func update_custom_height(update_graph_editors_expanded: bool = true) -> void:
		if update_graph_editors_expanded:
			graph_editors_expanded.clear()
		
		custom_height = ProjectServer.get_layer_customization(owner_as_media_clip.layer_index).size + 16
		var any_graph_opened: bool
		
		for usable_res: UsableRes in graph_editors:
			var usable_res_port: Dictionary[StringName, Category] = graph_editors[usable_res]
			
			for prop_key: StringName in usable_res_port:
				var category: Category = usable_res_port[prop_key]
				var category_is_expanded: bool = category.is_expanded
				custom_height += 20.0
				if category_is_expanded:
					category.size_flags_vertical = Control.SIZE_EXPAND_FILL
					custom_height += 250.0
					any_graph_opened = true
				else: category.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
				if update_graph_editors_expanded:
					graph_editors_expanded.append(category_is_expanded)
		
		if any_graph_opened: info_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		else: info_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		owner_as_media_clip.layer.update()
		await get_tree().process_frame
		owner_as_media_clip.focus_panel.update_displayed_keys(false)
	
	func _on_editor_server_frame_changed(new_frame: int) -> void:
		var new_local_frame: int = new_frame - owner_as_media_clip.clip_pos + owner_as_media_clip.clip_res.from
		for usable_res: UsableRes in graph_editors:
			var usable_res_port: Dictionary[StringName, Category] = graph_editors[usable_res]
			for prop_key: StringName in usable_res_port:
				usable_res_port[prop_key].content_container.get_child(0).set_cursor_pos(new_local_frame)


class ImageClipPanel extends ClipPanel:
	
	func _ready() -> void:
		super()
		add_theme_stylebox_override(&"panel", preload("uid://d0sgurvxit0n2"))
	
	func _get_ui_thumbnail() -> Texture2D:
		return MediaServer.get_thumbnail(owner_as_media_clip.clip_res.key_as_path).texture

class VideoClipPanel extends ClipPanel:
	func _ready() -> void:
		super()
		add_theme_stylebox_override(&"panel", preload("uid://bnc4n8cvuae5s"))

class AudioClipPanel extends ClipPanel:
	@onready var waveform_box_container: BoxContainer = IS.create_box_container(0, false, {})
	
	var texture_rects: Dictionary[int, TextureRect]
	
	var curr_waveform_textures_total_width: float
	var curr_waveform_start_index: Vector2i
	var curr_waveform_end_index: Vector2i
	
	func _ready() -> void:
		super()
		add_theme_stylebox_override(&"panel", preload("uid://djbj0r563olrv"))
	
	func _ready_ui() -> void:
		add_child(waveform_box_container)
		super()
	
	func _update_ui(frame_in: int = -1, length: int = -1) -> void:
		print()
		var clip_res: MediaClipRes = owner_as_media_clip.clip_res
		if frame_in == -1: frame_in = clip_res.from
		if length == -1: length = clip_res.length
		super(frame_in, length)
		
		var waveform_start_index: Vector2i = MediaServer.get_timeline_waveform_texture_index(frame_in)
		var waveform_end_index: Vector2i = MediaServer.get_timeline_waveform_texture_index(frame_in + length)
		
		var waveform_textures_info: Dictionary = MediaServer.get_timeline_waveform_textures(clip_res.key_as_path)
		var waveform_textures: Array = waveform_textures_info.textures
		var ranged_waveform_textures: Array = waveform_textures.slice(waveform_start_index.x, waveform_end_index.x)
		
		# Remove
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
		
		var texture_ratio: float = MediaServer.TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH / curr_total_width
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
			waveform_box_container.move_child(texture_rect, time)
		
		curr_waveform_textures_total_width = curr_total_width
		curr_waveform_start_index = waveform_start_index
		curr_waveform_end_index = waveform_end_index
		
		_update_ui_transform()
	
	func _update_ui_transform() -> void:
		var length_ratio: float = owner_as_media_clip.size.x / curr_length
		var textures_total_size: float = curr_waveform_textures_total_width * length_ratio
		var waveform_start_offset: float = curr_waveform_start_index.y * length_ratio
		
		waveform_box_container.position.x = -waveform_start_offset
		waveform_box_container.size.x = textures_total_size
		
		super()
	
	func _push_waveform_texture_rect(texture: ImageTexture) -> Control:
		var texture_rect: TextureRect = IS.create_texture_rect(texture, {})
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		waveform_box_container.add_child(texture_rect)
		return texture_rect

class ObjectClipPanel extends ClipPanel:
	func _ready() -> void:
		super()
		thumbnail_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumbnail_rect.custom_minimum_size.x = 50.0
		add_theme_stylebox_override(&"panel", preload("uid://dxxh6guqix0k"))
	
	func _get_ui_name() -> String:
		return owner_as_media_clip.clip_res.object_res.get_res_id()
	
	func _get_ui_thumbnail() -> Texture2D:
		var res_id: StringName = owner_as_media_clip.clip_res.object_res.get_res_id()
		return TypeServer.objects[res_id].icon


func get_file_main_info(path: StringName, get_more_meta_func: Callable = Callable()) -> Dictionary[StringName, String]:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
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
	return get_file_main_info(key_as_path).merged({
		&"title": "Video"
	})


func get_clip_sections(media_res: MediaClipRes) -> Array:
	if media_res is ImportedClipRes:
		return imported_clip_info[media_res.type].sections
	elif media_res is ObjectClipRes:
		return object_clip_info[media_res.object_res.get_res_id()].sections
	return []







#var media_preloaded: Dictionary[String, Variant] = {}
#var audio_durations: Dictionary[String, float] # as Seconds

func _ready() -> void:
	#await get_tree().create_timer(1.0).timeout
	#var audio_path = "res://untitled.mp3"
	#var audio_dur = get_audio_duration_with_ffprobe(audio_path)
	#generate_waveform_dynamic(audio_path, audio_path + ".png", audio_dur)
	pass

# Image Services

#func get_image_texture_from_path(path: String) -> ImageTexture:
	#if media_preloaded.has(path):
		#return media_preloaded[path]
	#var image: Image = Image.load_from_file(path)
	#var image_texture: ImageTexture = ImageTexture.create_from_image(image)
	#media_preloaded[path] = image_texture
	#return image_texture

# Video Services

#func get_video_display_texture_from_path(path: String, thumbnails_folder_path: String) -> ImageTexture:
	#var output_path = "%s/%s%s" % [thumbnails_folder_path, path.get_file(), ".jpg"]
	#if not FileAccess.file_exists(output_path):
		#extract_video_thumbnail(path, output_path)
	#return get_image_texture_from_path(output_path)

#func extract_video_thumbnail(video_path: String, output_path: String) -> void:
	#var ffmpeg_path = ProjectSettings.globalize_path("res://FFmpeg/ffmpeg.exe")
	#var abs_video_path = ProjectSettings.globalize_path(video_path)
	#var abs_output_path = ProjectSettings.globalize_path(output_path)
	#
	#var args = [
		#"-i", abs_video_path,
		#"-ss", "00:00:01.000",
		#"-vframes", "1",
		#"-s", "320x180",
		#"-q:v", "10",
		#abs_output_path
	#]
	#
	#var err = OS.execute(ffmpeg_path, args, [], true)
	#if err != OK:
		#printerr("Failed to start ffmpeg:", err)

#func is_stream_has_audio(file_path: String) -> bool:
	#var ffmpeg_path = ProjectSettings.globalize_path("res://FFmpeg/ffmpeg.exe")
	#var abs_path = ProjectSettings.globalize_path(file_path)
	#var args = ["-i", abs_path]
	#var output = []
	#var code = OS.execute(ffmpeg_path, args, output, true)
	#
	#for line in output:
		#if "Stream #" in line and "Audio" in line:
			#return true
	#return false

# Audio Services

#func get_audio_stream_from_path(audio_path: String) -> AudioStreamWAV:
	#var preload_key = audio_path + "_audio"
	#if not media_preloaded.has(preload_key):
		#media_preloaded[preload_key] = AudioStreamHelper.create_stream_from_path(audio_path)
	#return media_preloaded[preload_key]

#func get_audio_display_texture_from_path(path: String, thumbnails_folder_path: String, color_key: String = "bfbfbf", fixed_size: bool = true, size:= Vector2i(320, 180)) -> ImageTexture:
	#var output_path = "%s/%s%s" % [thumbnails_folder_path, path.get_file(), ".png"]
	#if not FileAccess.file_exists(output_path):
		#generate_waveform_dynamic(path, output_path, get_audio_duration_with_ffprobe(path), color_key, fixed_size, size)
	#return get_image_texture_from_path(output_path)

#func get_audio_duration_with_ffprobe(audio_path: String) -> float:
	#
	#if audio_durations.has(audio_path):
		#return audio_durations[audio_path]
	#
	#var ffprobe_path = ProjectSettings.globalize_path("res://FFmpeg/ffprobe.exe")
	#var abs_audio_path = ProjectSettings.globalize_path(audio_path)
	#var args = ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", abs_audio_path]
	#var output = []
	#var err = OS.execute(ffprobe_path, args, output)
	#if err == OK:
		#var result_dur = output[0].to_float()
		#audio_durations[audio_path] = result_dur
		#return result_dur
	#else:
		#printerr("Failed to get duration")
		#return .0

func generate_waveform_dynamic(audio_path: String, output_path: String, duration_seconds: float, color_key: String, fixed_size:= false, size:= Vector2i.ONE) -> void:
	var ffmpeg_path = ProjectSettings.globalize_path("res://FFmpeg/ffmpeg.exe")
	var abs_audio_path = ProjectSettings.globalize_path(audio_path)
	var abs_output_path = ProjectSettings.globalize_path(output_path)
	
	var pixels_per_second = 30
	var width = int(duration_seconds * pixels_per_second)
	var height = 120
	if fixed_size:
		width = size.x
		height = size.y
	
	var resolution = str(width, "x", height)
	var filter = "aformat=channel_layouts=mono,volume=6,showwavespic=s=" + resolution + ":colors=%s" % color_key
	
	var args = [
		"-i", abs_audio_path,
		"-filter_complex", filter,
		"-frames:v", "1",
		abs_output_path
	]
	
	var err = OS.execute(ffmpeg_path, args)
	if err != OK:
		printerr("Failed to generate waveform image:", err)

# Get Media Type

func get_media_type_from_path(path: String) -> MediaTypes:
	var extension = path.get_file().get_extension()
	var media_type: int = -1
	for i: PackedStringArray in ARR_MEDIA_EXTENSIONS:
		media_type += 1
		if extension in i:
			return media_type
	return -1

