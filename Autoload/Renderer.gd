extends Node

signal render_started()

signal frame_sended(frame: int)

signal render_paused()
signal render_resumed()

signal render_finished_successfully()
signal render_canceled_or_failed(error: String)
signal render_stopped()

@export var is_working: bool
@export var is_paused: bool

var output_path: String
var video_renderer: VideoRenderer
var audio_renderer: AudioRenderer

var latest_image: Image

func start(_output_path: String, _video_renderer: VideoRenderer, _audio_renderer: AudioRenderer) -> void:
	
	is_working = true
	is_paused = false
	
	EditorServer.update_from_performance_settings()
	
	PlaybackServer.stop()
	PlaybackServer.seek(0)
	
	output_path = _output_path
	video_renderer = _video_renderer
	audio_renderer = _audio_renderer
	
	var resolution: Vector2i = ProjectServer2.project_res.resolution
	video_renderer.set_width(resolution.x)
	video_renderer.set_height(resolution.y)
	video_renderer.set_fps(ProjectServer2.project_res.fps)
	
	if not video_renderer.start(output_path):
		return
	audio_renderer.share_video_renderer_format_ctx(video_renderer)
	if not audio_renderer.start():
		return
	if not video_renderer.open_output_file():
		return
	
	send_frame()
	
	render_started.emit()

func send_frame() -> void:
	
	if not is_working:
		_force_cancel()
		return
	
	if is_paused:
		return
	
	if not PlaybackServer.is_render_process_finished:
		await PlaybackServer.render_process_finished
	
	Scene2.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	latest_image = Scene2.viewport.get_texture().get_image()
	latest_image.convert(Image.FORMAT_RGBAH)
	video_renderer.send_frame(latest_image)
	
	if audio_renderer:
		var all_layers_samples: Array[PackedByteArray] = _extract_all_audio_samples_at(PlaybackServer.position)
		var samples: PackedByteArray = AudioMixer.mix_buffers(all_layers_samples, 1.)
		audio_renderer.push_samples(samples)
	
	frame_sended.emit(PlaybackServer.position)
	
	if PlaybackServer.position > ProjectServer2.project_res.root_clip_res.length:
		_finish()
		return
	
	PlaybackServer.position += 1
	send_frame()

func pause() -> void:
	is_paused = true
	render_paused.emit()

func resume() -> void:
	if is_paused:
		is_paused = false
		send_frame()
		render_resumed.emit()

func pause_resume() -> void:
	if Renderer.is_paused: Renderer.resume()
	else: Renderer.pause()

func cancel() -> void:
	is_working = false
	if is_paused:
		_force_cancel()

func _force_cancel() -> void:
	video_renderer.finish()
	if audio_renderer:
		audio_renderer.finish()
	video_renderer.close_output_file()
	
	if FileAccess.file_exists(output_path):
		DirAccess.remove_absolute(output_path)
	
	EditorServer.update_from_performance_settings()
	
	render_canceled_or_failed.emit("The rendering was cancelled, output file was deleted.")
	render_stopped.emit()

func _finish() -> void:
	is_working = false
	video_renderer.finish()
	if audio_renderer:
		audio_renderer.finish()
	video_renderer.close_output_file()
	
	EditorServer.update_from_performance_settings()
	
	render_finished_successfully.emit()
	render_stopped.emit()
	
	OS.shell_show_in_file_manager(output_path)


func _extract_all_audio_samples_at(position: int) -> Array[PackedByteArray]:
	
	var result: Array[PackedByteArray]
	
	var root_clip_res: RootClipRes = ProjectServer2.project_res.root_clip_res
	var layers: Array[LayerRes] = root_clip_res.layers
	
	for layer_idx: int in layers.size():
		var layer: RootLayerRes = layers[layer_idx]
		var curr_clip_res: MediaClipRes = layer.displayed_clip_res
		
		if not curr_clip_res:
			continue
		
		if curr_clip_res is VideoClipRes or curr_clip_res is AudioClipRes:
			var samples: PackedByteArray = curr_clip_res.audio_data_res.extract_frame_samples(position - layer.displayed_frame + curr_clip_res.from)
			result.append(samples)
	
	return result








