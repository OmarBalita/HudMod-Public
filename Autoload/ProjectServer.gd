extends Node

signal media_clip_added(layer_index: int, frame_in: int)
signal media_clips_copied()
signal media_clips_pasted()
signal media_clips_removed()
signal media_clips_duplicated()
signal media_clips_moved()
signal media_clips_changed()

signal layer_changed()

signal time_markers_changed()


const EXAMPLE_PATH: String = "res://ExampleProject/"

var project_path: String = EXAMPLE_PATH
var thumbnails_path: String = project_path + "media/thumbnails"
var fortimeline_path: String = project_path + "media/fortimeline"

var aspect_ratio: Vector2
var resolution: Vector2i = Vector2i(1280, 720)
var fps: int = 30:
	set(val):
		fps = val
		delta = 1.0 / fps
var delta: float = 1.0 / fps

var project_length: int

var layers: Dictionary[int, Dictionary]
# layers = {
	# layer_index: {
		# media_clips: {time_x: MediaClipRes.new(), time_y: MediaClipRes.new()},
		# audio_bus: {volume: int(), muted: bool()},
		# loked: bool(),
		# hidden: bool(),
		# muted: bool()
	#}
#}

var time_markers: Dictionary[int, TimeMarkerRes]

var copied_media_clips: Array[Dictionary]

var curr_clips: Dictionary[int, int] # key is layer, val is (clip_id or time_begin)






# Background Called Functions
# ---------------------------------------------------



func _ready() -> void:
	DirAccess.make_dir_absolute(thumbnails_path)
	DirAccess.make_dir_absolute(fortimeline_path)




# Media Clips
# ---------------------------------------------------

func add_media_clip(media_path: String, layer_index: int = -1, frame_in: int = 0) -> void:
	var media_res = MediaClipRes.new()
	var clip_id = generate_clip_id()
	var media_length = EditorServer.editor_default_settings.media_length * fps
	
	if MediaServer.get_media_type_from_path(media_path) in [1, 2]:
		media_length = int(MediaServer.get_audio_duration_with_ffprobe(media_path) * fps)
	media_res.id = clip_id
	media_res.media_resource_path = media_path
	media_res.length = media_length
	
	layer_index = check_layer(layer_index, frame_in, media_length)
	layers[layer_index].media_clips[frame_in] = media_res
	
	media_clip_added.emit(layer_index, frame_in)
	media_clips_changed.emit()
	
	update_scene_nodes()


func copy_media_clips(clips_info: Array[Dictionary], cut: bool = false, emit_changes: bool = true) -> void:
	copied_media_clips = clips_info
	
	if cut:
		remove_media_clips(clips_info)
	
	if emit_changes:
		update_scene_nodes()
		media_clips_copied.emit()
		media_clips_changed.emit()


func past_media_clips(target_frames_in: Array, target_layers_indeces: Array = [-1], true_arrangement: bool = true, generate_new_id: bool = true, force_same_layer_index: bool = false, emit_changes: bool = true) -> Dictionary[int, Dictionary]:
	
	if not copied_media_clips: return {}
	
	var pasted_layers: Dictionary[int, Dictionary]
	
	var displacement_frame: int
	if true_arrangement:
		var frames: Array[int]
		for info in copied_media_clips:
			frames.append(info.clip_pos)
		displacement_frame = frames.min()
	
	for index in copied_media_clips.size():
		
		var info = copied_media_clips[index]
		
		var from_layer_index = info.layer_index
		var from_frame_in = info.clip_pos
		var media_res = info.clip_res.duplicate(true)
		if generate_new_id:
			media_res.id = generate_clip_id()
		var true_index = min(index, target_frames_in.size() - 1)
		var target_frame_in = target_frames_in[true_index]
		var target_layer_index = target_layers_indeces[true_index]
		var absolute_target_frame_in = (from_frame_in + target_frame_in - displacement_frame) if true_arrangement else target_frame_in
		var absolute_target_layer_index = from_layer_index
		if not force_same_layer_index:
			absolute_target_layer_index = check_layer(from_layer_index if target_layer_index == -1 else target_layer_index, absolute_target_frame_in, media_res.length)
		var target_layer = make_layer_absolute(absolute_target_layer_index)
		
		target_layer.media_clips[absolute_target_frame_in] = media_res
		
		if not pasted_layers.has(absolute_target_layer_index):
			pasted_layers[absolute_target_layer_index] = {}
		pasted_layers[absolute_target_layer_index][absolute_target_frame_in] = media_res
	
	if emit_changes:
		update_scene_nodes()
		media_clips_pasted.emit()
		media_clips_changed.emit()
	
	return pasted_layers


