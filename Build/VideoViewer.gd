class_name VideoViewer extends Sprite2D


signal video_updated()


@export_global_file() var path: String

var updated: bool
var is_playing: bool
var curr_frame: int

var video: Video
var shader_material:= ShaderMaterial.new()

var audio_player:= AudioStreamPlayer.new()
var stream:= AudioStreamWAV.new()

var padding: int = 0
var video_rotation: int = 0
var frame_rate: float = 0.
var frame_count: int = 0
var resolution: Vector2i = Vector2i.ZERO
var uv_resolution: Vector2i = Vector2i.ZERO

var y_texture: ImageTexture
var u_texture: ImageTexture
var v_texture: ImageTexture

var video_preload_path: String
var audio_preload_path: String





func _ready() -> void:
	start()







func start() -> void:
	
	material = shader_material
	texture = ImageTexture.new()
	add_child(audio_player)
	
	video_preload_path = "%s%s%s" % [path, "_video_", get_meta("layer")]
	audio_preload_path = "%s%s" % [path, "_audio"]
	
	stream.mix_rate = 44100
	stream.stereo = true
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_player.stream = stream
	audio_player.bus = ProjectServer.get_bus_name_from_layer_index(get_meta("layer"))
	
	_open_video()
	_open_audio()
	
	_update_video(video)







func play(timeline_frame: int = 0) -> void:
	is_playing = true
	seek_frame(timeline_frame)
	step_frame()
	audio_player.set_stream_paused(false)
	audio_player.play(TimeServer.frame_to_seconds(TimeServer.localize_frame(timeline_frame + get_meta("clip_res").from, get_meta("clip_pos"))))
	audio_player.set_stream_paused(!is_playing)

func stop() -> void:
	is_playing = false
	audio_player.stop()

func step_frame() -> void:
	var timeline_frame = EditorServer.time_line.curr_frame
	var absolute_frame = get_absolute_frame(timeline_frame)
	if curr_frame < absolute_frame:
		var update_image = timeline_frame % 2 == 0
		video.next_frame(not update_image)
		if update_image:
			_set_frame_image()
		curr_frame += 1
	await EditorServer.time_line.curr_frame_changed_automatically
	if is_playing:
		step_frame()

func seek_frame(timeline_frame: int) -> void:
	var absolute_frame = get_absolute_frame(timeline_frame)
	if not is_open() or absolute_frame == curr_frame:
		return
	
	curr_frame = absolute_frame
	#curr_frame = clamp(absolute_frame, 0, frame_count)
	if video.seek_frame(curr_frame):
		printerr("Couldn't seek frame!")
	else:
		_set_frame_image()


func is_open() -> bool:
	return video != null and video.is_open()

func is_updated() -> bool:
	return updated


func get_absolute_frame(curr_frame: int) -> int:
	curr_frame = TimeServer.localize_frame(curr_frame + get_meta("clip_res").from, get_meta("clip_pos"))
	return TimeServer.map_frames_between_fps(curr_frame, 0, frame_rate)








func _open_video() -> void:
	
	if MediaServer.media_preloaded.has(video_preload_path):
		video = MediaServer.media_preloaded[video_preload_path]
	else:
		video = Video.new()
		video.open(path)
		#video.set_hw_decoding(hardware_decoding if OS.get_name() != "Windows" else false)
		MediaServer.media_preloaded[video_preload_path] = video

func _open_audio() -> void:
	
	if not MediaServer.media_preloaded.has(audio_preload_path):
		MediaServer.media_preloaded[audio_preload_path] = Audio.get_audio_data(path)
	stream.data = MediaServer.media_preloaded[audio_preload_path]



func _update_video(new_video: Video) -> void:
	video = new_video
	if !is_open():
		printerr("Video isn't open!")
		return
	
	var image: Image
	
	padding = video.get_padding()
	video_rotation = video.get_rotation()
	frame_rate = video.get_framerate()
	frame_count = video.get_frame_count()
	resolution = video.get_resolution()
	uv_resolution = Vector2i(int((resolution.x + padding) / 2.), int(resolution.y / 2.))
	image = Image.create_empty(resolution.x, resolution.y, false, Image.FORMAT_R8)
	
	texture.set_image(image)
	
	if video.get_pixel_format().begins_with("yuv"):
		if video.is_full_color_range(): shader_material.shader = preload("res://addons/gde_gozen/shaders/yuv420p_full.gdshader")
		else: shader_material.shader = preload("res://addons/gde_gozen/shaders/yuv420p_standard.gdshader")
	else:
		if video.is_full_color_range(): shader_material.shader = preload("res://addons/gde_gozen/shaders/nv12_full.gdshader")
		else: shader_material.shader = preload("res://addons/gde_gozen/shaders/nv12_standard.gdshader")
	
	match video.get_color_profile():
		"bt601", "bt470": shader_material.set_shader_parameter("color_profile", Vector4(1.402, 0.344136, 0.714136, 1.772))
		"bt2020", "bt2100": shader_material.set_shader_parameter("color_profile", Vector4(1.4746, 0.16455, 0.57135, 1.8814))
		_: # bt709 and unknown
			shader_material.set_shader_parameter("color_profile", Vector4(1.5748, 0.1873, 0.4681, 1.8556))
	
	shader_material.set_shader_parameter("resolution", resolution)
	
	if not y_texture:
		y_texture = ImageTexture.create_from_image(video.get_y_data())
		u_texture = ImageTexture.create_from_image(video.get_u_data())
		if video.get_pixel_format().begins_with("yuv"):
			v_texture = ImageTexture.create_from_image(video.get_v_data())
	
	shader_material.set_shader_parameter("y_data", y_texture)
	if video.get_pixel_format().begins_with("yuv"):
		shader_material.set_shader_parameter("u_data", u_texture)
		shader_material.set_shader_parameter("v_data", v_texture)
	else:
		shader_material.set_shader_parameter("uv_data", u_texture)
	
	updated = true
	video_updated.emit()



func _set_frame_image() -> void:
	
	if y_texture == null: return
	
	y_texture.update(video.get_y_data())
	u_texture.update(video.get_u_data())
	
	if video.get_pixel_format().begins_with("yuv"):
		v_texture.update(video.get_v_data())





















