extends Node

var update_video_viewers_frame: bool = false

var editor_settings: AppEditorSettings = EditorServer.editor_settings

var viewport: SubViewport = SubViewport.new()
var root: Node
var camera: Camera2D

var curr_nodes: Array[MediaClipRes]
var stream_players: Array[MediaClipRes]
var video_players: Array[VideoClipRes]
var cameras: Array[Camera2DClipRes]


func _ready_scene() -> void:
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.audio_listener_enable_2d = true
	viewport.transparent_bg = true
	ProjectServer2.project_opened.connect(_on_project_server_project_opened)
	PlaybackServer.played.connect(play_stream_players)
	PlaybackServer.stopped.connect(stop_stream_players)

func start_scene() -> void:
	root = Node.new()
	
	var root_clip_res: RootClipRes = ProjectServer2.project_res.root_clip_res
	root_clip_res.curr_node = root
	curr_nodes.append(root_clip_res)
	
	camera = Camera2D.new()
	root.add_child(camera)
	viewport.add_child(root)
	
	update_viewport()


func update_viewport() -> void:
	viewport.size = ProjectServer2.project_res.resolution
	viewport.use_debanding = Renderer.is_working
	viewport.use_hdr_2d = Renderer.is_working

func get_curr_nodes() -> Array[MediaClipRes]:
	return curr_nodes

func set_curr_nodes(new_val: Array[MediaClipRes]) -> void:
	curr_nodes = new_val

func curr_nodes_has(clip_res: MediaClipRes) -> bool:
	return curr_nodes.has(clip_res)

func curr_nodes_get(clip_res: MediaClipRes) -> Node:
	return clip_res.curr_node

func add_stream_player(audio_clip_res: MediaClipRes) -> void:
	if PlaybackServer.is_playing():
		play_stream_player(audio_clip_res, PlaybackServer.position, float(ProjectServer2.fps))
	stream_players.append(audio_clip_res)
func remove_stream_player(audio_clip_res: MediaClipRes) -> void: stream_players.erase(audio_clip_res)

func add_video_player(video_clip_res: VideoClipRes) -> void:
	if PlaybackServer.is_playing():
		play_video_stream_player(video_clip_res, PlaybackServer.position, float(ProjectServer2.fps))
	video_players.append(video_clip_res)
func remove_video_player(video_clip_res: VideoClipRes) -> void: video_players.erase(video_clip_res)

func add_camera(camera_clip_res: Camera2DClipRes) -> void:
	cameras.append(camera_clip_res)
	update_camera_enabling()
func remove_camera(camera_clip_res: Camera2DClipRes) -> void:
	cameras.erase(camera_clip_res)
	update_camera_enabling()

func update_camera_enabling() -> void:
	camera.enabled = cameras.size() == 0

func spawn_node(parent_res: MediaClipRes, clip_res: MediaClipRes, node: Node) -> void:
	var view: Viewport
	var node_parent: Node = parent_res.curr_node
	
	for prenode: Node in clip_res.prenodes:
		node_parent.add_child(prenode)
	
	node_parent.add_child(node)
	
	for postnode: Node in clip_res.postnodes:
		node_parent.add_child(postnode)
	
	clip_res.curr_node = node
	curr_nodes.append(clip_res)

func free_node(clip_res: MediaClipRes) -> void:
	for prenode: Node in clip_res.prenodes: prenode.queue_free()
	clip_res.prenodes.clear()
	
	clip_res.curr_node.queue_free()
	clip_res.curr_node = null
	
	for postnode: Node in clip_res.postnodes: postnode.queue_free()
	clip_res.postnodes.clear()
	
	curr_nodes.erase(clip_res)


func clear_nodes() -> void:
	for clip_res: MediaClipRes in curr_nodes:
		if clip_res.curr_node:
			clip_res.curr_node.queue_free()
	curr_nodes.clear()
	stream_players.clear()
	video_players.clear()
	cameras.clear()


func loop_nodes(method: Callable) -> void:
	
	for clip_res: MediaClipRes in curr_nodes:
		await method.call(clip_res)

func play_stream_players(at: int) -> void:
	
	var fps_f: float = float(ProjectServer2.fps)
	
	for stream_clip_res: MediaClipRes in stream_players:
		play_stream_player(stream_clip_res, at, fps_f)
	
	for video_clip_res: VideoClipRes in video_players:
		play_video_stream_player(video_clip_res, at, fps_f)

func stop_stream_players(at: int) -> void:
	
	for stream_clip_res: MediaClipRes in stream_players:
		stream_clip_res.curr_node.stop()
	
	for video_clip_res: VideoClipRes in video_players:
		video_clip_res.stream_player.stop()

func play_stream_player(clip_res: MediaClipRes, at: int, fps_f: float) -> void:
	var target_frame: int = PlaybackServer.position - clip_res.clip_pos + clip_res.from
	clip_res.curr_node.play(target_frame / fps_f)

func play_video_stream_player(video_clip_res: VideoClipRes, at: int, fps_f: float) -> void:
	var target_frame: int = PlaybackServer.position - video_clip_res.clip_pos + video_clip_res.from
	video_clip_res.stream_player.play(target_frame / fps_f)



func _on_project_server_project_opened(project_res: ProjectRes) -> void:
	start_scene()

func _on_media_res_shader_material_changed(media_res: MediaClipRes, node_2d: CanvasItem) -> void:
	node_2d.set_material(media_res.get_shader_material())


