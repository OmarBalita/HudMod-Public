extends Node

var viewport: SubViewport

var root: Node2D
var camera: Camera2D

var curr_nodes: Dictionary



func _ready() -> void:
	# Start Scene
	start_scene()
	# Connections
	EditorServer.time_line.curr_frame_stopped_manually.connect(on_timeline_curr_frame_stopped_manually)
	EditorServer.time_line.timeline_played.connect(try_play)
	EditorServer.time_line.timeline_stoped.connect(stop)
	pass

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
	instance_node(layer, sprite, clip_res, frame_begin)
	return sprite

func create_video(layer: int, clip_res: MediaClipRes, frame_begin: int) -> VideoRenderer:
	var video_renderer = VideoRenderer.new()
	video_renderer.path = clip_res.media_resource_path
	instance_node(layer, video_renderer, clip_res, frame_begin)
	try_play()
	return video_renderer

func create_audio(layer: int, clip_res: MediaClipRes, frame_begin: int) -> AudioStreamPlayer:
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = load(clip_res.media_resource_path)
	instance_node(layer, audio_player, clip_res, frame_begin)
	try_play()
	return audio_player


func remove_node(layer: int) -> void:
	if curr_nodes.has(layer):
		curr_nodes[layer].scene_node.queue_free()
		curr_nodes[layer].tree_node.free()
		curr_nodes.erase(layer)

func instance_node(layer: int, node: Node, clip_res: MediaClipRes, frame_begin: int) -> void:
	var tree_node = EditorServer.clip_nodes_explorer.create_layer_node(layer, clip_res)
	node.set_meta("clip_res", clip_res)
	node.set_meta("clip_pos", frame_begin)
	root.add_child(node)
	curr_nodes[layer] = {
		"scene_node" = node,
		"tree_node" = tree_node
	}




func loop_nodes(function: Callable) -> void:
	for layer in curr_nodes.keys():
		var node = curr_nodes[layer].scene_node
		function.call(layer, node)



func try_play(curr_frame: int = -1) -> void:
	var timeline = EditorServer.time_line
	
	if not timeline.is_playing:
		return
	
	if curr_frame == -1:
		curr_frame = timeline.curr_frame
	
	loop_nodes(
		func(layer: int, node: Node):
			var clip_pos = node.get_meta("clip_pos")
			var local_frame = localize_frame(curr_frame, clip_pos)
			
			if node is AudioStreamPlayer:
				node.play(TimeServer.frame_to_seconds(local_frame))
			elif node is VideoRenderer:
				if not node.is_updated():
					await node.video_updated
				node.play(localize_frame(EditorServer.time_line.curr_frame, clip_pos))
	)


func stop() -> void:
	loop_nodes(
		func(layer: int, node: Node):
			if node is AudioStreamPlayer:
				node.stop()
			elif node is VideoRenderer:
				node.stop()
	)




func localize_frame(curr_frame: int, clip_pos: int) -> int:
	return curr_frame - clip_pos

func globalize_position(local_frame: int, clip_pos: int) -> int:
	return local_frame + clip_pos







func on_timeline_curr_frame_stopped_manually() -> void:
	loop_nodes(
		func(layer: int, node: Node):
			if node is VideoRenderer:
				node.seek_frame(localize_frame(EditorServer.time_line.curr_frame, node.get_meta("clip_pos")))
	)
