func edit_media_clip(layer_index: int, frame_in: int, edit_info: Dictionary[String, Variant], emit_changes: bool = true) -> Dictionary:
	var target_frame_in = edit_info.frame_in
	var media_res = layers[layer_index].media_clips[frame_in].duplicate(true)
	remove_media_clips([{"layer_index": layer_index, "clip_pos": frame_in}], true)
	media_res.from = edit_info.from
	media_res.length = edit_info.length
	layers[check_layer(layer_index, target_frame_in, edit_info.length)].media_clips[target_frame_in] = media_res
	update_scene_nodes()
	if emit_changes:
		media_clips_changed.emit()
	return {"layer_index": layer_index, "clip_pos": target_frame_in, "clip_res": media_res}

func split_media_clip(clip_info: Dictionary, split_in: int, right_side: bool, left_side: bool, emit_changes: bool = true) -> void:
	var layer_index = clip_info.layer_index
	var clip_pos = clip_info.clip_pos
	var clip_res = clip_info.clip_res
	
	var local_frame = TimeServer.localize_frame(split_in, clip_pos)
	var full_length = clip_res.length
	
	if local_frame < 0 or local_frame >= full_length:
		return
	
	# Left Cut
	var left_info = edit_media_clip(layer_index, clip_pos, {
		"frame_in": clip_pos,
		"from": clip_res.from,
		"length": local_frame
	})
	
	# Right Cut
	if right_side:
		var duplicated_layers = duplicate_media_clips([{"layer_index": layer_index, "clip_pos": clip_pos, "clip_res": clip_res}], split_in, true)
		var absolute_layer = duplicated_layers.keys()[0]
		edit_media_clip(absolute_layer, split_in, {
			"frame_in": split_in,
			"from": local_frame + clip_res.from,
			"length": full_length - local_frame
		})
	
	if not left_side:
		remove_media_clips([left_info], false)
	
	update_scene_nodes()
	if emit_changes:
		media_clips_changed.emit()


func duplicate_media_clips(clips_info: Array[Dictionary], target_frame_in: int, force_same_layer_index:= false) -> Dictionary[int, Dictionary]:
	copy_media_clips(clips_info, false, false)
	var pasted_layers = past_media_clips([target_frame_in], [-1], true, true, force_same_layer_index, false)
	update_scene_nodes()
	media_clips_duplicated.emit()
	media_clips_changed.emit()
	return pasted_layers


func move_media_clips(clips_info: Array[Dictionary], target_layers_indeces: Array, target_frames_in: Array) -> Dictionary[int, Dictionary]:
	copy_media_clips(clips_info, true, false)
	var pasted_layers = past_media_clips(target_frames_in, target_layers_indeces, false, false)
	update_scene_nodes()
	media_clips_moved.emit()
	media_clips_changed.emit()
	return pasted_layers


func remove_media_clips(clips_info: Array[Dictionary], emit_changes: bool = true) -> void:
	for info in clips_info:
		layers[info.layer_index].media_clips.erase(info.clip_pos)
	update_scene_nodes()
	if emit_changes:
		media_clips_removed.emit()
		media_clips_changed.emit()






# Layers
# ---------------------------------------------------



func check_layer(layer_index: int, frame_in: int, media_length: int) -> int:
	if layer_index < 0 or not is_layer_unoccupied(layer_index, frame_in, media_length):
		layer_index = get_best_unoccupied_layer(frame_in, media_length)
	return layer_index

func get_best_unoccupied_layer(frame_in: int, media_length: int) -> int:
	var layer_index = 0
	while true:
		if is_layer_unoccupied(layer_index, frame_in, media_length):
			break
		layer_index += 1
	return layer_index

func is_layer_unoccupied(layer_index: int, frame_in: int, media_length: int) -> bool:
	
	var layer = make_layer_absolute(layer_index)
	var media_clips = layer.media_clips
	
	var new_time_begin = frame_in
	var new_time_end = frame_in + media_length
	
	for time_begin: int in media_clips.keys():
		var media = media_clips.get(time_begin)
		var time_end = time_begin + media.length
		if not (time_end <= new_time_begin or new_time_end <= time_begin):
			return false
	return true

func make_layer_absolute(layer_index: int) -> Dictionary:
	if not layers.has(layer_index):
		layers[layer_index] = {
			media_clips = {},
			audio_bus = {
				volume = .0,
				muted = false
			},
			locked = false,
			hidden = false,
		}
	make_audio_bus_absolute(layer_index)
	return layers[layer_index]



