extends Node

signal curr_length_changed(new_length: int)

signal media_clip_added(layer_index: int, frame_in: int)
signal media_clips_copied()
signal media_clips_pasted()
signal media_clips_removed()
signal media_clips_duplicated()
signal media_clips_moved()
signal media_clips_changed()

signal media_clip_entered(clip_res_to: MediaClipRes)
signal media_clip_exited(clip_res_from: MediaClipRes, times: int)

signal layer_added(layer_index: int)
signal layer_property_changed(layer_index: int)
signal layers_added(layers_indeces: PackedInt32Array)
signal layers_changed()

signal curr_layers_changed()

signal time_markers_changed()


const EXAMPLE_PATH: String = "res://ExampleProject/"

var project_path: String = EXAMPLE_PATH
var objects_path: String = project_path + "objects"
var explorer_thumbnails_path: String = project_path + "thumbnails/explorer"
var timeline_thumbnails_path: String = project_path + "thumbnails/timeline"
var brush_thumbnails_path: String = project_path + "thumbnails/brushes"

var aspect_ratio: Vector2
var resolution: Vector2i = Vector2i(1280, 720)
var default_length: int = 900 # as Frames
var curr_length: int = default_length:
	set(val):
		curr_length = val
		curr_length_changed.emit(val)
var fps: int = 30:
	set(val):
		fps = val
		delta = 1.0 / fps
var delta: float = 1.0 / fps

var project_length: int

var layers: Dictionary[int, Dictionary] = {}
# layers = {
	# layer_index: {
		# media_clips: {time_x: MediaClipRes.new(), time_y: MediaClipRes.new()},
		# audio_bus: {volume: int(), muted: bool()},
		# loked: bool(),
		# hidden: bool(),
		# more: {}
	#}
#}

var time_markers: Dictionary[int, TimeMarkerRes]

var copied_media_clips: Array[Dictionary]

var curr_clips: Dictionary[int, int] # key is layer, val is (clip_id or time_begin)

var curr_layers_path: Array[Dictionary]
var curr_layers_string_path: Array[String]
var curr_layers: Dictionary[int, Dictionary] = layers:
	set(val):
		curr_layers = val
		curr_layers_changed.emit()

var curr_spacial_frames: Array[int]



# Background Called Functions
# ---------------------------------------------------

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(objects_path)
	DirAccess.make_dir_recursive_absolute(explorer_thumbnails_path)
	DirAccess.make_dir_recursive_absolute(timeline_thumbnails_path)
	DirAccess.make_dir_recursive_absolute(brush_thumbnails_path)
	
	update_curr_length_and_curr_spacial_frames()


# Media Clips
# ---------------------------------------------------

func get_media_clip(layer_index: int, frame_in: int) -> MediaClipRes:
	return curr_layers[layer_index].media_clips[frame_in]

func add_media_clip(media_path: String, layer_index: int = -1, frame_in: int = 0, object_res: UsableRes = null, emit_changes: bool = false) -> void:
	
	if object_res != null:
		if media_path.is_empty():
			var object_id: String = generate_new_id(DirAccess.get_files_at(objects_path))
			var object_name: String = "object_" + object_id + ".res"
			media_path = "%s/%s" % [objects_path, object_name]
		ResourceSaver.save(object_res, media_path, ResourceSaver.FLAG_COMPRESS)
	
	var media_res: MediaClipRes = MediaClipRes.new()
	var clip_id: String = generate_clip_id()
	var media_length: int = EditorServer.editor_settings.clip_default_length
	
	if MediaServer.get_media_type_from_path(media_path) in [1, 2]:
		media_length = MediaServer.get_audio_duration_with_ffprobe(media_path)
	media_length = int(media_length * fps)
	
	media_res.id = clip_id
	media_res.media_resource_path = media_path
	media_res.length = media_length
	
	layer_index = check_layer(layer_index, frame_in, media_length)
	curr_layers[layer_index].media_clips[frame_in] = media_res
	
	if emit_changes:
		media_clip_added.emit(layer_index, frame_in)
		emit_media_clips_change()
	
	update_scene_nodes()


