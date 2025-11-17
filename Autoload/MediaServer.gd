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

var media_clip_info: Dictionary[int, Dictionary] = {
	0: {default_name = "Image", sections = ["Display2D", "Image", "Color", "Transition"], style = preload("uid://d0sgurvxit0n2")}, # Image
	1: {default_name = "Video", sections = ["Display2D", "Image", "Color", "Transition", "Sound"], style = preload("uid://bnc4n8cvuae5s")}, # Video
	2: {default_name = "Audio", sections = ["Sound"], style = preload("uid://djbj0r563olrv")}, # Audio
	3: {default_name = "Empty Object 2D", sections = ["Display2D"], style = preload("uid://djp5a3r486n1c"), thumbnail = preload("uid://cnd2y4daw32sc")}, # Empty Object 2D
	4: {default_name = "Text", sections = ["Display2D", "Transition", "Text"], style = preload("uid://bum2qjv15h7uu"), thumbnail = null}, # Text
	5: {default_name = "Draw", sections = ["Display2D", "Color", "Draw"], style = preload("uid://bdh5bw2do3yxc"), thumbnail = preload("uid://b34e2o0he11w5")}, # Draw
	6: {default_name = "Particles", sections = ["Display2D", "Particles"], style = preload("uid://cutvayr76572b"), thumbnail = null}, # Particles
	7: {default_name = "Camera 2D", sections = ["Display2D", "Camera"], style = preload("uid://dxxh6guqix0k"), thumbnail = preload("uid://dbafad8ipb25s")}, # Camera 2D
	8: {default_name = "Audio 2D", sections = ["Display2D", "Sound"], style = preload("uid://pk4vsqxdvixi"), thumbnail = preload("uid://bodxdwiaqu416")} # Audio 2D
}


const THUMBNAIL_TARGET_WIDTH: int = 128
const TIMELINE_VIDEO_IMAGE_WIDTH: int = 64
const TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH: int = 512

var thumbnails: Dictionary[StringName, Dictionary]
var timeline_video_images: Dictionary[StringName, Array]
var timeline_waveform_images: Dictionary[StringName, Array]

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

func create_timeline_video_images_from_video_path(video_path: StringName) -> Array[Image]:
	return []

func get_timeline_video_images() -> Array[Image]:
	return []

func get_timeline_video_images_range(frame_start: int, frame_end: int) -> Array[int]:
	return [] # image_from_index, pixel_from_index, image_to_index, pixel_to_index

func create_timeline_waveform_images_from_audio(key_as_path: StringName, audio: AudioStreamWAV) -> Array[Image]:
	var waveform_images: Array[Image] = generate_waveform_images(audio, draw_waveform_line_timeline, ProjectServer.fps, TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH, 64, 1, 2, Color.TRANSPARENT)
	timeline_waveform_images[key_as_path] = waveform_images
	return waveform_images

func get_timeline_waveform_images(key_as_path: StringName) -> Array[Image]:
	return timeline_waveform_images[key_as_path]

func get_timeline_waveform_images_range(frame_start: int, frame_end: int) -> Array[int]:
	return [
		frame_start / TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH,
		frame_start % TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH,
		frame_end / TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH,
		frame_end % TIMELINE_WAVEFORM_IMAGES_CHUNK_WIDTH
	] # image_from_index, pixel_from_index, image_to_index, pixel_to_index

func get_media_length(media_type: int, key_as_path: StringName) -> float:
	var media_length: float
	
	match media_type:
		
		MediaClipRes.MediaType.MEDIA_TYPE_VIDEO:
			var video_info: Dictionary = MediaCache.get_video_info(key_as_path)
			media_length = video_info.frame_count * video_info.frame_rate
		
		MediaClipRes.MediaType.MEDIA_TYPE_AUDIO:
			media_length = MediaCache.get_audio(key_as_path).get_length()
		
		_:
			media_length = EditorServer.editor_settings.media_clip_default_length
	
	return media_length


# Written by Omar TOP and edited by Claude AI
func generate_waveform_images(stream: AudioStreamWAV, draw_func: Callable, pixels_per_second: int = 30, width: int = 512, height: int = 64, space_width: int = 0, line_width: int = 1, bg_color: Color = Color.TRANSPARENT) -> Array[Image]:
	var images: Array[Image]
	
	var length: float = stream.get_length()
	var pixels_per_length: int = length * pixels_per_second
	var images_count: int = pixels_per_length / width
	var chunk_length: float = length / images_count
	
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
	var sample_height: int = int(sample * height)
	for y: int in sample_height:
		var color: Color
		if y > height - 5: color = editor_settings.media_clip_waveform_high_color
		elif y < height - 10: color = editor_settings.media_clip_waveform_low_color
		else: color = editor_settings.media_clip_waveform_medium_color
		image.set_pixel(x, height - y - 1, color)


class ClipPanelContainer extends PanelContainer:
	
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)






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
		#return 0.0

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

func get_types_intersection_properties_sections(types: Array[int]) -> Array:
	var types_sections: Array[Array]
	
	for type: int in types:
		var type_sections: Array = media_clip_info.get(type).sections
		types_sections.append(type_sections)
	
	if types_sections.is_empty():
		return []
	
	var result: Array = types_sections[0]
	for index: int in range(0, types_sections.size()):
		result = result.filter(func(element: String) -> bool: return element in types_sections[index])
	
	return result














