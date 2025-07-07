extends Node


var viewport: SubViewport

var root: Node2D
var camera: Camera2D

var curr_nodes: Dictionary


# RealTime Variables
var update_video_viewers_on_drag: bool
var update_video_viewers_frame: bool
var update_video_viewers_rate: float = .5




func _ready() -> void:
	# Start Scene
	start_scene()
	# Connections
	var timeline = EditorServer.time_line
	timeline.curr_frame_played_manually.connect(on_timeline_curr_frame_played_manually)
	timeline.curr_frame_stopped_manually.connect(on_timeline_curr_frame_stopped_manually)
	timeline.timeline_played.connect(try_play)
	timeline.timeline_stoped.connect(stop)



func start_scene() -> void:
	await EditorServer.player.ready
	viewport = EditorServer.player.viewport
	root = Node2D.new()
	camera = Camera2D.new()
	root.add_child(camera)
	viewport.add_child(root)

func create_sprite(layer: int, clip_res: MediaClipRes, frame_begin: int) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = MediaServer.get_image_texture_from_path(clip_res.media_resource_path)
	sprite.z_index = layer
	instance_node(layer, sprite, clip_res, frame_begin)
	return sprite

func create_video(layer: int, clip_res: MediaClipRes, frame_begin: int) -> VideoViewer:
	var video_renderer = VideoViewer.new()
	video_renderer.path = clip_res.media_resource_path
	video_renderer.z_index = layer
	instance_node(layer, video_renderer, clip_res, frame_begin)
	try_play()
	return video_renderer

func create_audio(layer: int, clip_res: MediaClipRes, frame_begin: int) -> AudioStreamPlayer:
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = load(clip_res.media_resource_path)
	audio_player.bus = ProjectServer.get_bus_name_from_layer_index(layer)
	instance_node(layer, audio_player, clip_res, frame_begin)
	try_play()
	return audio_player

func remove_node(layer: int) -> void:
	if curr_nodes.has(layer):
		curr_nodes[layer].scene_node.queue_free()
		curr_nodes[layer].tree_node.free()
		curr_nodes.erase(layer)

func instance_node(layer: int, node: Node, clip_res: MediaClipRes, frame_begin: int) -> void:
	node.set_meta("layer", layer)
	node.set_meta("clip_pos", frame_begin)
	node.set_meta("clip_res", clip_res)
	
	var tree_node = EditorServer.clip_nodes_explorer.create_layer_node(layer, clip_res)
	root.add_child(node)
	
	curr_nodes[layer] = {
		"tree_node" = tree_node,
		"scene_node" = node
	}

func try_play(curr_frame = null) -> void:
	
	var timeline = EditorServer.time_line
	
	if not timeline.is_playing:
		return
	
	if curr_frame == null:
		curr_frame = timeline.curr_frame
	
	await loop_nodes(
		func(layer: int, node: Node):
			var clip_pos = node.get_meta("clip_pos")
			var local_frame = TimeServer.localize_frame(curr_frame, clip_pos)
			
			if node is AudioStreamPlayer:
				if node.playing:
					return
				node.play(TimeServer.frame_to_seconds(local_frame))
			
			elif node is VideoViewer:
				if node.is_playing:
					return
				if not node.is_updated():
					await node.video_updated
				node.play(timeline.curr_frame)
				return 1
	)



func stop() -> void:
	loop_nodes(
		func(layer: int, node: Node):
			if node is AudioStreamPlayer:
				node.stop()
			elif node is VideoViewer:
				node.stop()
	)



func seek_video_viewers_frame(curr_frame = null) -> void:
	if curr_frame == null:
		curr_frame = EditorServer.time_line.curr_frame
	
	var video_viewer_count: int
	for node in curr_nodes:
		if node is VideoViewer:
			video_viewer_count += 1
	var between_rate = update_video_viewers_rate / float(video_viewer_count)
	
	loop_nodes(
		func(layer: int, node: Node):
			if node is VideoViewer:
				node.seek_frame(curr_frame)
				await get_tree().create_timer(between_rate).timeout
	)
	
	await get_tree().create_timer(update_video_viewers_rate).timeout
	if update_video_viewers_frame:
		seek_video_viewers_frame()






func on_timeline_curr_frame_played_manually() -> void:
	if update_video_viewers_on_drag:
		update_video_viewers_frame = true
		seek_video_viewers_frame()

func on_timeline_curr_frame_stopped_manually() -> void:
	update_video_viewers_frame = false
	seek_video_viewers_frame()






func loop_nodes(function: Callable) -> void:
	for layer in curr_nodes.keys():
		var node = curr_nodes[layer].scene_node
		var frames_delay = await function.call(layer, node)









