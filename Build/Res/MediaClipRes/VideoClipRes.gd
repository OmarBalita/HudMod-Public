@icon("res://Asset/Icons/Objects/video.png")
class_name VideoClipRes extends Display2DClipRes

@export var video: String:
	set(val):
		video = val
		
		if not video_decoder:
			video_decoder = VideoDecoder.new()
		
		var can_open: bool = video and MediaCache.videos_info_has(video)
		
		if can_open:
			
			var video_info: Dictionary = MediaCache.get_video_info(video)
			
			video_decoder.set_video_path(video)
			video_decoder.set_internal_enhance(false)
			video_decoder.open()
			video_cache = MediaCache.get_video_cache(video)
			seek_frame_smart(0)
			
			audio_stream = MediaCache.get_audio(video)
			
			fps = video_info.fps
			
			if shader_material:
				_init_video_shader_params()
		else:
			video_decoder.close()
		
		is_opening = can_open
		emit_res_changed()

#@export var scale_factor: float = 1.

var stream_player: AudioStreamPlayer

var is_opening: bool
var video_decoder: VideoDecoder
var video_cache: MediaCache.VideoCache
var audio_stream: AudioStreamWAV
var fps: float

var latest_scale_factor: float

var texture_y: ImageTexture
var texture_u: ImageTexture
var texture_v: ImageTexture

func _set_shader_code(val: String) -> void:
	super(val)
	if curr_node:
		curr_node.texture = get_self_texture()

func get_display_name() -> String: return str("Video:", video.get_file())
func get_thumbnail() -> Texture2D: return MediaServer.get_thumbnail(video).texture

static func get_media_clip_info() -> Dictionary[StringName, String]: return {
	&"title": "Video",
	&"description": ""
}
static func is_media_clip_spawnable() -> bool: return true

func get_min_from() -> float: return .0
func get_max_length() -> float:
	if is_opening: return video_decoder.get_duration() * ProjectServer2.fps
	else: return +INF

func get_self_main_texture() -> Texture2D: return texture_y

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"video": export(string_args(video)),
		#&"scale_factor": export(float_args(scale_factor, .1, 1., .1, .01, .1)),
	} as Dictionary[StringName, ExportInfo].merged(super())

func init_node(root_layer_idx: int, layer_idx: int, frame: int) -> Node:
	var video_viewer: VideoViewer = VideoViewer.new()
	stream_player = AudioStreamPlayer.new()
	stream_player.stream = audio_stream
	video_viewer.add_child(stream_player)
	return _init_node2d(root_layer_idx, layer_idx, frame, video_viewer)

func enter(node: Node) -> void:
	super(node)
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
	Scene2.remove_video_player(self)

func seek_frame_smart(at: int) -> void:
	
	if video_cache.has_frame(at):
		var yuv: Array[Texture2D] = video_cache.get_frame(at)
		texture_y = yuv[0]
		texture_u = yuv[1]
		texture_v = yuv[2]
	
	else:
		if not video_decoder.seek_frame_smart(at): return
		_update_video_frame()
		video_cache.push_frame(at, [texture_y, texture_u, texture_v])

func _update_video_frame() -> void:
	
	var scale_factor: float = EditorServer.editor_settings.video_scale_factor
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
	shader_material.set_shader_parameter(&"tex_y", texture_y)
	shader_material.set_shader_parameter(&"tex_u", texture_u)
	shader_material.set_shader_parameter(&"tex_v", texture_v)

func _init_video_shader_params() -> void:
	shader_material.set_shader_parameter(&"color_matrix", video_decoder.get_color_matrix_idx())
	shader_material.set_shader_parameter(&"is_full_range", video_decoder.get_color_range() == 2)

static func get_compatible_format(bit_depth: int) -> Image.Format:
	return Image.FORMAT_R16 if bit_depth > 8 else Image.FORMAT_R8

static func convert_buffer_to_image(res: Vector2i, format: Image.Format, data: PackedByteArray) -> Image:
	return Image.create_from_data(res.x, res.y, false, format, data)

func _set_shader_material(val: ShaderMaterial) -> void:
	super(val)
	if is_opening:
		_init_video_shader_params()

func _get_shader_global_param_snip() -> String:
	return "
uniform sampler2D tex_y;
uniform sampler2D tex_u;
uniform sampler2D tex_v;
uniform int color_space;
uniform bool is_full_range;
"

func _get_shader_fragment_snip() -> String:
	return "
	// قراءة البيانات بدقة عالية (إذا كانت التكستشر 16-bit ستكون القيمة دقيقة جداً)
	float {y} = texture(tex_y, UV).r;
	float {u} = texture(tex_u, UV).r - .5;
	float {v} = texture(tex_v, UV).r - .5;
	
	// 1. تصحيح المدى (Range Correction)
	if (!is_full_range) {
		{y} = ({y} - (16. / 255.)) * (255. / (235. - 16.));
		{u} = ({u} * (255. / 224.));
		{v} = ({v} * (255. / 224.));
	}
	
	// 2. اختيار مصفوفة التحويل (Color Space Matrix)
	vec3 {rgb};
	if (color_space == 0) { // BT.709 (HD)
		{rgb}.r = {y} + 1.5748 * {v};
		{rgb}.g = {y} - .1873 * {u} - .4681 * {v};
		{rgb}.b = {y} + 1.8556 * {u};
	} else if (color_space == 1) { // BT.2020 (HDR)
		{rgb}.r = {y} + 1.4746 * {v};
		{rgb}.g = {y} - .1645 * {u} - .5713 * {v};
		{rgb}.b = {y} + 1.8814 * {u};
	} else { // BT.601 (SD)
		{rgb}.r = {y} + 1.402 * {v};
		{rgb}.g = {y} - .344 * {u} - .714 * {v};
		{rgb}.b = {y} + 1.772 * {u};
	}
	
	// 3. إذا كانت الشاشة HDR، يمكننا عرض ألوان تتجاوز الـ 1.0 هنا
	color.rgb = {rgb};
"

