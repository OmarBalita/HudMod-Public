class_name VideoRenderProfile extends UsableRes

signal renderer_created_successfully(output_path: String, video_renderer: VideoRenderer, audio_renderer: AudioRenderer)
signal renderer_creation_failed(error: String)

static var video_formats_info: Dictionary[VideoFormat, VideoFormatInfo] = {
	VideoFormat.MP4: VideoFormatInfo.new(&"mp4", &"mp4", [VideoCodec.H_264, VideoCodec.H_265, VideoCodec.VP9, VideoCodec.AV1, VideoCodec.MPEG4], ["yuva420p", "yuva422p", "yuva444p", "yuva420p10le", "yuva422p10le", "yuva444p10le", "yuva420p12le", "yuva422p12le", "yuva444p12le"]),
	VideoFormat.MKV: VideoFormatInfo.new(&"mkv", &"matroska", [VideoCodec.H_264, VideoCodec.H_265, VideoCodec.VP9, VideoCodec.AV1, VideoCodec.ProRes, VideoCodec.FFV1], []),
	VideoFormat.AVI: VideoFormatInfo.new(&"avi", &"avi", [VideoCodec.H_264, VideoCodec.MPEG4], []),
	VideoFormat.WEBM: VideoFormatInfo.new(&"webm", &"webm", [VideoCodec.AV1, VideoCodec.VP8, VideoCodec.VP9], []),
}

static var video_codecs_info: Dictionary[VideoCodec, VideoCodecInfo] = {
	VideoCodec.H_264: VideoCodecInfo.new(&"H_264", &"libx264", ["yuv420p", "yuv422p", "yuv444p", "yuv420p10le", "yuv422p10le", "yuv444p10le"]),
	VideoCodec.H_265: VideoCodecInfo.new(&"H_265", &"libx265", ["yuv420p", "yuv422p", "yuv444p", "yuv420p10le", "yuv422p10le", "yuv444p10le", "yuv420p12le", "yuv422p12le", "yuv444p12le"]),
	VideoCodec.VP8: VideoCodecInfo.new(&"VP8", &"libvpx", ["yuv420p"]), # "yuva420p"
	VideoCodec.VP9: VideoCodecInfo.new(&"VP9", &"libvpx-vp9", ["yuv420p", "yuv422p", "yuv444p", "yuv420p10le", "yuv422p10le", "yuv444p10le", "yuv420p12le", "yuv422p12le", "yuv444p12le"]), # "yuva420p", "yuva422p", "yuva444p", "yuva420p10le", "yuva422p10le", "yuva444p10le", "yuva420p12le", "yuva422p12le", "yuva444p12le"
	VideoCodec.AV1: VideoCodecInfo.new(&"AV1", &"libsvtav1", ["yuv420p", "yuv420p10le"]),
	VideoCodec.MPEG4: VideoCodecInfo.new(&"MPEG4", &"mpeg4", ["yuv420p"]),
	VideoCodec.ProRes: VideoCodecInfo.new(&"ProRes", &"prores", ["yuv422p10le", "yuv444p10le"]), # "yuva444p10le"
	VideoCodec.FFV1: VideoCodecInfo.new(&"FFV1", &"ffv1", ["yuv420p", "yuv422p", "yuv444p", "yuv420p10le", "yuv422p10le", "yuv444p10le", "yuv420p12le", "yuv422p12le", "yuv444p12le"])
}

static var audio_codecs_info: Dictionary[AudioCodec, AudioCodecInfo] = {
	AudioCodec.AAC: AudioCodecInfo.new(&"AAC", &"aac"),
	#AudioCodec.MP3: AudioCodecInfo.new(&"MP3", &"libmp3lame"),
	AudioCodec.OPUS: AudioCodecInfo.new(&"OPUS", &"libopus"),
}

enum VideoFormat {
	MP4,
	MKV,
	AVI,
	WEBM
}

enum VideoCodec {
	H_264,
	H_265,
	VP8,
	VP9,
	AV1,
	MPEG4,
	ProRes,
	FFV1
}

enum BitRateControlMode {
	CRF,
	VBR,
	CBR
}

enum ColorSpaceMode {
	BT709,
	BT2020
}

enum EncodingSpeed {
	VERY_FAST,
	FAST,
	MEDIUM,
	SLOW,
	SLOWER,
	VERY_SLOW
}


