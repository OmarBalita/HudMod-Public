extends Node

@export var curr_objects: Dictionary[MediaClipRes, Node]

var update_video_viewers_frame: bool = false

var editor_settings: AppEditorSettings = EditorServer.editor_settings

var viewport: SubViewport
var root: Node
var camera: Camera2D

func _ready_scene() -> void:
	# Start Scene
	start_scene()
	# Connections
	var timeline: TimeLine = EditorServer.time_line
	ProjectServer.layer_property_changed.connect(on_layer_property_changed)
	timeline.curr_frame_played_manually.connect(on_timeline_curr_frame_played_manually)
	timeline.curr_frame_stopped_manually.connect(on_timeline_curr_frame_stopped_manually)
	timeline.timeline_played.connect(try_play)
	timeline.timeline_stoped.connect(stop)

func start_scene() -> void:
	viewport = EditorServer.player.viewport
	root = Node.new()
	curr_objects[ProjectServer.root_clip_res] = root
	camera = Camera2D.new()
	root.add_child(camera)
	viewport.add_child(root)

func get_curr_objects() -> Dictionary[MediaClipRes, Node]:
	return curr_objects

func set_curr_objects(new_val: Dictionary[MediaClipRes, Node]) -> void:
	curr_objects = new_val

func get_object(media_res: MediaClipRes) -> Variant:
	return curr_objects.get(media_res)

func instance_sprite(parent_res: MediaClipRes, imported_res: ImportedClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Sprite2D:
	var sprite:= Sprite2D.new()
	sprite.texture = MediaCache.get_texture(imported_res.key_as_path)
	instance_object_2d(parent_res, imported_res, sprite, layer_index, frame_in, root_layer_index)
	return sprite

func instance_video_viewer(parent_res: MediaClipRes, imported_res: ImportedClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> VideoViewer:
	var video_viewer:= VideoViewer.new()
	instance_object_2d(parent_res, imported_res, video_viewer, layer_index, frame_in, root_layer_index)
	try_play()
	return video_viewer

func instance_audio_stream_player(parent_res: MediaClipRes, imported_res: ImportedClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> AudioStreamPlayer:
	var audio_player:= AudioStreamPlayer.new()
	audio_player.stream = MediaCache.get_audio(imported_res.key_as_path)
	audio_player.bus = ProjectServer.get_bus_name_from_layer_index(root_layer_index)
	instance_object(parent_res, imported_res, audio_player, layer_index, frame_in, root_layer_index)
	try_play()
	return audio_player

func instance_object_2d(parent_res: MediaClipRes, media_res: MediaClipRes, object: CanvasItem, layer_index: int, frame_in: int, root_layer_index: int) -> void:
	instance_object(parent_res, media_res, object, layer_index, frame_in, root_layer_index)
	var object_parent: Node = curr_objects[parent_res]
	object_parent.move_child(object, min(object_parent.get_child_count(), layer_index))
	
	var shader_update_func: Callable = _on_media_res_shader_material_changed.bind(media_res, object)
	
	object.set_material(media_res.get_shader_material())
	media_res.shader_material_changed.connect(shader_update_func)
	object.tree_exited.connect(func() -> void:
		media_res.shader_material_changed.disconnect(shader_update_func)
	)
	
	object.visible = not get_layer_from_media_res(parent_res, layer_index).hidden

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, object: Node, layer_index: int, frame_in: int, root_layer_index: int) -> void:
	var object_parent: Node = curr_objects.get(parent_res)
	object.set_meta(&"parent_res", parent_res)
	object.set_meta(&"media_res", media_res)
	object.set_meta(&"layer_index", layer_index)
	object.set_meta(&"frame_in", frame_in)
	object_parent.add_child(object)
	media_res.curr_node = object
	curr_objects[media_res] = object

func free_object(media_res: MediaClipRes) -> void:
	var children: Dictionary[int, Dictionary] = media_res.get_children()
	for layer_index: int in children:
		var media_ress: Dictionary = children[layer_index].media_clips
		for frame_in: int in media_ress:
			var child_media_res: MediaClipRes = media_ress.get(frame_in)
			free_object(child_media_res)
	
	media_res.curr_clips.clear()
	if curr_objects.has(media_res):
		curr_objects[media_res].queue_free()
		curr_objects.erase(media_res)

func get_layer_from_media_res(media_res: MediaClipRes, layer_index: int) -> Dictionary:
	return media_res.get_children()[layer_index]

func loop_objects(method: Callable) -> void:
	for media_res: MediaClipRes in curr_objects:
		var object: Node = curr_objects[media_res]
		await method.call(media_res, object)

func try_play(curr_frame: Variant = null) -> void:
	var timeline: TimeLine = EditorServer.time_line
	if not timeline.is_playing: return
	await loop_objects(try_play_func)

func try_play_func(media_res: MediaClipRes, object: Node) -> void:
	var curr_frame: int = EditorServer.frame
	
	var frame_in: int = object.get_meta(&"frame_in")
	var start_from: int = media_res.from
	var local_frame: int = TimeServer.localize_frame(curr_frame, frame_in)
	
	if object is AudioStreamPlayer:
		if object.playing:
			return
		object.play((local_frame + start_from) / float(ProjectServer.fps))
	
	elif object is VideoViewer:
		if object.is_playing:
			return
		if not object.is_updated():
			await object.video_updated
		object.play(curr_frame)

func stop() -> void:
	loop_objects(stop_func)

func stop_func(media_res: MediaClipRes, object: Object) -> void:
	if object is AudioStreamPlayer:
		object.stop()
	elif object is VideoViewer:
		object.stop()

func update_visibilities(visibility: Variant = null) -> void:
	loop_objects(
		func(media_res: MediaClipRes, object: Node) -> void:
			if object is Node2D: update_visibility(object, visibility)
	)

func seek_video_viewers_frame(curr_frame: Variant = null) -> void:
	if curr_frame == null: curr_frame = EditorServer.time_line.curr_frame
	
	var video_viewer_count: int
	for media_res: MediaClipRes in curr_objects.keys():
		var object: Node = curr_objects[media_res]
		if object is VideoViewer:
			video_viewer_count += 1
	var between_rate: float = editor_settings.update_video_viewers_rate / float(video_viewer_count)
	
	loop_objects(
		func(media_res: MediaClipRes, object: Node) -> void:
			if object is VideoViewer:
				object.seek_frame(curr_frame)
				await get_tree().create_timer(between_rate).timeout
	)
	
	await get_tree().create_timer(editor_settings.update_video_viewers_rate).timeout
	if update_video_viewers_frame:
		seek_video_viewers_frame()

func update_visibility(object: Node, visibility: Variant = null) -> void:
	if visibility == null:
		var parent_res: MediaClipRes = object.get_meta(&"parent_res")
		var layer_index: int = object.get_meta(&"layer_index")
		visibility = not get_layer_from_media_res(parent_res, layer_index).hidden
	object.visible = visibility

func on_layer_property_changed(index: int) -> void:
	update_visibilities()

func on_timeline_curr_frame_played_manually() -> void:
	if editor_settings.update_video_viewers_on_drag:
		update_video_viewers_frame = true
		seek_video_viewers_frame()

func on_timeline_curr_frame_stopped_manually() -> void:
	update_video_viewers_frame = false
	seek_video_viewers_frame()

func _on_media_res_shader_material_changed(media_res: MediaClipRes, object_2d: CanvasItem) -> void:
	var shader_material: ShaderMaterial = media_res.get_shader_material()
	object_2d.set_material(media_res.get_shader_material())

