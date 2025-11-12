extends Node

var viewport: SubViewport

var root: Node2D
var camera: Camera2D

var curr_nodes: Dictionary

# RealTime Variables
var update_video_viewers_on_drag: bool
var update_video_viewers_frame: bool
var update_video_viewers_rate: float = .5



class NodeData extends Resource:
	
	var instantiated_node: Node
	@export var parent: NodeData
	@export var children: Dictionary[int, NodeData]
	
	@export var node_owner: MediaClipRes
	
	func set_instantiated_node(new_val: Node) -> void:
		instantiated_node = new_val
	
	func set_parent(new_val: NodeData) -> void:
		parent = new_val
	
	func add_child() -> void:
		pass
	
	func remove_child() -> void:
		pass
	
	func set_node_owner(new_val: MediaClipRes) -> void:
		node_owner = new_val



func get_curr_nodes() -> Dictionary:
	return curr_nodes

func _ready() -> void:
	if get_tree().get_current_scene().scene_file_path == "res://Prototype/PrototypeMain.tscn":
		# Start Scene
		start_scene()
		# Connections
		var timeline = EditorServer.time_line
		ProjectServer.layer_property_changed.connect(on_layer_property_changed)
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
	var sprite:= Sprite2D.new()
	sprite.texture = MediaServer.get_image_texture_from_path(clip_res.media_resource_path)
	instance_node_2d(layer, sprite, clip_res, frame_begin)
	return sprite

func create_video(layer: int, clip_res: MediaClipRes, frame_begin: int) -> VideoViewer:
	var video_renderer:= VideoViewer.new()
	video_renderer.path = clip_res.media_resource_path
	instance_node_2d(layer, video_renderer, clip_res, frame_begin)
	try_play()
	return video_renderer

func create_audio(layer: int, clip_res: MediaClipRes, frame_begin: int) -> AudioStreamPlayer:
	var audio_player:= AudioStreamPlayer.new()
	var stream:= MediaServer.get_audio_stream_from_path(clip_res.media_resource_path)
	audio_player.stream = stream
	audio_player.bus = ProjectServer.get_bus_name_from_layer_index(layer)
	instance_node(layer, audio_player, clip_res, frame_begin)
	try_play()
	return audio_player

func create_empty_object(layer: int, clip_res: MediaClipRes, frame_begin: int) -> Node2D:
	var empty_object:= Node2D.new()
	instance_node_2d(layer, empty_object, clip_res, frame_begin)
	return empty_object

func create_text() -> void:
	pass

func create_draw(layer: int, clip_res: MediaClipRes, frame_begin: int) -> GDDraw:
	var draw:= GDDraw.new()
	var draw_res: DrawRes = ResourceLoader.load(clip_res.media_resource_path)
	draw.drawings_ress = draw_res.drawings_ress
	instance_node_2d(layer, draw, clip_res, frame_begin)
	return draw

func create_particles() -> void:
	pass

func create_camera_2d(layer: int, clip_res: MediaClipRes, frame_begin: int) -> Camera2D:
	var camera:= Camera2D.new()
	instance_node_2d(layer, camera, clip_res, frame_begin)
	camera.make_current()
	return camera

func create_audio_2d(layer: int, clip_res: MediaClipRes, frame_begin: int) -> AudioStreamPlayer2D:
	var audio_2d:= AudioStreamPlayer2D.new()
	instance_node_2d(layer, audio_2d, clip_res, frame_begin)
	return audio_2d




func setup_node2d(layer: int, node: Node2D) -> void:
	node.z_index = layer
	node.visible = not ProjectServer.get_layer_hide(layer)

func get_scene_node(layer: int) -> Node:
	return curr_nodes[layer].scene_node if curr_nodes.has(layer) else null

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



func instance_node_2d(layer: int, node: Node, clip_res: MediaClipRes, frame_begin: int) -> void:
	setup_node2d(layer, node)
	instance_node(layer, node, clip_res, frame_begin)

func update_node_2d_visbility(layer: int, node: Node, visibility: Variant = null) -> void:
	var node_visib: bool
	if visibility == null:
		node_visib = not ProjectServer.get_layer_hide(layer)
	else:
		node_visib = visibility
	node.visible = node_visib



func try_play(curr_frame = null) -> void:
	
	var timeline = EditorServer.time_line
	
	if not timeline.is_playing:
		return
	
	if curr_frame == null:
		curr_frame = timeline.curr_frame
	
	await loop_nodes(
		func(layer: int, node: Node):
			var clip_pos = node.get_meta("clip_pos")
			var from = node.get_meta("clip_res").from
			var local_frame = TimeServer.localize_frame(curr_frame, clip_pos)
			
			if node is AudioStreamPlayer:
				if node.playing:
					return
				node.play(TimeServer.frame_to_seconds(local_frame + from))
			
			elif node is VideoViewer:
				if node.is_playing:
					return
				if not node.is_updated():
					await node.video_updated
				node.play(timeline.curr_frame)
				return 1
	)


func loop_nodes(function: Callable) -> void:
	for layer in curr_nodes.keys():
		var node = curr_nodes[layer].scene_node
		var frames_delay = await function.call(layer, node)

func stop() -> void:
	loop_nodes(
		func(layer: int, node: Node):
			if node is AudioStreamPlayer:
				node.stop()
			elif node is VideoViewer:
				node.stop()
	)

func update_visibilities(visibility: Variant = null) -> void:
	loop_nodes(
		func(layer: int, node: Node):
			if node is Node2D: update_node_2d_visbility(layer, node, visibility)
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




func on_layer_property_changed(index: int) -> void:
	update_visibilities()

func on_timeline_curr_frame_played_manually() -> void:
	if update_video_viewers_on_drag:
		update_video_viewers_frame = true
		seek_video_viewers_frame()

func on_timeline_curr_frame_stopped_manually() -> void:
	update_video_viewers_frame = false
	seek_video_viewers_frame()













