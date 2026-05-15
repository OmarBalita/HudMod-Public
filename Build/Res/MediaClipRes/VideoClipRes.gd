#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
@icon("res://Asset/Icons/Objects/video.png")
class_name VideoClipRes extends Display2DClipRes

@export var video: String:
	set(val):
		
		var can_open: bool = val and MediaCache.video_contexts_has(val)
		
		#if video == val and can_open == is_opening:
			#return
		
		video = val
		
		if can_open:
			
			video_ctx = MediaCache.get_video_context(video)
			audio_data_res = MediaCache.get_audio_data(video)
			fps = video_ctx.fps
		else:
			video_ctx = null
			audio_data_res = MediaCache.default_audio_f32_data
		
		is_opening = can_open
		emit_res_changed()

#@export var scale_factor: float = 1.

var stream_player: CustomAudioStreamPlayer

var is_opening: bool
var video_ctx: MediaCache.VideoContext
var video_decoder: VideoDecoder
var audio_data_res: MediaCache.AudioF32Data = MediaCache.default_audio_f32_data
var fps: float

var latest_scale_factor: float

var texture_y: ImageTexture
var texture_u: ImageTexture
var texture_v: ImageTexture

func get_display_name() -> String: return str("Video:", video.get_file())
func get_thumbnail() -> Texture2D: return MediaServer.get_thumbnail(video).texture
static func get_icon() -> Texture2D: return preload("res://Asset/Icons/Objects/video.png")

static func get_media_clip_info() -> Dictionary[StringName, String]: return {
	&"title": "Video",
	&"description": ""
}
static func is_media_clip_spawnable() -> bool: return true

func get_min_from() -> float: return .0
func get_max_length() -> float:
	if is_opening: return video_ctx.duration * ProjectServer2.fps
	else: return +INF

func get_self_main_texture() -> Texture2D: return texture_y

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"video": export(string_args(video)),
		#&"scale_factor": export(float_args(scale_factor, .1, 1., .1, .01, .1)),
	} as Dictionary[StringName, ExportInfo].merged(super())

func init_node(root_layer_idx: int, layer_idx: int, layer_res: LayerRes, frame: int) -> Node:
	
	var video_viewer: VideoViewer = VideoViewer.new()
	stream_player = CustomAudioStreamPlayer.new()
	if audio_data_res:
		stream_player.set_data(audio_data_res.get_data())
	stream_player.bus = PlaybackServer.root_layer_get_bus_unique_name(root_layer_idx)
	video_viewer.add_child(stream_player)
	
	return _init_node2d(root_layer_idx, layer_idx, layer_res, frame, video_viewer)

func enter(node: Node) -> void:
	super(node)
	video_decoder = video_ctx.request_video_decoder()
	_init_video_shader_params()
	seek_frame_smart(0)
	node.texture = get_self_texture()
	Scene2.add_video_player(self)

func _process_comps(frame: int) -> void:
	
	if is_opening:
		var new_video_frame: int = (frame + from) / float(ProjectServer2.fps) * fps
		
		if new_video_frame != video_decoder.get_curr_frame():
			seek_frame_smart(new_video_frame)
		
		_update_video_shader_params()
	
	super(frame)

func exit(node: Node) -> void:
	super(node)
	
	video_decoder.set_channel_y([])
	video_decoder.set_channel_u([])
	video_decoder.set_channel_v([])
	texture_y = null
	texture_u = null
	texture_v = null
	
	video_ctx.push_video_decoder_front(video_decoder)
	video_decoder = null
	
	_update_video_shader_params()
	Scene2.remove_video_player(self)

func seek_frame_smart(at: int) -> void:
	
	if video_ctx.has_frame(at):
		var yuv: Array[Texture2D] = video_ctx.get_frame(at)
		texture_y = yuv[0]
		texture_u = yuv[1]
		texture_v = yuv[2]
	
	else:
		if not video_decoder.seek_frame_smart(at):
			return
		_update_video_frame()
		video_ctx.push_frame(at, [texture_y, texture_u, texture_v])

func _update_video_frame() -> void:
	
	var scale_factor: float = EditorServer.editor_settings.performance.video_scale_factor
	video_decoder.update_video_channels(scale_factor)
	
	var dim: Dictionary = video_decoder.get_channels_dim()
	var bit_depth: int = video_decoder.get_bit_depth()
	var format: Image.Format = get_compatible_format(bit_depth)
	
	var y_scaled: Vector2i = dim.y * scale_factor
	var uv_scaled: Vector2i = dim.uv * scale_factor
	
	var image_y: Image = convert_buffer_to_image(y_scaled, format, video_decoder.channel_y)
	var image_u: Image = convert_buffer_to_image(uv_scaled, format, video_decoder.channel_u)
	var image_v: Image = convert_buffer_to_image(uv_scaled, format, video_decoder.channel_v)
	
	texture_y = ImageTexture.create_from_image(image_y)
	texture_u = ImageTexture.create_from_image(image_u)
	texture_v = ImageTexture.create_from_image(image_v)

