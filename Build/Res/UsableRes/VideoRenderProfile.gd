#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
##	This program is free software: you can redistribute it and/or modify   ##
##	it under the terms of the GNU General Public License as published by   ##
##	the Free Software Foundation, either version 3 of the License, or	   ##
##	(at your option) any later version.									   ##
##																		   ##
##	This program is distributed in the hope that it will be useful,		   ##
##	but WITHOUT ANY WARRANTY; without even the implied warranty of		   ##
##	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the		   ##
##	GNU General Public License for more details.						   ##
##																		   ##
##	You should have received a copy of the GNU General Public License	   ##
##	along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
class_name VideoRenderProfile extends UsableRes

signal renderer_created_successfully(output_path: String, video_renderer: VideoRenderer, audio_renderer: AudioRenderer)
signal renderer_creation_failed(error: String)
signal preset_applied(preset_name: StringName)
signal custom_presets_changed()

static var video_formats_info: Dictionary[VideoFormat, VideoFormatInfo] = {
	VideoFormat.MP4: VideoFormatInfo.new(&"mp4", &"mp4", [VideoCodec.H_264, VideoCodec.H_265, VideoCodec.VP9, VideoCodec.AV1, VideoCodec.MPEG4], ["yuva420p", "yuva422p", "yuva444p", "yuva420p10le", "yuva422p10le", "yuva444p10le", "yuva420p12le", "yuva422p12le", "yuva444p12le"]),
	VideoFormat.MKV: VideoFormatInfo.new(&"mkv", &"matroska", [VideoCodec.H_264, VideoCodec.H_265, VideoCodec.VP9, VideoCodec.AV1, VideoCodec.ProRes, VideoCodec.FFV1], []),
	VideoFormat.AVI: VideoFormatInfo.new(&"avi", &"avi", [VideoCodec.H_264, VideoCodec.MPEG4], []),
	VideoFormat.WEBM: VideoFormatInfo.new(&"webm", &"webm", [VideoCodec.AV1, VideoCodec.VP8, VideoCodec.VP9], [])
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

const PRESET_OPTIONS: Dictionary[StringName, Dictionary] = {
	# --- Video Platforms ---
	&"YouTube 1080p": {&"resolution": Vector2(1920, 1080), &"bitrate": 12_000_000, &"encoding_speed": EncodingSpeed.SLOW},
	&"YouTube 1440p (2K)": {&"resolution": Vector2(2560, 1440), &"bitrate": 24_000_000, &"encoding_speed": EncodingSpeed.SLOW},
	&"YouTube 4K": {&"resolution": Vector2(3840, 2160), &"bitrate": 45_000_000, &"encoding_speed": EncodingSpeed.SLOW},
	&"Vimeo 1080p": {&"resolution": Vector2(1920, 1080), &"bitrate": 20_000_000, &"encoding_speed": EncodingSpeed.SLOW},
	# --- Social Platforms ---
	&"TikTok (1080x1920)": {&"resolution": Vector2(1080, 1920), &"bitrate": 8_000_000},
	&"Instagram Reels / Stories": {&"resolution": Vector2(1080, 1920), &"bitrate": 8_000_000},
	&"Instagram Feed (4:5)": {&"resolution": Vector2(1080, 1350), &"bitrate": 8_000_000},
	&"Facebook 1080p": {&"resolution": Vector2(1920, 1080), &"bitrate": 8_000_000},
	&"X (Twitter) 1080p": {&"resolution": Vector2(1920, 1080), &"bitrate": 10_000_000},
	# --- Messaging / Small size ---
	&"WhatsApp / Telegram (Small)": {
		&"resolution": Vector2(1280, 720),
		&"bitrate_control_mode": BitRateControlMode.CRF,
		&"crf_value": 26,
		&"encoding_speed": EncodingSpeed.FAST
	},
	# --- Web ---
	&"WebM VP9 1080p": {
		&"resolution": Vector2(1920, 1080),
		&"video_format": VideoFormat.WEBM,
		&"video_codec": VideoCodec.VP9,
		&"audio_codec": AudioCodec.OPUS,
		&"bitrate": 8_000_000
	},
	# --- Master / Archive ---
	&"H.265 4K High Quality": {
		&"resolution": Vector2(3840, 2160),
		&"video_codec": VideoCodec.H_265,
		&"pixel_format": "yuv420p10le",
		&"bitrate_control_mode": BitRateControlMode.CRF,
		&"crf_value": 20,
		&"encoding_speed": EncodingSpeed.SLOW
	},
	&"Master ProRes (MKV)": {
		&"video_format": VideoFormat.MKV,
		&"video_codec": VideoCodec.ProRes,
		&"pixel_format": "yuv422p10le",
		&"bitrate_control_mode": BitRateControlMode.CRF
	},
	&"Archive Lossless FFV1 (MKV)": {
		&"video_format": VideoFormat.MKV,
		&"video_codec": VideoCodec.FFV1,
		&"pixel_format": "yuv420p",
		&"bitrate_control_mode": BitRateControlMode.CRF
	}
}

# Applied before any preset so container related props never leak from the previous preset.
const PRESET_BASE: Dictionary = {
	&"video_format": VideoFormat.MP4,
	&"video_codec": VideoCodec.H_264,
	&"pixel_format": "yuv420p",
	&"audio_codec": AudioCodec.AAC
}

const PRESET_PROPS: Array[StringName] = [
	&"resolution",
	&"video_format",
	&"video_codec",
	&"pixel_format",
	&"bitrate_control_mode",
	&"bitrate",
	&"crf_value",
	&"color_space",
	&"encoding_speed",
	&"audio_codec"
]

const NO_PRESET_TEXT: String = "No Preset"

static var custom_presets: Dictionary[StringName, Dictionary]
static var is_custom_presets_loaded: bool

@export var file_path: String
@export var file_name: String

@export var resolution: Vector2 = Vector2.ONE

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

var curr_preset: StringName
var preset_options_ctrlr: OptionController


func _init() -> void:
	_update_options()
	preset_applied.connect(_update_preset_options_ctrlr.unbind(1))
	custom_presets_changed.connect(_update_preset_options_ctrlr)

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	
	var get_ctrl_mode: Callable = get.bind(&"bitrate_control_mode")
	
	return {
		&"file_path": export(string_args(file_path, IS.StringControllerType.TYPE_OPEN_DIR, [])),
		&"file_name": export(string_args(file_name, 0, [], "~ video_file.mp4")),
		
		&"Video": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		
		&"resolution": export(vec2_args(resolution, true, true, FloatController.SuffixType.TYPE_PIXEL, Vector2(48, 7680), Vector2(48, 4320))),
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

func _custom_editor_spawned(edit_cont: EditContainer, props_editors: Dictionary[StringName, Control]) -> void:
	# Called again whenever the edit re-enters the tree (e.g. layout switching), so don't add a second menu.
	if is_instance_valid(preset_options_ctrlr) and preset_options_ctrlr.get_parent() == edit_cont.header_cont:
		return
	preset_options_ctrlr = IS.create_options_controller_2(0, {NO_PRESET_TEXT: 0})
	preset_options_ctrlr.selected_option_changed.connect(
		func(id: int, option: MenuOption) -> void:
			if id == 0:
				curr_preset = &""
				preset_applied.emit(curr_preset)
			else:
				apply_preset(StringName(option.text))
	)
	edit_cont.header_cont.add_child(preset_options_ctrlr)
	_update_preset_options_ctrlr()

func _update_preset_options_ctrlr() -> void:
	if not is_instance_valid(preset_options_ctrlr): return
	
	var options: Array = [MenuOption.new(NO_PRESET_TEXT), MenuOption.new_line()]
	for preset_name: StringName in PRESET_OPTIONS:
		options.append(MenuOption.new(preset_name))
	
	var presets: Dictionary[StringName, Dictionary] = get_custom_presets()
	if presets:
		options.append(MenuOption.new_line())
		for preset_name: StringName in presets:
			options.append(MenuOption.new(preset_name))
	
	var selected_idx: int = options.find_custom(
		func(option: MenuOption) -> bool:
			return not option.is_separation_line and option.text == curr_preset
	)
	
	preset_options_ctrlr.options = options
	preset_options_ctrlr.set_selected_id_manually(max(selected_idx, 0))


static func get_custom_presets_path() -> String:
	return EditorServer.editor_path + "render_presets.bin"

static func get_custom_presets() -> Dictionary[StringName, Dictionary]:
	if not is_custom_presets_loaded:
		is_custom_presets_loaded = true
		var file: FileAccess = FileAccess.open(get_custom_presets_path(), FileAccess.READ)
		if file:
			var data: Variant = file.get_var()
			if data is Dictionary:
				for preset_name: Variant in data:
					custom_presets[StringName(preset_name)] = data[preset_name]
	return custom_presets

static func save_custom_presets() -> void:
	DirAccess.make_dir_recursive_absolute(EditorServer.editor_path)
	var file: FileAccess = FileAccess.open(get_custom_presets_path(), FileAccess.WRITE)
	if file: file.store_var(Dictionary(custom_presets))

static func get_preset_info(preset_name: StringName) -> Dictionary:
	if PRESET_OPTIONS.has(preset_name):
		return PRESET_BASE.merged(PRESET_OPTIONS[preset_name], true)
	return get_custom_presets().get(preset_name, {})

static func is_custom_preset(preset_name: StringName) -> bool:
	return get_custom_presets().has(preset_name)

func is_curr_preset_custom() -> bool:
	return is_custom_preset(curr_preset)

func apply_preset(preset_name: StringName) -> void:
	var preset_info: Dictionary = get_preset_info(preset_name)
	if preset_info.is_empty(): return
	
	for prop_key: StringName in PRESET_PROPS:
		if prop_key == &"pixel_format" or not preset_info.has(prop_key):
			continue
		set(prop_key, preset_info[prop_key])
	
	_update_options()
	
	if preset_info.has(&"pixel_format"):
		pixel_format = pixel_formats_options.get(preset_info[&"pixel_format"], 0)
	
	curr_preset = preset_name
	emit_res_changed()
	_try_to_update_props_edits()
	preset_applied.emit(preset_name)

# Returns false if the name is reserved by a built-in preset.
func save_as_custom_preset(preset_name: StringName) -> bool:
	if PRESET_OPTIONS.has(preset_name) or preset_name == NO_PRESET_TEXT:
		return false
	
	var preset_info: Dictionary
	for prop_key: StringName in PRESET_PROPS:
		preset_info[prop_key] = get(prop_key)
	preset_info[&"pixel_format"] = pixel_formats_options.find_key(pixel_format)
	
	get_custom_presets()[preset_name] = preset_info
	save_custom_presets()
	
	curr_preset = preset_name
	custom_presets_changed.emit()
	preset_applied.emit(curr_preset)
	return true

func delete_custom_preset(preset_name: StringName) -> void:
	if not get_custom_presets().erase(preset_name): return
	save_custom_presets()
	
	if curr_preset == preset_name:
		curr_preset = &""
	custom_presets_changed.emit()
	preset_applied.emit(curr_preset)

func _try_to_update_props_edits() -> void:
	if not EditorServer.usable_ress_editors_has_editor_with_idx(self, 0): return
	
	var props_edits: Dictionary[StringName, Control] = EditorServer.usable_ress_editors_get_props_edits_conts(self, 0)
	for prop_key: StringName in PRESET_PROPS:
		# Codec and pixel format are already handled by _try_to_update_ui().
		if prop_key in [&"video_codec", &"pixel_format"] or not props_edits.has(prop_key):
			continue
		var prop_edit: EditContainer = props_edits[prop_key]
		var prop_val: Variant = get(prop_key)
		prop_edit.set_curr_value_manually(prop_val)
		prop_edit.set_controller_curr_value_manually(prop_val)
	
	EditorServer.usable_ress_editors_get_ui_profile(self, 0).update()


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
	if not EditorServer.usable_ress_editors_has_editor_with_idx(self, 0): return
	
	var codec_ctrlr: OptionController = EditorServer.usable_ress_editors_get_prop_edit_cont(self, 0, &"video_codec").get_child(1)
	var pxl_format_ctrlr: OptionController = EditorServer.usable_ress_editors_get_prop_edit_cont(self, 0, &"pixel_format").get_child(1)
	
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
		renderer_creation_failed.emit("Please fill in both 'File Path' and 'File Name'.")
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
	video_renderer.set_width(resolution.x)
	video_renderer.set_height(resolution.y)
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