func copy_media_clips(clips_info: Array[Dictionary], cut: bool = false, emit_changes: bool = true) -> void:
	copied_media_clips = clips_info
	
	if cut:
		remove_media_clips(clips_info)
	
	if emit_changes:
		update_scene_nodes()
		media_clips_copied.emit()
		emit_media_clips_change()


func past_media_clips(target_frames_in: Array, target_layers_indeces: Array = [-1], true_arrangement: bool = true, generate_new_id: bool = true, force_same_layer_index: bool = false, emit_changes: bool = true) -> Dictionary[int, Dictionary]:
	
	if not copied_media_clips: return {}
	
	var pasted_layers: Dictionary[int, Dictionary]
	
	var displacement_frame: int
	if true_arrangement:
		var frames: Array[int]
		for info in copied_media_clips:
			frames.append(info.clip_pos)
		displacement_frame = frames.min()
	
	for index: int in copied_media_clips.size():
		
		var info: Dictionary = copied_media_clips[index]
		
		var from_layer_index: int = info.layer_index
		var from_frame_in: int = info.clip_pos
		var media_res: MediaClipRes = info.clip_res.duplicate(true)
		if generate_new_id:
			media_res.id = generate_clip_id()
		var true_index: int = min(index, target_frames_in.size() - 1)
		var target_frame_in: int = target_frames_in[true_index]
		var target_layer_index: int = target_layers_indeces[true_index]
		var absolute_target_frame_in: int = (from_frame_in + target_frame_in - displacement_frame) if true_arrangement else target_frame_in
		var absolute_target_layer_index: int = from_layer_index
		if not force_same_layer_index:
			absolute_target_layer_index = check_layer(from_layer_index if target_layer_index == -1 else target_layer_index, absolute_target_frame_in, media_res.length)
		var target_layer: Dictionary = get_layer(absolute_target_layer_index)
		
		target_layer.media_clips[absolute_target_frame_in] = media_res
		
		if not pasted_layers.has(absolute_target_layer_index):
			pasted_layers[absolute_target_layer_index] = {}
		pasted_layers[absolute_target_layer_index][absolute_target_frame_in] = media_res
	
	if emit_changes:
		update_scene_nodes()
		media_clips_pasted.emit()
		emit_media_clips_change()
	
	return pasted_layers


func edit_media_clip(layer_index: int, frame_in: int, edit_info: Dictionary[String, Variant], emit_changes: bool = true) -> Dictionary:
	var target_frame_in: int = edit_info.frame_in
	var media_res: MediaClipRes = curr_layers[layer_index].media_clips[frame_in]
	remove_media_clips([{"layer_index": layer_index, "clip_pos": frame_in}], true)
	media_res.from = edit_info.from
	media_res.length = edit_info.length
	curr_layers[check_layer(layer_index, target_frame_in, edit_info.length)].media_clips[target_frame_in] = media_res
	update_scene_nodes()
	if emit_changes:
		emit_media_clips_change()
	return {"layer_index": layer_index, "clip_pos": target_frame_in, "clip_res": media_res}

func split_media_clip(clip_info: Dictionary, split_in: int, right_side: bool, left_side: bool, emit_changes: bool = true) -> void:
	var layer_index: int = clip_info.layer_index
	var clip_pos: int = clip_info.clip_pos
	var clip_res: MediaClipRes = clip_info.clip_res
	
	var local_frame: int = TimeServer.localize_frame(split_in, clip_pos)
	var full_length: int = clip_res.length
	
	if local_frame < 0 or local_frame >= full_length:
		return
	
	# Left Cut
	var left_info: Dictionary = edit_media_clip(layer_index, clip_pos, {
		"frame_in": clip_pos,
		"from": clip_res.from,
		"length": local_frame
	})
	
	# Right Cut
	if right_side:
		var duplicated_layers: Dictionary[int, Dictionary] = duplicate_media_clips([{"layer_index": layer_index, "clip_pos": clip_pos, "clip_res": clip_res}], split_in, true)
		var absolute_layer: int = duplicated_layers.keys()[0]
		edit_media_clip(absolute_layer, split_in, {
			"frame_in": split_in,
			"from": local_frame + clip_res.from,
			"length": full_length - local_frame
		})
	
	if not left_side:
		remove_media_clips([left_info], false)
	
	update_scene_nodes()
	if emit_changes:
		emit_media_clips_change()