func set_layer_lock(index: int, val: bool) -> void:
	layers[index].locked = val
	layer_changed.emit()

func set_layer_hide(index: int, val: bool) -> void:
	layers[index].hidden = val
	layer_changed.emit()

func set_layer_mute(index: int, val: bool) -> void:
	layers[index].audio_bus.muted = val
	set_bus_mute(index, val)
	layer_changed.emit()

func get_layer_lock(index: int) -> bool:
	return layers[index].locked

func get_layer_hide(index: int) -> bool:
	return layers[index].hidden

func get_layer_mute(index: int) -> bool:
	return layers[index].audio_bus.muted


# Audio Bus Management
# ---------------------------------------------------

func make_audio_bus_absolute(layer_index: int) -> void:
	var bus_name = get_bus_name_from_layer_index(layer_index)
	var bus_count = AudioServer.bus_count
	for i in bus_count:
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

func add_time_marker(frame_in: int = 0, custom_name: String = "Marker", custom_color: Color = InterfaceServer.RAINBOW_COLORS[2], custom_description: String = "Just a Marker :)") -> void:
	var time_marker = TimeMarkerRes.new()
	time_marker.custom_name = custom_name
	time_marker.custom_color = custom_color
	time_marker.custom_description = custom_description
	time_markers[frame_in] = time_marker
	time_markers_changed.emit()

func move_time_marker(from_frame_in: int, target_frame_in: int) -> void:
	if time_markers.keys().has(target_frame_in):
		return
	var time_marker_res = time_markers[from_frame_in].duplicate(true)
	time_markers.erase(from_frame_in)
	time_markers[target_frame_in] = time_marker_res
	time_markers_changed.emit()

func remove_time_marker(frame_in: int) -> void:
	time_markers.erase(frame_in)
	time_markers_changed.emit()


# Scene Management
# ---------------------------------------------------

func update_scene_nodes(curr_frame: int = -1) -> Dictionary[int, int]:
	
	var new_clips: Dictionary[int, int]
	
	if curr_frame < 0:
		curr_frame = EditorServer.time_line.curr_frame
	
	for layer_index in layers.keys():
		var media_clips = layers[layer_index].media_clips
		for time_begin: int in media_clips.keys():
			var media = media_clips.get(time_begin)
			var time_end = time_begin + media.length
			if curr_frame >= time_begin and curr_frame < time_end:
				new_clips[layer_index] = time_begin
				break
	
	var removed_clips: Dictionary[int, int]
	var added_clips: Dictionary[int, int]
	
	for index in curr_clips.keys():
		var curr_clip_id = curr_clips[index]
		if new_clips.has(index) and curr_clip_id == new_clips[index]:
			continue
		removed_clips[index] = curr_clip_id
		remove_node(index, curr_clip_id)
	
	for index in new_clips.keys():
		var new_clip_id = new_clips[index]
		if curr_clips.has(index) and new_clip_id == curr_clips[index]:
			continue
		added_clips[index] = new_clip_id
		instance_node(index, new_clip_id)
	
	curr_clips = new_clips
	
	return curr_clips



func remove_node(layer: int, clip_id: int) -> void:
	Scene.remove_node(layer)


func instance_node(layer: int, clip_id: int) -> void:
	var clip_res = layers[layer].media_clips[clip_id]
	var media_res_path = clip_res.media_resource_path
	var media_type = MediaServer.get_media_type_from_path(media_res_path)
	if media_type == -1:
		printerr("Project Server: Invalid Instance Layer Clip (Media type could not be recognized).")
		return
	match media_type:
		0: Scene.create_sprite(layer, clip_res, clip_id)
		1: Scene.create_video(layer, clip_res, clip_id)
		2: Scene.create_audio(layer, clip_res, clip_id)


func generate_clip_id(id_length: int = 12) -> String:
	return generate_new_id(get_used_clip_id(), id_length)


func get_used_clip_id() -> Array[String]:
	var used_clip_id: Array[String]
	for layer_index in layers:
		var clips = layers[layer_index].media_clips
		for time_begin in clips:
			used_clip_id.append(clips[time_begin].id)
	return used_clip_id






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


func generate_new_id(used_id: Array[String], id_length: int = 12) -> String:
	var id_keys = "abcdefghijklmnopqrstuvwxyz"
	var keys_length = id_keys.length() - 1
	
	var result_id: String
	
	while not result_id or result_id in used_id:
		result_id = ""
		for time in id_length:
			result_id += id_keys[randi_range(0, keys_length)]
	
	
	return result_id