func _update_video_shader_params() -> void:
	if not pre_shader_material: return
	pre_shader_material.set_shader_parameter(&"tex_y", texture_y)
	pre_shader_material.set_shader_parameter(&"tex_u", texture_u)
	pre_shader_material.set_shader_parameter(&"tex_v", texture_v)

func _init_video_shader_params() -> void:
	var bit_depth: int = video_decoder.get_bit_depth()
	pre_shader_material.set_shader_parameter(&"color_matrix", video_decoder.get_color_matrix_idx())
	pre_shader_material.set_shader_parameter(&"is_full_range", false)
	pre_shader_material.set_shader_parameter(&"bit_depth", bit_depth)
	pre_shader_material.set_shader_parameter(&"bit_max_val", pow(2., 16 if bit_depth > 8 else 8))

static func get_compatible_format(bit_depth: int) -> Image.Format:
	return Image.FORMAT_R16 if bit_depth > 8 else Image.FORMAT_R8

static func convert_buffer_to_image(res: Vector2i, format: Image.Format, data: PackedByteArray) -> Image:
	return Image.create_from_data(res.x, res.y, false, format, data)


func build_shader_pipeline() -> void:
	await super()
	if video_decoder:
		_init_video_shader_params()
	if curr_node:
		curr_node.texture = get_self_texture()
		process_here()

static func _shader_is_post() -> bool: return false

func _get_shader_global_param_snip() -> String:
	return "
uniform sampler2D tex_y;
uniform sampler2D tex_u;
uniform sampler2D tex_v;

uniform float bit_depth; // 8, 10, 12, 16
uniform float bit_max_val;

uniform bool is_full_range;
uniform int color_space; // 0=BT.709, 1=BT.2020, 2=BT.601
"

func _get_shader_fragment_snip() -> String:
	return "
	float {y} = texture(tex_y, UV).r;
	float {u} = texture(tex_u, UV).r;
	float {v} = texture(tex_v, UV).r;
	
	float {bit_scale} = (exp2(bit_depth) - 1.0) / bit_max_val;
	{y} /= {bit_scale};
	{u} /= {bit_scale};
	{v} /= {bit_scale};
	
	float {max_val}   = exp2(bit_depth) - 1.0;
	float {uv_offset} = exp2(bit_depth - 1.0);
	
	if (is_full_range) {
		{u} -= {uv_offset} / {max_val};
		{v} -= {uv_offset} / {max_val};
	} else {
		float {y_min}     = exp2(bit_depth - 4.0);
		float {y_range}   = exp2(bit_depth - 4.0) * 219.0 / 16.0;
		float {uv_range}  = exp2(bit_depth - 4.0) * 224.0 / 16.0;
		{y} = ({y} - {y_min}     / {max_val}) / ({y_range}  / {max_val});
		{u} = ({u} - {uv_offset} / {max_val}) / ({uv_range} / {max_val});
		{v} = ({v} - {uv_offset} / {max_val}) / ({uv_range} / {max_val});
	}
	
	if (color_space == 0) {        // BT.709
		color.r = {y} + 1.5748 * {v};
		color.g = {y} - 0.1873 * {u} - 0.4681 * {v};
		color.b = {y} + 1.8556 * {u};
	} else if (color_space == 1) { // BT.2020
		color.r = {y} + 1.4746 * {v};
		color.g = {y} - 0.1645 * {u} - 0.5713 * {v};
		color.b = {y} + 1.8814 * {u};
	} else {                       // BT.601
		color.r = {y} + 1.402 * {v};
		color.g = {y} - 0.344 * {u} - 0.714 * {v};
		color.b = {y} + 1.772 * {u};
	}
"

func check_for_paths(paths_for_check: PackedStringArray) -> PackedStringArray:
	return [] if paths_for_check.has(video) else [video]

func format_paths(paths_for_format: Dictionary[String, String]) -> void:
	if paths_for_format.has(video): video = paths_for_format[video]

func erase_paths(paths_for_erase: PackedStringArray) -> void:
	if paths_for_erase.has(video): video = ""

func update_paths() -> void:
	video = video