func duplicate_media_clips(clips_info: Array[Dictionary], target_frame_in: int, force_same_layer_index:= false) -> Dictionary[int, Dictionary]:
	copy_media_clips(clips_info, false, false)
	var pasted_layers: Dictionary[int, Dictionary] = past_media_clips([target_frame_in], [-1], true, true, force_same_layer_index, false)
	update_scene_nodes()
	media_clips_duplicated.emit()
	emit_media_clips_change()
	return pasted_layers


func move_media_clips(clips_info: Array[Dictionary], target_layers_indeces: Array, target_frames_in: Array) -> Dictionary[int, Dictionary]:
	copy_media_clips(clips_info, true, false)
	var pasted_layers: Dictionary[int, Dictionary] = past_media_clips(target_frames_in, target_layers_indeces, false, false, false, false)
	update_scene_nodes()
	media_clips_moved.emit()
	emit_media_clips_change()
	return pasted_layers


func remove_media_clips(clips_info: Array[Dictionary], emit_changes: bool = true) -> void:
	for info in clips_info:
		curr_layers[info.layer_index].media_clips.erase(info.clip_pos)
	update_scene_nodes()
	if emit_changes:
		media_clips_removed.emit()
		emit_media_clips_change()


func enter_media_clip_children(layer_index: int, frame_in: int, default_layers_count: int = 4) -> void:
	var media_res: MediaClipRes = get_media_clip(layer_index, frame_in)
	curr_layers_path.append({"layer": layer_index, "frame": frame_in, "res": media_res})
	update_curr_layers()
	media_clip_entered.emit(media_res)

func exit_media_clip_children(times: int) -> void:
	if curr_layers_path.is_empty(): return
	curr_layers_path.resize(curr_layers_path.size() - times)
	update_curr_layers()
	media_clip_exited.emit(times)

func reparent_media_clips() -> void:
	pass

func parent_up_media_clips() -> void:
	pass

func clear_media_clips_parents() -> void:
	pass

func update_curr_layers() -> void:
	
	curr_layers_string_path.clear()
	
	for info: Dictionary in curr_layers_path:
		var media_res: MediaClipRes = info.res
		var media_name: String = media_res.media_resource_path.get_file()
		curr_layers_string_path.append(media_name)
	
	if curr_layers_path.is_empty(): curr_layers = layers
	else: curr_layers = curr_layers_path.back().res.get_children()
	
	update_curr_length_and_curr_spacial_frames()


func emit_media_clips_change() -> void:
	update_curr_length_and_curr_spacial_frames()
	EditorServer.time_line.queue_redraw()
	EditorServer.player.update_ui()
	media_clips_changed.emit()


func loop_media_clips(info: Dictionary[StringName, Variant], method) -> Dictionary[StringName, Variant]:
	for layer_index: int in curr_layers.keys():
		var media_clips: Dictionary = curr_layers[layer_index].media_clips
		for frame_in: int in media_clips.keys():
			var media_res: MediaClipRes = media_clips[frame_in]
			method.call(layer_index, frame_in, media_res, info)
	return info




# Layers
# ---------------------------------------------------


func get_layer_from(layers_lib: Dictionary[int, Dictionary], layer_index: int) -> Dictionary:
	return layers_lib[layer_index]

func get_curr_layers() -> Dictionary[int, Dictionary]:
	return curr_layers

func set_curr_layers(new_layers: Dictionary[int, Dictionary]) -> void:
	curr_layers = new_layers

func get_layer(layer_index: int) -> Dictionary:
	return make_layer_absolute(layer_index)

func get_layer_if(layer_index: int) -> Dictionary:
	return curr_layers[layer_index]

