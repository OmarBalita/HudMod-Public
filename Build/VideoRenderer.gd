class_name VideoRenderer extends Sprite2D


signal video_updated()


@export_global_file() var path: String
@export var hardware_decoding: bool = false

var updated: bool
var is_playing: bool
var curr_frame: int

var audio_player:= AudioStreamPlayer.new()

var video: Video
var shader_material:= ShaderMaterial.new()

var audio: Video
var stream:= AudioStreamWAV.new()

var _rotation: int = 0
var _padding: int = 0
var _frame_rate: float = 0.
var _frame_count: int = 0

var _resolution: Vector2i = Vector2i.ZERO
var _uv_resolution: Vector2i = Vector2i.ZERO

var threads: PackedInt64Array

var y_texture: ImageTexture
var u_texture: ImageTexture
var v_texture: ImageTexture

var preloaded_media_path: String




func _enter_tree() -> void:
	add_child(audio_player)
	material = shader_material
	texture = ImageTexture.new()

func _ready() -> void:
	start()


func _process(delta: float) -> void:
	if !threads.is_empty():
		
		for i: int in threads:
			if WorkerThreadPool.is_task_completed(i):
				WorkerThreadPool.wait_for_task_completion(i)
				threads.remove_at(threads.find(i))
			if threads.is_empty():
				_update_video(video)
		
		return







func start() -> void:
	
	preloaded_media_path = "%s%s%s" % [path, "-", get_meta("clip_res")]
	
	stream.mix_rate = 44100
	stream.stereo = true
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_player.stream = stream
	
	if MediaServer.media_preloaded.has(preloaded_media_path):
		video = MediaServer.media_preloaded[preloaded_media_path]
		_update_video(video)
	else:
		video = Video.new()
		video.set_hw_decoding(hardware_decoding if OS.get_name() != "Windows" else false)
		threads.append(WorkerThreadPool.add_task(_open_video))
		threads.append(WorkerThreadPool.add_task(_open_audio))








func play(frame_from: int = 0) -> void:
	is_playing = true
	seek_frame(frame_from)
	step_frame()

func stop() -> void:
	is_playing = false

func step_frame() -> void:
	video.next_frame(false)
	_set_frame_image()
	await EditorServer.time_line.curr_frame_changed_automatically
	if is_playing:
		step_frame()

func seek_frame(frame: int) -> void:
	if not is_open():
		return
	
	curr_frame = clamp(frame, 0, _frame_count)
	if video.seek_frame(curr_frame):
		printerr("Couldn't seek frame!")
	else:
		_set_frame_image()
	
	#audio_player.set_stream_paused(false)
	#audio_player.play(curr_frame / _frame_rate)
	#audio_player.set_stream_paused(!is_playing)

func next_frame(skip: bool = false) -> void:
	if video.next_frame(skip) and not skip:
		_set_frame_image()
	elif not skip:
		print("Something went wrong getting next frame!")

func is_open() -> bool:
	return video != null and video.is_open()

func is_updated() -> bool:
	return updated








func _open_video() -> void:
	print(preloaded_media_path)
	if video.open(path):
		printerr("Error opening video!")
	MediaServer.media_preloaded[preloaded_media_path] = video

func _open_audio() -> void:
	audio_player.stream.data = Audio.get_audio_data(path)


func _update_video(new_video: Video) -> void:
	video = new_video
	if !is_open():
		printerr("Video isn't open!")
		return
	
	var image: Image
	
	_padding = video.get_padding()
	_rotation = video.get_rotation()
	_frame_rate = video.get_framerate()
	_resolution = video.get_resolution()
	_frame_count = video.get_frame_count()
	_uv_resolution = Vector2i(int((_resolution.x + _padding) / 2.), int(_resolution.y / 2.))
	image = Image.create_empty(_resolution.x, _resolution.y, false, Image.FORMAT_R8)
	
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
	
	shader_material.set_shader_parameter("resolution", _resolution)
	
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





