enum AudioCodec {
	AAC,
	#MP3,
	OPUS
}

@export var file_path: String
@export var file_name: String

@export var video_format: VideoFormat = VideoFormat.MP4
@export var video_codec: int
@export var pixel_format: int

@export var bitrate_control_mode: BitRateControlMode
@export_range(1_000_000, 60_000_000) var bitrate: int = 6_000_000
@export_range(0, 51) var crf_value: int = 18

@export var limited_color_range: bool = false
@export var color_space: ColorSpaceMode = ColorSpaceMode.BT709
@export var encoding_speed: EncodingSpeed = EncodingSpeed.MEDIUM

@export var audio_codec: AudioCodec = AudioCodec.AAC

var codecs_ignored_options: Array[int]
var pixel_formats_options: Dictionary


func _init() -> void:
	_update_options()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	
	var get_ctrl_mode: Callable = get.bind(&"bitrate_control_mode")
	
	return {
		&"file_path": export(string_args(file_path, IS.StringControllerType.TYPE_OPEN_DIR, [])),
		&"file_name": export(string_args(file_name, 0, [], "~ video_file.mp4")),
		
		&"Video": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		
		&"Format": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"video_format": export(options_args(video_format, VideoFormat)),
		&"video_codec": export(options_args(video_codec, VideoCodec)),
		&"pixel_format": export(options_args(pixel_format, pixel_formats_options)),
		&"_Format": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Bit Rate": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"bitrate_control_mode": export(options_args(bitrate_control_mode, BitRateControlMode)),
		&"bitrate": export(int_args(bitrate, 1_000_000, 60_000_000), [get_ctrl_mode, [1, 2]]),
		&"crf_value": export(int_args(crf_value, 0, 51), [get_ctrl_mode, [0]]),
		&"_Bit Rate": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		#&"limited_color_range": export(bool_args(limited_color_range)),
		&"color_space": export(options_args(color_space, ColorSpaceMode)),
		&"encoding_speed": export(options_args(encoding_speed, EncodingSpeed)),
		
		&"_Video": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Audio": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"audio_codec": export(options_args(audio_codec, AudioCodec)),
		&"_Audio": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	}

func _exported_props_controllers_created(main_edit: EditBoxContainer, props_controllers: Dictionary[StringName, Control]) -> void:
	super(main_edit, props_controllers)
	await Engine.get_main_loop().process_frame
	_update_options()
	_try_to_update_ui()

func emit_res_changed() -> void:
	super()
	_update_options()
	_try_to_update_ui()


func _update_options() -> void:
	var valid_codecs_options: Dictionary = find_available_codecs_for_video_format(video_format)
	
	var video_codec_keys: Array = VideoCodec.keys()
	
	codecs_ignored_options.clear()
	
	for idx: int in VideoCodec.size():
		var abs_name: String = video_codec_keys[idx]
		if not valid_codecs_options.has(abs_name):
			codecs_ignored_options.append(idx)
	
	if codecs_ignored_options.has(video_codec):
		video_codec = valid_codecs_options.values()[0]
	
	var valid_pixel_formats_options: Dictionary = find_available_pixel_formats_for_video_codec(video_codec, video_format)
	
	var pixel_format_name: StringName = pixel_formats_options.keys()[pixel_format] if pixel_formats_options else &""
	
	if valid_pixel_formats_options.has(pixel_format_name):
		var valid_pixel_formats_keys: Array = valid_pixel_formats_options.keys()
		pixel_format = valid_pixel_formats_keys.find(pixel_format_name)
	else:
		pixel_format = 0
	
	pixel_formats_options = valid_pixel_formats_options


func _try_to_update_ui() -> void:
	
	if not EditorServer.has_usable_res_controllers(self):
		return
	
	var codec_ctrlr: OptionController = EditorServer.get_usable_res_property_controller(self, &"video_codec").get_child(1)
	var pxl_format_ctrlr: OptionController = EditorServer.get_usable_res_property_controller(self, &"pixel_format").get_child(1)
	
	if not codec_ctrlr:
		return
	
	for idx: int in codec_ctrlr.options.size():
		var option: MenuOption = codec_ctrlr.options[idx]
		option.hidden = codecs_ignored_options.has(idx)
	
	pxl_format_ctrlr.options.clear()
	for option_name: String in pixel_formats_options:
		pxl_format_ctrlr.options.append(MenuOption.new(option_name))
	
	codec_ctrlr.selected_id = video_codec
	pxl_format_ctrlr.selected_id = pixel_format