func get_default_layer() -> Dictionary:
	return {
		media_clips = {},
		audio_bus = {
			volume = .0,
			muted = false
		},
		customization = get_default_layer_customization(),
		locked = false,
		hidden = false,
		more = {},
	}

func make_layer_absolute(layer_index: int, emit_change: bool = true) -> Dictionary:
	if not curr_layers.has(layer_index):
		curr_layers[layer_index] = get_default_layer()
		if curr_layers_path.is_empty():
			make_audio_bus_absolute(layer_index)
		if emit_change: layer_added.emit(layer_index)
	return curr_layers[layer_index]

func make_layers_absolute(layers_indeces: PackedInt32Array) -> void:
	for layer_index: int in layers_indeces: make_layer_absolute(layer_index, false)
	layers_added.emit(layers_indeces)

func delete_layer(layer_index: int) -> void:
	curr_layers[layer_index].clear()
	move_layers(layer_index + 1, layers.keys().max(), -1, false)
	layers_changed.emit()
	update_scene_nodes()

func clear_layer(layer_index: int) -> void:
	curr_layers[layer_index] = get_default_layer()

func clear_layer_media_clips(layer_index: int) -> void:
	curr_layers[layer_index].media_clips = {}

func replace_layer(index_from: int, index_to: int) -> void:
	curr_layers[index_to] = layers[index_from]
	clear_layer(index_from)

func move_layers(from: int, to: int, steps: int, emit_changes: bool = true) -> void:
	var indeces_range: Array = range(from, to)
	if steps > 0: indeces_range.reverse()
	for index: int in indeces_range:
		replace_layer(index, index + steps)
		#printt("index_from", index, "index_to", index + steps)
	if emit_changes:
		layers_changed.emit()

func move_layer(index_from: int, index_to: int) -> void:
	var layer_from: Dictionary = get_layer(index_from)
	if index_from < index_to:
		move_layers(index_from + 1, index_to + 1, -1, false)
	elif index_from > index_to:
		move_layers(index_to, index_from, 1, false)
	curr_layers[index_to] = layer_from
	layers_changed.emit()
	#printt("index_from", index_from, "index_to", index_to)

func set_layer_customization(layer_index: int, name: StringName, color: Color, size: int) -> void:
	get_layer(layer_index)["customization"] = {
		&"name": name, &"color": color, &"size": size
	} as Dictionary[StringName, Variant]

func get_layer_customization(layer_index: int) -> Dictionary[StringName, Variant]:
	return get_layer_if(layer_index).customization

func get_default_layer_customization() -> Dictionary[StringName, Variant]:
	var editor_settings: AppEditorSettings = EditorServer.editor_settings
	return {&"name": "", &"color": editor_settings.layer_color, &"size": editor_settings.layer_size}

func set_layer_lock(index: int, val: bool) -> void:
	curr_layers[index].locked = val
	layer_property_changed.emit(index)

func set_layer_hide(index: int, val: bool) -> void:
	curr_layers[index].hidden = val
	layer_property_changed.emit(index)

func set_layer_mute(index: int, val: bool) -> void:
	curr_layers[index].audio_bus.muted = val
	set_bus_mute(index, val)
	layer_property_changed.emit(index)

func get_layer_lock(index: int) -> bool:
	return curr_layers[index].locked

func get_layer_hide(index: int) -> bool:
	return curr_layers[index].hidden

func get_layer_mute(index: int) -> bool:
	return curr_layers[index].audio_bus.muted

func check_layer(layer_index: int, frame_in: int, media_length: int) -> int:
	if layer_index < 0 or not is_layer_unoccupied(layer_index, frame_in, media_length):
		layer_index = get_best_unoccupied_layer(frame_in, media_length)
	return layer_index

func get_best_unoccupied_layer(frame_in: int, media_length: int) -> int:
	var layer_index: int = 0
	while true:
		if is_layer_unoccupied(layer_index, frame_in, media_length):
			break
		layer_index += 1
	return layer_index

