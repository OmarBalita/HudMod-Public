extends Node

enum MediaTypes {
	IMAGE,
	VIDEO,
	AUDIO,
	TEXT,
	SHAPE,
	ADJUSTMENT,
	CODE,
	PARTICLES
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

const AUDIO_EXTENSIONS: PackedStringArray = [
	"wav", "ogg", "mp3", "flac", "opus"
]

const MEDIA_EXTENSIONS = IMAGE_EXTENSIONS + VIDEO_EXTENSIONS + AUDIO_EXTENSIONS

const ARR_MEDIA_EXTENSIONS = [
	IMAGE_EXTENSIONS, VIDEO_EXTENSIONS, AUDIO_EXTENSIONS
]


var media_clip_info: Dictionary[int, Dictionary] = {
	0: {style = preload("uid://d0sgurvxit0n2"), control = InterfaceServer.create_clip_image_control}, # Image
	1: {style = preload("uid://bnc4n8cvuae5s"), control = InterfaceServer.create_clip_video_control}, # Video
	2: {style = preload("uid://djbj0r563olrv"), control = InterfaceServer.create_clip_audio_control}, # Audio
	3: {style = preload("uid://d0sgurvxit0n2"), control = null}, # Text
	4: {style = preload("uid://d0sgurvxit0n2"), control = null}, # Shape
	5: {style = preload("uid://d0sgurvxit0n2"), control = null}, # Effect
	6: {style = preload("uid://d0sgurvxit0n2"), control = null} # CODE (procedural)
}



var media_preloaded: Dictionary[String, Variant] = {}

var audio_durations: Dictionary[String, float] # as Seconds








func _ready() -> void:
	#await get_tree().create_timer(1.0).timeout
	#var audio_path = "res://untitled.mp3"
	#var audio_dur = get_audio_duration_with_ffprobe(audio_path)
	#generate_waveform_dynamic(audio_path, audio_path + ".png", audio_dur)
	pass



# Image Services

func get_image_texture_from_path(path: String) -> ImageTexture:
	if media_preloaded.has(path):
		return media_preloaded[path]
	var image = Image.new()
	image.load(path)
	var image_texture = ImageTexture.create_from_image(image)
	media_preloaded[path] = image_texture
	return image_texture


# Video Services

func get_video_display_texture_from_path(path: String, thumbnails_folder_path: String) -> ImageTexture:
	var output_path = "%s/%s%s" % [thumbnails_folder_path, path.get_file(), ".jpg"]
	if not FileAccess.file_exists(output_path):
		extract_video_thumbnail(path, output_path)
	return get_image_texture_from_path(output_path)


func extract_video_thumbnail(video_path: String, output_path: String) -> void:
	var ffmpeg_path = ProjectSettings.globalize_path("res://FFmpeg/ffmpeg.exe")
	var abs_video_path = ProjectSettings.globalize_path(video_path)
	var abs_output_path = ProjectSettings.globalize_path(output_path)
	
	var args = [
		"-i", abs_video_path,
		"-ss", "00:00:01.000",
		"-vframes", "1",
		"-s", "320x180",
		"-q:v", "10",
		abs_output_path
	]
	
	var err = OS.execute(ffmpeg_path, args, [], true)
	if err != OK:
		printerr("Failed to start ffmpeg:", err)


func is_stream_has_audio(file_path: String) -> bool:
	var ffmpeg_path = ProjectSettings.globalize_path("res://FFmpeg/ffmpeg.exe")
	var abs_path = ProjectSettings.globalize_path(file_path)
	var args = ["-i", abs_path]
	var output = []
	var code = OS.execute(ffmpeg_path, args, output, true)
	
	for line in output:
		if "Stream #" in line and "Audio" in line:
			return true
	return false


# Audio Services


func get_audio_display_texture_from_path(path: String, thumbnails_folder_path: String, color_key: String = "bfbfbf", fixed_size: bool = true, size:= Vector2i(320, 180)) -> ImageTexture:
	var output_path = "%s/%s%s" % [thumbnails_folder_path, path.get_file(), ".png"]
	if not FileAccess.file_exists(output_path):
		generate_waveform_dynamic(path, output_path, get_audio_duration_with_ffprobe(path), color_key, fixed_size, size)
	return get_image_texture_from_path(output_path)



func get_audio_duration_with_ffprobe(audio_path: String) -> float:
	
	if audio_durations.has(audio_path):
		return audio_durations[audio_path]
	
	var ffprobe_path = ProjectSettings.globalize_path("res://FFmpeg/ffprobe.exe")
	var abs_audio_path = ProjectSettings.globalize_path(audio_path)
	var args = ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", abs_audio_path]
	var output = []
	var err = OS.execute(ffprobe_path, args, output)
	if err == OK:
		var result_dur = output[0].to_float()
		audio_durations[audio_path] = result_dur
		return result_dur
	else:
		printerr("Failed to get duration")
		return 0.0


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
	for i in ARR_MEDIA_EXTENSIONS:
		media_type += 1
		if extension in i:
			return media_type
	return -1