static func find_available_codecs_for_video_format(video_format: VideoFormat) -> Dictionary:
	var result: Dictionary
	
	var codecs: Array[VideoCodec] = video_formats_info[video_format].supported_codecs
	for idx: int in codecs.size():
		var codec: VideoCodec = codecs[idx]
		var codec_name: StringName = video_codecs_info[codec].codec_name
		result[codec_name] = codec
	
	return result

static func find_available_pixel_formats_for_video_codec(video_codec: VideoCodec, video_format: VideoFormat = -1) -> Dictionary:
	var result: Dictionary
	
	var pixel_formats: PackedStringArray = video_codecs_info[video_codec].supported_pixel_formats
	var pixel_formats_exclusions: PackedStringArray = video_formats_info[video_format].pixel_format_exclusions if video_format > -1 else []
	var idx: int
	for pixel_format: String in pixel_formats:
		if pixel_formats_exclusions.has(pixel_format):
			continue
		result[pixel_format] = idx
		idx += 1
	
	return result


func create_renderer_from_profile() -> void:
	
	if file_path.is_empty() or file_name.is_empty():
		renderer_creation_failed.emit("Please fill in both 'File Path' and 'File Name'")
		return
	
	if not DirAccess.dir_exists_absolute(file_path):
		renderer_creation_failed.emit("Invalid folder path.")
		return
	
	if not file_name.is_valid_filename():
		renderer_creation_failed.emit("Invalid file name.")
		return
	
	var format_info: VideoFormatInfo = video_formats_info[video_format]
	
	var abs_file_name: String = file_name
	if not abs_file_name.ends_with(format_info.extension_name):
		abs_file_name += "." + String(format_info.extension_name)
	
	var full_path: String = file_path + "/" + abs_file_name
	full_path = full_path.simplify_path()
	
	var video_renderer:= VideoRenderer.new()
	video_renderer.set_container_name(format_info.internal_name)
	video_renderer.set_encoder_name(video_codecs_info[video_codec].encoder_internal_name)
	video_renderer.set_pixel_format(pixel_formats_options.find_key(pixel_format))
	video_renderer.set_bit_rate_control_mode(bitrate_control_mode)
	video_renderer.set_bit_rate(bitrate)
	video_renderer.set_crf_value(crf_value)
	video_renderer.set_is_color_range_limited(limited_color_range)
	video_renderer.set_color_space_idx(color_space)
	video_renderer.set_quality_level(encoding_speed)
	
	var audio_renderer:= AudioRenderer.new()
	audio_renderer.set_encoder_name(audio_codecs_info[audio_codec].encoder_internal_name)
	
	renderer_created_successfully.emit(full_path, video_renderer, audio_renderer)


class VideoFormatInfo extends Object:
	
	@export var extension_name: StringName
	@export var internal_name: StringName
	@export var supported_codecs: Array[VideoCodec]
	@export var pixel_format_exclusions: PackedStringArray
	
	func _init(_extension_name: StringName, _internal_name: StringName, _supported_codecs: Array[VideoCodec], _pixel_format_exclusions: PackedStringArray = []) -> void:
		extension_name = _extension_name
		internal_name = _internal_name
		supported_codecs = _supported_codecs
		pixel_format_exclusions = _pixel_format_exclusions

class VideoCodecInfo extends Object:
	
	@export var codec_name: StringName
	@export var encoder_internal_name: StringName
	@export var supported_pixel_formats: PackedStringArray
	
	func _init(_codec_name: StringName, _encoder_internal_name: StringName, _supported_pixel_formats: PackedStringArray) -> void:
		codec_name = _codec_name
		encoder_internal_name = _encoder_internal_name
		supported_pixel_formats = _supported_pixel_formats

class AudioCodecInfo extends Object:
	
	@export var codec_name: StringName
	@export var encoder_internal_name: StringName
	
	func _init(_codec_name: StringName, _encoder_internal_name: StringName) -> void:
		codec_name = _codec_name
		encoder_internal_name = _encoder_internal_name