func is_layer_unoccupied(layer_index: int, frame_in: int, media_length: int, media_ignored: Array = []) -> bool:
	
	var layer: Dictionary = get_layer(layer_index)
	var media_clips: Dictionary = layer.media_clips
	
	var new_time_begin: int = frame_in
	var new_time_end: int = frame_in + media_length
	
	for time_begin: int in media_clips.keys():
		var media: MediaClipRes = media_clips.get(time_begin)
		if media_ignored.has(media): continue
		var time_end: int = time_begin + media.length
		if not (time_end <= new_time_begin or new_time_end <= time_begin):
			return false
	return true

func loop_layers(info: Dictionary[StringName, Variant], method: Callable) -> Dictionary[StringName, Variant]:
	for layer_index: int in curr_layers:
		method.call(layer_index, curr_layers[layer_index], info)
	return info


# Audio Bus Management
# ---------------------------------------------------

func make_audio_bus_absolute(layer_index: int) -> void:
	var bus_name: StringName = get_bus_name_from_layer_index(layer_index)
	var bus_count: int = AudioServer.bus_count
	for i: int in bus_count:
		if AudioServer.get_bus_name(i) == bus_name:
			return
	AudioServer.add_bus(bus_count)
	AudioServer.set_bus_name(bus_count, bus_name)

func set_bus_mute(layer_index: int, val: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(get_bus_name_from_layer_index(layer_index)), val)

func get_bus_name_from_layer_index(layer_index: int) -> StringName:
	return StringName("Layer%s" % layer_index)


# Time Markers
# ---------------------------------------------------

func add_time_marker(frame_in: int = 0, custom_name: String = "Marker", custom_color: Color = IS.RAINBOW_COLORS[2], custom_description: String = "Just a Marker :)") -> void:
	var time_marker: TimeMarkerRes = TimeMarkerRes.new()
	time_marker.custom_name = custom_name
	time_marker.custom_color = custom_color
	time_marker.custom_description = custom_description
	time_markers[frame_in] = time_marker
	time_markers_changed.emit()
	update_curr_length_and_curr_spacial_frames()

func move_time_marker(from_frame_in: int, target_frame_in: int) -> void:
	if time_markers.keys().has(target_frame_in):
		return
	var time_marker_res: TimeMarkerRes = time_markers[from_frame_in].duplicate(true)
	time_markers.erase(from_frame_in)
	time_markers[target_frame_in] = time_marker_res
	time_markers_changed.emit()
	update_curr_length_and_curr_spacial_frames()

func remove_time_marker(frame_in: int) -> void:
	time_markers.erase(frame_in)
	time_markers_changed.emit()
	update_curr_length_and_curr_spacial_frames()

# Scene Management
# ---------------------------------------------------

func is_frame_on_media(curr_frame: int, time_begin: int, clip_length: int) -> bool:
	var time_end: int = time_begin + clip_length
	return curr_frame >= time_begin and curr_frame < time_end

func update_scene_nodes(curr_frame: int = -1) -> Dictionary[int, int]:
	
	var new_clips: Dictionary[int, int]
	
	if curr_frame < 0:
		curr_frame = EditorServer.time_line.curr_frame
	
	for layer_index: int in layers.keys():
		var media_clips: Dictionary = layers[layer_index].media_clips
		for time_begin: int in media_clips.keys():
			var media_res: MediaClipRes = media_clips.get(time_begin)
			if is_frame_on_media(curr_frame, time_begin, media_res.length):
				new_clips[layer_index] = time_begin
				var layer_node: Node = Scene.get_scene_node(layer_index)
				var local_frame: int = TimeServer.localize_frame(curr_frame, time_begin)
				if layer_node: media_res.process(local_frame)
				break
	
	var removed_clips: Dictionary[int, int]
	var added_clips: Dictionary[int, int]
	
	for index: int in curr_clips.keys():
		var curr_clip_id: int = curr_clips[index]
		if new_clips.has(index) and curr_clip_id == new_clips[index]:
			continue
		removed_clips[index] = curr_clip_id
		remove_node(index, curr_clip_id)
	
	for index: int in new_clips.keys():
		var new_clip_id: int = new_clips[index]
		if curr_clips.has(index) and new_clip_id == curr_clips[index]:
			continue
		added_clips[index] = new_clip_id
		instance_node(index, new_clip_id)
	
	curr_clips = new_clips
	
	return curr_clips


