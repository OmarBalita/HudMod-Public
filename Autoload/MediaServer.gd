extends Node

enum MediaTypes {
	IMAGE,
	VIDEO,
	AUDIO,
	TEXT,
	SHAPE
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




func _ready() -> void:
	#await get_tree().create_timer(1.0).timeout
	#var audio_path = "res://untitled.mp3"
	#var audio_dur = get_audio_duration_with_ffprobe(audio_path)
	#generate_waveform_dynamic(audio_path, audio_path + ".png", audio_dur)
	pass



# Image Services

func get_image_texture_from_path(path: String) -> ImageTexture:
	var image = Image.new()
	image.load(path)
	return ImageTexture.create_from_image(image)


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



# Audio Services


func get_audio_display_texture_from_path(path: String, thumbnails_folder_path: String) -> ImageTexture:
	var output_path = "%s/%s%s" % [thumbnails_folder_path, path.get_file(), ".png"]
	if not FileAccess.file_exists(output_path):
		generate_audio_thumbnail(path, output_path)
	return get_image_texture_from_path(output_path)

func generate_audio_thumbnail(audio_path: String, output_path: String) -> void:
	generate_waveform_dynamic(audio_path, output_path, get_audio_duration_with_ffprobe(audio_path), true, Vector2i(320, 180))


func get_audio_duration_with_ffprobe(audio_path: String) -> float:
	var ffprobe_path = ProjectSettings.globalize_path("res://FFmpeg/ffprobe.exe")
	var abs_audio_path = ProjectSettings.globalize_path(audio_path)
	var args = ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", abs_audio_path]
	var output = []
	var err = OS.execute(ffprobe_path, args, output)
	if err == OK:
		return output[0].to_float()
	else:
		printerr("Failed to get duration")
		return 0.0


func generate_waveform_dynamic(audio_path: String, output_path: String, duration_seconds: float, fixed_size:= false, size:= Vector2i.ONE) -> void:
	var ffmpeg_path = ProjectSettings.globalize_path("res://FFmpeg/ffmpeg.exe")
	var abs_audio_path = ProjectSettings.globalize_path(audio_path)
	var abs_output_path = ProjectSettings.globalize_path(output_path)
	
	var pixels_per_second = 20.0
	var width = int(duration_seconds * pixels_per_second)
	var height = 120
	if fixed_size:
		width = size.x
		height = size.y
	
	var resolution = str(width, "x", height)
	
	var args = [
		"-i", abs_audio_path,
		"-filter_complex", "aformat=channel_layouts=mono,showwavespic=s=" + resolution + ":colors=white",
		"-frames:v", "1",
		abs_output_path
	]
	
	var err = OS.execute(ffmpeg_path, args)
	if err != OK:
		printerr("Failed to generate waveform image:", err)