func remove_node(layer: int, clip_id: int) -> void:
	var node: Node = Scene.get_scene_node(layer)
	node.get_meta("clip_res").exit(node)
	Scene.remove_node(layer)


func instance_node(layer: int, clip_id: int) -> void:
	var clip_res: MediaClipRes = layers[layer].media_clips[clip_id]
	var media_res_path: String = clip_res.media_resource_path
	var media_type: int = MediaServer.get_media_type_from_path(media_res_path)
	
	if media_type == -1:
		printerr("Project Server: Invalid Instance Layer Clip (Media type could not be recognized).")
		return
	
	var node: Node
	match media_type:
		0: node = Scene.create_sprite(layer, clip_res, clip_id)
		1: node = Scene.create_video(layer, clip_res, clip_id)
		2: node = Scene.create_audio(layer, clip_res, clip_id)
		3: node = Scene.create_empty_object(layer, clip_res, clip_id)
		4: node = Node.new() # Scene.create_text()
		5: node = Scene.create_draw(layer, clip_res, clip_id)
		6: node = Node.new() # Scene.create_particles()
		7: node = Scene.create_camera_2d(layer, clip_res, clip_id)
		8: node = Scene.create_audio_2d(layer, clip_res, clip_id)
	
	clip_res.enter(node)
	clip_res.process(TimeServer.localize_frame(EditorServer.frame, clip_id))


func generate_clip_id(id_length: int = 12) -> String:
	return generate_new_id(get_used_clip_id(), id_length)


func get_used_clip_id() -> PackedStringArray:
	var used_clip_id:= PackedStringArray()
	for layer_index in layers:
		var clips: Dictionary = layers[layer_index].media_clips
		for time_begin in clips:
			used_clip_id.append(clips[time_begin].id)
	return used_clip_id



# Somethings
# ---------------------------------------------------

func get_start_and_end_frame() -> Array[int]:
	
	var frame_start_in: int
	var frame_end_in: int
	
	var curr_layers_path: Array[Dictionary] = curr_layers_path
	
	if curr_layers_path.size():
		var curr_info: Dictionary = curr_layers_path.back()
		frame_start_in = curr_info.frame
		frame_end_in = frame_start_in + curr_info.res.length
	else:
		frame_start_in = 0
		frame_end_in = ProjectServer.curr_length
	
	return [frame_start_in, frame_end_in]

func update_curr_length_and_curr_spacial_frames() -> void:
	var result:= loop_media_clips({"length_needed": 0 as int, "new_frame_poss": [] as Array[int]},
		func(l: int, f: int, m: MediaClipRes, i: Dictionary[StringName, Variant]) -> void:
			var curr_result_needed: int = f + m.length
			if curr_result_needed > i.length_needed:
				i.length_needed = curr_result_needed
			i.new_frame_poss.append(curr_result_needed)
			i.new_frame_poss.append(f)
	)
	
	curr_length = max(default_length, result.length_needed)
	var start_and_end: Array[int] = get_start_and_end_frame()
	curr_spacial_frames = start_and_end + result.new_frame_poss + time_markers.keys()


# Files and Saving Part
# ---------------------------------------------------

func get_res_file(path: String, as_file: Resource) -> Resource:
	var full_path = project_path + path
	DirAccess.make_dir_absolute(full_path.get_base_dir())
	if not FileAccess.file_exists(full_path):
		ResourceSaver.save(as_file, full_path)
	return ResourceLoader.load(full_path)


# Generating
# ---------------------------------------------------

func generate_new_id(used_id: PackedStringArray, id_length: int = 12) -> String:
	var id_keys: String = "abcdefghijklmnopqrstuvwxyz"
	var keys_length: int = id_keys.length() - 1
	
	var result_id: String
	
	while not result_id or result_id in used_id:
		result_id = ""
		for time in id_length:
			result_id += id_keys[randi_range(0, keys_length)]
	
	return result_id














