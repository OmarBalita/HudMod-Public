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
signal layer_removed()
signal layer_property_changed(layer_index: int)
signal layers_added(layers_indeces: PackedInt32Array)
signal layers_removed(layers_count: int)
signal layers_changed()

signal curr_layers_changed()

signal time_markers_changed()


const EXAMPLE_PATH: String = "res://ExampleProject/"

var project_path: String = EXAMPLE_PATH
var objects_path: String = project_path + "objects"
var explorer_thumbnails_path: String = project_path + "thumbnails/explorer"
var brush_thumbnails_path: String = project_path + "thumbnails/brushes"
var timeline_thumbnails_path: String = project_path + "timeline"

var aspect_ratio: Vector2
var resolution: Vector2i = Vector2i(1920, 1080)
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

var root_clip_res: MediaClipRes = MediaClipRes.new()
var root_layers: Dictionary[int, Dictionary] = {}
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

var curr_layers_path: Array[Dictionary]
var curr_layers_string_path: Array[String]
var curr_layers: Dictionary[int, Dictionary] = root_layers

var curr_spacial_frames: Array[int]

var copied_media_clips: Array[Dictionary]


# Background Called Functions
# ---------------------------------------------------

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(objects_path)
	DirAccess.make_dir_recursive_absolute(explorer_thumbnails_path)
	DirAccess.make_dir_recursive_absolute(brush_thumbnails_path)
	DirAccess.make_dir_recursive_absolute(timeline_thumbnails_path)
	
	root_clip_res.set_children(curr_layers)
	
	update_curr_length_and_curr_spacial_frames()


# Media Clips
# ---------------------------------------------------

func get_media_clip(layer_index: int, frame_in: int) -> MediaClipRes:
	return curr_layers[layer_index].media_clips[frame_in]

func get_media_clips_min_layer_index_and_frame_in(clips_info: Array[Dictionary]) -> Vector2i:
	var layers_indeces: Array[int]
	var frames: Array[int]
	for info: Dictionary in clips_info:
		layers_indeces.append(info.layer_index)
		frames.append(info.clip_pos)
	return Vector2i(layers_indeces.min(), frames.min())

func get_media_clip_place_method() -> Callable:
	var method: Callable
	match EditorServer.time_line.media_clip_place_method:
		0: method = place_on_top_clip
		1: method = insert_clip
		2: method = overwrite_clip
		3: method = fit_to_fill_clip
		4: method = replace_clip
	return method

func loop_intersected_media_clips(layer_index: int, frame_in: int, media_res: MediaClipRes, method: Callable, info: Dictionary[StringName, Variant] = {}) -> Dictionary[StringName, Variant]:
	var frame_out: int = frame_in + media_res.length
	var media_clips: Dictionary = get_layer(layer_index).media_clips
	media_clips.sort()
	for other_frame_in: int in media_clips:
		var other_media_res: MediaClipRes = media_clips[other_frame_in]
		var other_frame_out: int = other_frame_in + other_media_res.length
		if not (other_frame_out <= frame_in or frame_out <= other_frame_in):
			method.call(other_frame_in, other_media_res, info)
	return info

func get_intersected_media_clips(layer_index: int, frame_in: int, media_res: MediaClipRes) -> Array[Dictionary]:
	return loop_intersected_media_clips(layer_index, frame_in, media_res, get_intersection_media_clip_method, {&"media_clips": [] as Array[Dictionary]}).media_clips

func get_intersection_media_clip_method(frame_in: int, media_res: MediaClipRes, info: Dictionary[StringName, Variant]) -> void:
	info.media_clips.append({&"frame_in": frame_in, &"clip_res": media_res})

func place_media_clip(layer_index: int, frame_in: int, media_res: MediaClipRes, place_method: Callable = Callable(), emit_changes: bool = false) -> void:
	if place_method.is_null():
		place_method = get_media_clip_place_method()
	place_method.call(layer_index, frame_in, media_res, emit_changes)

func place_on_top_clip(layer_index: int, frame_in: int, media_res: MediaClipRes, emit_changes: bool) -> void:
	var loop_times: int
	var target_layer_index: int
	while true:
		target_layer_index = layer_index + loop_times
		if is_layer_unoccupied(target_layer_index, frame_in, media_res.length):
			break
		elif loop_times <= layer_index:
			target_layer_index = layer_index - loop_times
			if is_layer_unoccupied(target_layer_index, frame_in, media_res.length):
				break
		loop_times += 1
	
	just_place_clip(target_layer_index, frame_in, media_res, emit_changes, 0)

func insert_clip(layer_index: int, frame_in: int, media_res: MediaClipRes, emit_changes: bool) -> void:
	var target_frame_in: int = frame_in
	var intersected_infos: Array[Dictionary] = get_intersected_media_clips(layer_index, frame_in, media_res)
	target_frame_in += just_get_insert_offset(frame_in, intersected_infos)
	
	if intersected_infos:
		var move_info: Array[Dictionary]
		var move_layers_indeces: Array
		var move_frames_indeces: Array
		
		var media_clips: Dictionary = get_layer(layer_index).media_clips
		var media_clips_keys: Array = media_clips.keys()
		var index_from: int = media_clips_keys.find(intersected_infos[0].frame_in)
		var index_to: int = media_clips.size()
		
		var curr_frame_end: int = target_frame_in + media_res.length
		for index: int in range(index_from, index_to):
			var _frame_in: int = media_clips_keys[index]
			var _media_res: MediaClipRes = media_clips.get(_frame_in)
			if curr_frame_end > _frame_in:
				var _target_frame_in: int = _frame_in + (curr_frame_end - _frame_in)
				move_info.append({"layer_index": layer_index, "clip_pos": _frame_in, "clip_res": _media_res})
				move_layers_indeces.append(layer_index)
				move_frames_indeces.append(_target_frame_in)
				curr_frame_end = _target_frame_in + _media_res.length
			else:
				break
		
		move_media_clips(move_info, move_layers_indeces, move_frames_indeces, place_on_top_clip, false, false)
	just_place_clip(layer_index, target_frame_in, media_res, emit_changes, 1)

func overwrite_clip(layer_index: int, frame_in: int, media_res: MediaClipRes, emit_changes: bool) -> void:
	var frame_out: int = frame_in + media_res.length
	
	var result: Dictionary[StringName, Variant] = loop_intersected_media_clips(layer_index, frame_in, media_res,
	func(_frame_in: int, _media_res: MediaClipRes, info: Dictionary[StringName, Variant]) -> void:
		var _frame_out: int = _frame_in + _media_res.length
		var frame_in_delta: int = frame_in - _frame_in
		var frame_out_delta: int = frame_out - _frame_out
		var cut_left: bool = frame_in_delta <= 0
		var cut_right: bool = frame_out_delta >= 0
		if cut_left and cut_right:
			info.removed_clips_info.append({"layer_index": layer_index, "clip_pos": _frame_in})
		else:
			var left_cut: int = frame_out - _frame_in
			var right_cut: int = _frame_out - frame_in
			var clip_info: Dictionary[String, Variant]
			if not cut_left and not cut_right:
				var splited_res: MediaClipRes = _media_res.duplicate_media_res()
				splited_res.from += left_cut
				splited_res.length = -frame_out_delta
				clip_info = {"frame_in": _frame_in, "length": _media_res.length - right_cut, "from": _media_res.from}
				just_place_clip(layer_index, frame_out, splited_res, false)
			
			elif cut_left: clip_info = {"frame_in": _frame_in + left_cut, "length": _media_res.length - left_cut, "from": _media_res.from + left_cut}
			else: clip_info = {"frame_in": _frame_in, "length": _media_res.length - right_cut, "from": _media_res.from}
			info.edited_frames_in.append(_frame_in)
			info.edited_clips_info.append(clip_info),
		{&"edited_frames_in": [], &"edited_clips_info": [], &"removed_clips_info": [] as Array[Dictionary]}
	)
	
	var frames_in: Array = result.edited_frames_in
	var edit_infos: Array = result.edited_clips_info
	for index: int in frames_in.size():
		edit_media_clip(layer_index, frames_in[index], edit_infos[index], [], false, false)
	remove_media_clips(result.removed_clips_info, false)
	just_place_clip(layer_index, frame_in, media_res, emit_changes, 1)

func fit_to_fill_clip(layer_index: int, frame_in: int, media_res: MediaClipRes, emit_changes: bool) -> void:
	var target_frame_in: int = frame_in
	var target_length: int
	
	var intersected_infos: Array[Dictionary] = get_intersected_media_clips(layer_index, frame_in, media_res)
	target_frame_in += just_get_insert_offset(frame_in, intersected_infos)
	
	if intersected_infos:
		target_length = intersected_infos[0].frame_in - target_frame_in
	else:
		var media_clips: Dictionary = get_layer_if(layer_index).media_clips
		for _frame_in: int in media_clips.keys():
			if _frame_in > target_frame_in:
				target_length = _frame_in - target_frame_in
				break
		if not target_length:
			target_length = get_start_and_end_frame()[1] - target_frame_in
	
	media_res.length = target_length
	just_place_clip(layer_index, target_frame_in, media_res, emit_changes)

func replace_clip(layer_index: int, frame_in: int, media_res: MediaClipRes, emit_changes: bool) -> void:
	var intersected_infos: Array[Dictionary] = get_intersected_media_clips(layer_index, frame_in, media_res)
	if intersected_infos:
		var first_info: Dictionary = intersected_infos[0]
		var _frame_in: int = first_info.frame_in
		if frame_in - first_info.frame_in > 0:
			var _media_res: MediaClipRes = first_info.clip_res
			
			frame_in = first_info.frame_in
			media_res.from = _media_res.from
			media_res.length = _media_res.length
			
			just_place_clip(layer_index, frame_in, media_res, emit_changes, 1)
		else: place_on_top_clip(layer_index, frame_in, media_res, emit_changes)
	else: place_on_top_clip(layer_index, frame_in, media_res, emit_changes)

func just_get_insert_offset(frame_in: int, intersected_infos: Array[Dictionary]) -> int:
	if intersected_infos:
		var first_info: Dictionary = intersected_infos[0]
		var frame_in_delta: int = frame_in - first_info.frame_in
		if frame_in_delta > 0:
			var frame_in_offset: int = first_info.clip_res.length - frame_in_delta
			intersected_infos.remove_at(0)
			return frame_in_offset # Return Move Offset
	return 0

func just_place_clip(layer_index: int, frame_in: int, media_res: MediaClipRes, emit_changes: bool, emit_method: int = 0) -> void:
	if not media_res.length:
		return
	curr_layers[layer_index].media_clips[frame_in] = media_res
	if emit_changes:
		match emit_method:
			0:
				media_clip_added.emit(layer_index, frame_in)
				emit_media_clips_change()
			1:
				update_curr_length_and_curr_spacial_frames()
				var layer: Layer = EditorServer.time_line.get_layer(layer_index)
				layer.displayed_media_clips_clear()
				layer.update(false)

func add_imported_clip(imported_type: int, key_as_path: StringName, layer_index: int = -1, frame_in: int = 0, emit_changes: bool = false) -> ImportedClipRes:
	var imported_clip_res: ImportedClipRes = ImportedClipRes.new()
	imported_clip_res.type = imported_type
	imported_clip_res.key_as_path = key_as_path
	
	var media_length: int = int(MediaServer.get_media_default_length(imported_type, key_as_path) * fps)
	add_media_clip(imported_clip_res, media_length, layer_index, frame_in, emit_changes)
	return imported_clip_res

func add_object_clip(object_res: ObjectRes, layer_index: int, frame_in: int, emit_changes: bool = false, force_layer_index: bool = false) -> ObjectClipRes:
	var object_clip_res: ObjectClipRes = ObjectClipRes.new()
	object_clip_res.object_res = object_res
	add_media_clip(object_clip_res, EditorServer.editor_settings.media_clip_default_length * fps, layer_index, frame_in, emit_changes, force_layer_index)
	return object_clip_res

func add_media_clip(media_res: MediaClipRes, media_length: int, layer_index: int, frame_in: int, emit_changes: bool = false, force_layer_index: bool = false) -> void:
	media_res.clip_pos = frame_in
	media_res.id = generate_clip_id()
	media_res.length = media_length
	
	layer_index = max(0, layer_index)
	if force_layer_index: just_place_clip(layer_index, frame_in, media_res, emit_changes, 0)
	else: place_media_clip(layer_index, frame_in, media_res, Callable(), emit_changes)
	
	update_scene_objects()

func copy_media_clips(clips_info: Array[Dictionary], cut: bool = false, emit_changes: bool = true) -> void:
	copied_media_clips = clips_info
	
	if cut:
		remove_media_clips(clips_info, false)
	
	if emit_changes:
		media_clips_copied.emit()
		request_delete_layers()

func past_media_clips(target_frames_in: Array, target_layers_indeces: Array = [-1], true_arrangement: bool = true, generate_new_id: bool = true, force_same_layer_index: bool = false, place_method: Callable = Callable(), emit_changes: bool = true) -> Dictionary[int, Dictionary]:
	
	if not copied_media_clips: return {}
	
	var pasted_layers: Dictionary[int, Dictionary]
	
	var displacement_frame: int
	if true_arrangement:
		displacement_frame = get_media_clips_min_layer_index_and_frame_in(copied_media_clips).y
	
	var layers_updated: Array[Layer]
	
	for index: int in copied_media_clips.size():
		
		var info: Dictionary = copied_media_clips[index]
		
		var from_layer_index: int = info.layer_index
		var from_frame_in: int = info.clip_pos
		var media_res: MediaClipRes
		
		media_res = info.clip_res.duplicate_media_res()
		
		var true_index: int = min(index, target_frames_in.size() - 1)
		var target_frame_in: int = target_frames_in[true_index]
		var target_layer_index: int = target_layers_indeces[true_index]
		var absolute_target_frame_in: int = (from_frame_in + target_frame_in - displacement_frame) if true_arrangement else target_frame_in
		var absolute_target_layer_index: int = from_layer_index if target_layer_index < 0 else target_layer_index
		
		if force_same_layer_index: just_place_clip(absolute_target_layer_index, absolute_target_frame_in, media_res, false)
		else: place_media_clip(absolute_target_layer_index, absolute_target_frame_in, media_res, place_method, false)
		
		if not pasted_layers.has(absolute_target_layer_index):
			pasted_layers[absolute_target_layer_index] = {}
		pasted_layers[absolute_target_layer_index][absolute_target_frame_in] = media_res
		media_res.clip_pos = absolute_target_frame_in
		
		var old_layer: Layer = EditorServer.time_line.get_layer(from_layer_index)
		var new_layer: Layer = EditorServer.time_line.get_layer(absolute_target_layer_index)
		var old_clip_panel: MediaServer.ClipPanel = old_layer.get_media_clip(from_frame_in).clip_panel
		if old_clip_panel.is_graph_editor_opened:
			new_layer.send_media_clip_expanded_graph_editors(target_frame_in, old_clip_panel.graph_editors_expanded)
			old_layer.request_remove_media_clip(from_frame_in)
		if not layers_updated.has(old_layer):
			layers_updated.append(old_layer)
	
	if emit_changes:
		media_clips_pasted.emit()
		request_delete_layers()
	
	for layer: Layer in layers_updated:
		layer.update()
	
	return pasted_layers

func edit_media_clip(layer_index: int, frame_in: int, edit_info: Dictionary[String, Variant], media_ignored: Array[MediaClipRes], force_layer_index: bool = false, emit_changes: bool = true) -> Dictionary:
	
	var target_layer_index: int = layer_index
	var target_frame_in: int = edit_info.frame_in
	var media_res: MediaClipRes = curr_layers[layer_index].media_clips[frame_in]
	
	remove_media_clips([{"layer_index": layer_index, "clip_pos": frame_in}], false)
	media_res.from = edit_info.from
	media_res.length = edit_info.length
	
	EditorServer.time_line.get_layer(target_layer_index).select_media_clip(target_frame_in)
	if not force_layer_index:
		target_layer_index = check_layer(layer_index, target_frame_in, edit_info.length, media_ignored)
	
	curr_layers[target_layer_index].media_clips[target_frame_in] = media_res
	media_res.clip_pos = target_frame_in
	
	if emit_changes:
		request_delete_layers()
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
	}, [])
	
	# Right Cut
	if right_side:
		var duplicated_layers: Dictionary[int, Dictionary] = duplicate_media_clips([{
			"layer_index": layer_index,
			"clip_pos": clip_pos,
			"clip_res": clip_res
		}], split_in, true)
		
		var absolute_layer: int = duplicated_layers.keys()[0]
		edit_media_clip(absolute_layer, split_in, {
			"frame_in": split_in,
			"from": local_frame + clip_res.from,
			"length": full_length - local_frame
		}, [])
	
	if not left_side:
		remove_media_clips([left_info], false)
	
	update_scene_objects()
	if emit_changes:
		emit_media_clips_change()

func duplicate_media_clips(clips_info: Array[Dictionary], target_frame_in: int, force_same_layer_index:= false) -> Dictionary[int, Dictionary]:
	copy_media_clips(clips_info, false, false)
	var pasted_layers: Dictionary[int, Dictionary] = past_media_clips([target_frame_in], [-1], true, true, force_same_layer_index, Callable(), false)
	media_clips_duplicated.emit()
	request_delete_layers()
	return pasted_layers

func move_media_clips(clips_info: Array[Dictionary], target_layers_indeces: Array, target_frames_in: Array, place_method: Callable = Callable(), emit_changes: bool = true, update_scene: bool = true) -> Dictionary[int, Dictionary]:
	for index: int in clips_info.size():
		var info: Dictionary = clips_info[index]
		var frame_in_delta: int = target_frames_in[index] - info.clip_pos
		var children: Dictionary[int, Dictionary] = info.clip_res.get_children()
		
		enter_media_clip_children(info.layer_index, info.clip_pos, false)
		var curr_clips_info: Array[Dictionary]
		var curr_target_layers_indeces: Array
		var curr_target_frames_in: Array
		for layer_index: int in children.keys():
			var media_clips: Dictionary = children[layer_index].media_clips
			for frame_in: int in media_clips:
				curr_clips_info.append({
					"layer_index": layer_index,
					"clip_pos": frame_in,
					"clip_res": media_clips[frame_in]
				})
				curr_target_layers_indeces.append(layer_index)
				curr_target_frames_in.append(frame_in + frame_in_delta)
		move_media_clips(curr_clips_info, curr_target_layers_indeces, curr_target_frames_in, place_on_top_clip, false, false)
		exit_media_clip_children(1, false)
	
	copy_media_clips(clips_info, true, false)
	var pasted_layers: Dictionary[int, Dictionary] = past_media_clips(target_frames_in, target_layers_indeces, false, false, false, place_method, false)
	
	if update_scene:
		update_scene_objects()
	if emit_changes:
		media_clips_moved.emit()
		request_delete_layers()
	return pasted_layers


func remove_media_clips(clips_info: Array[Dictionary], emit_changes: bool = true) -> void:
	for info: Dictionary in clips_info:
		var media_clips: Dictionary = curr_layers[info.layer_index].media_clips
		if media_clips.has(info.clip_pos):
			free_object(media_clips[info.clip_pos])
			media_clips.erase(info.clip_pos)
	
	if emit_changes:
		media_clips_removed.emit()
		request_delete_layers()

func enter_media_clip_children(layer_index: int, frame_in: int, emit_changes: bool = true) -> void:
	var media_res: MediaClipRes = get_media_clip(layer_index, frame_in)
	curr_layers_path.append({"layer": layer_index, "frame": frame_in, "res": media_res})
	update_curr_layers()
	if emit_changes:
		emit_curr_layers_change()
		media_clip_entered.emit(media_res)
		curr_layers_changed.emit()

func exit_media_clip_children(times: int, emit_changes: bool = true) -> void:
	if curr_layers_path.is_empty(): return
	curr_layers_path.resize(curr_layers_path.size() - times)
	update_curr_layers()
	if emit_changes:
		emit_curr_layers_change()
		media_clip_exited.emit(times)
		curr_layers_changed.emit()

func create_media_clips_parent(focused_clip_info: Dictionary, clips_info: Array[Dictionary], reset_offset: bool = false) -> void:
	
	var clip_pos: int = focused_clip_info.clip_pos
	var layer_index: int = focused_clip_info.layer_index
	
	remove_media_clips(clips_info, false)
	EditorServer.media_clips_selection_group.remove_object(focused_clip_info.clip_res.id)
	
	layer_index = check_layer(layer_index, clip_pos, focused_clip_info.clip_res.length)
	var empty_object_res:= Object2DRes.new()
	var parent_clip_res: ObjectClipRes = add_object_clip(empty_object_res, layer_index, clip_pos, false, true)
	layers_changed.emit()
	
	reparent_media_clips({
		"layer_index": layer_index,
		"clip_pos": clip_pos,
		"clip_res": parent_clip_res
	}, clips_info, reset_offset, false)

func reparent_media_clips(parent_clip_info: Dictionary, clips_info: Array[Dictionary], reset_offset: bool = false, auto_remove: bool = true) -> void:
	
	var parent_layer_index: int = parent_clip_info.layer_index
	var parent_clip_res: MediaClipRes = parent_clip_info.clip_res
	var parent_clip_pos: int = parent_clip_info.clip_pos
	
	if auto_remove:
		clips_info.erase(parent_clip_info)
		remove_media_clips(clips_info, false)
	
	enter_media_clip_children(parent_layer_index, parent_clip_pos, false)
	
	clips_info.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.layer_index < b.layer_index)
	
	var min_values: Vector2i = get_media_clips_min_layer_index_and_frame_in(clips_info)
	var layer_index_begin: int = min_values.x
	var frame_begin: int = min_values.y
	var frame_ends: Array[int]
	for index: int in clips_info.size():
		var info: Dictionary = clips_info[index]
		var clip_res: MediaClipRes = info.clip_res
		var target_clip_pos: int = parent_clip_pos + int(not reset_offset) * info.clip_pos - frame_begin
		var target_layer: int = check_layer(info.layer_index - layer_index_begin, target_clip_pos, clip_res.length)
		just_place_clip(target_layer, target_clip_pos, clip_res, false)
		curr_layers[target_layer].media_clips[target_clip_pos] = clip_res
		clip_res.clip_pos = target_clip_pos
		frame_ends.append(target_clip_pos + clip_res.length)
	
	exit_media_clip_children(1, false)
	
	var parent_target_length: int = MediaServer.get_media_default_from_and_length(parent_clip_res, 0, frame_ends.max() - parent_clip_pos).y
	var parent_target_layer_index: int = check_layer(parent_layer_index, parent_clip_pos, parent_target_length, [parent_clip_res])
	parent_clip_res.length = parent_target_length
	move_media_clips([parent_clip_info], [parent_target_layer_index], [parent_clip_pos], place_on_top_clip)
	EditorServer.time_line.get_layer(parent_target_layer_index).on_layers_changed()
	media_clips_changed.emit()

func parent_up_media_clips(clips_info: Array[Dictionary], times: int = 1) -> void:
	var parent_clip_pos: int = curr_layers_path.back().frame
	copy_media_clips(clips_info, true, false)
	exit_media_clip_children(times)
	past_media_clips([parent_clip_pos])

func clear_media_clips_parents(clips_info: Array[Dictionary]) -> void:
	parent_up_media_clips(clips_info, curr_layers_path.size())

func update_curr_layers() -> void:
	if curr_layers_path.is_empty(): curr_layers = root_layers
	else: curr_layers = curr_layers_path.back().res.get_children()

func emit_curr_layers_change() -> void:
	curr_layers_string_path.clear()
	
	for info: Dictionary in curr_layers_path:
		var media_res: MediaClipRes = info.res
		var media_name: String = media_res.get_display_name()
		curr_layers_string_path.append(media_name)
	
	update_curr_length_and_curr_spacial_frames()

func emit_media_clips_change() -> void:
	update_curr_length_and_curr_spacial_frames()
	EditorServer.time_line.queue_redraw()
	EditorServer.player.update_ui()
	curr_layers.sort()
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

func delete_layer(layer_index: int, emit_changes: bool = true) -> void:
	clear_layer_media_clips(layer_index)
	
	var max_layer_index: int = curr_layers.keys().max()
	move_layers(layer_index + 1, max_layer_index + 1, -1, false)
	curr_layers.erase(max_layer_index)
	
	if emit_changes:
		layer_removed.emit()
		await get_tree().process_frame
		layers_changed.emit()
		emit_media_clips_change()
		update_scene_objects()

func request_delete_layers() -> void:
	var layers_indeces: PackedInt32Array
	var curr_indeces: Array[int]
	var layers_indeces_packages: Array[Array]
	var move_layers_steps: int
	
	var curr_layers_keys: Array[int] = curr_layers.keys()
	var curr_layers_size: int = curr_layers.size()
	
	for index: int in curr_layers_size:
		var layer_index: int = curr_layers_keys[index]
		var cond1: bool = layer_index + 1 > EditorServer.time_line.max_layers_count
		var cond2: bool = curr_layers[layer_index].media_clips.is_empty()
		if cond1 and cond2: layers_indeces.append(index)
	
	for layer_index: int in layers_indeces:
		if not curr_indeces.is_empty() and not layer_index - 1 == curr_indeces.back():
			layers_indeces_packages.append(curr_indeces)
			curr_indeces = []
		curr_indeces.append(layer_index)
	if curr_indeces:
		layers_indeces_packages.append(curr_indeces)
	
	for time: int in layers_indeces_packages.size() - 1:
		var indeces1: Array[int] = layers_indeces_packages[time]
		var indeces2: Array[int] = layers_indeces_packages[time + 1]
		move_layers_steps += indeces1.size()
		move_layers(indeces1.back() + 1, indeces2.front(), -move_layers_steps, false)
	if layers_indeces_packages.size():
		var last_indeces: Array = layers_indeces_packages.back()
		var max_layer_index: int = curr_layers.keys().max()
		move_layers_steps += last_indeces.size()
		move_layers(last_indeces.back() + 1, max_layer_index + 1, -move_layers_steps, false)
		var erase_range: Array = range(0, move_layers_steps)
		erase_range.reverse()
		for time: int in erase_range:
			curr_layers.erase(max_layer_index - time)
	
	layers_removed.emit(move_layers_steps)
	await get_tree().process_frame
	emit_media_clips_change()
	update_scene_objects()

func clear_layer(layer_index: int) -> void:
	curr_layers[layer_index] = get_default_layer()

func clear_layer_media_clips(layer_index: int) -> void:
	for media_res: MediaClipRes in curr_layers[layer_index].media_clips.values():
		free_object(media_res)
	curr_layers[layer_index].media_clips = {}

func replace_layer(index_from: int, index_to: int) -> void:
	curr_layers[index_to] = root_layers[index_from]
	clear_layer(index_from)

func move_layers(from: int, to: int, steps: int, emit_changes: bool = true) -> void:
	var indeces_range: Array = range(from, to)
	if steps > 0: indeces_range.reverse()
	for index: int in indeces_range:
		replace_layer(index, index + steps)
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

func set_layer_customization(layer_index: int, name: StringName, color: Color, size: int) -> void:
	get_layer(layer_index)["customization"] = {
		&"name": name, &"color": color, &"size": size
	} as Dictionary[StringName, Variant]

func get_layer_customization(layer_index: int) -> Dictionary[StringName, Variant]:
	return get_layer(layer_index).customization

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

func check_layer(layer_index: int, frame_in: int, media_length: int, media_ignored: Array[MediaClipRes] = []) -> int:
	if layer_index < 0 or not is_layer_unoccupied(layer_index, frame_in, media_length):
		layer_index = get_best_unoccupied_layer(frame_in, media_length, media_ignored)
	return layer_index

func get_best_unoccupied_layer(frame_in: int, media_length: int, media_ignored: Array[MediaClipRes]) -> int:
	var layer_index: int = 0
	while true:
		if is_layer_unoccupied(layer_index, frame_in, media_length, media_ignored):
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

func update_scene_objects(curr_frame: int = -1) -> void:
	if curr_frame < 0: curr_frame = EditorServer.frame
	update_media_res_children(root_clip_res, curr_frame)

func update_media_res_children(parent_res: MediaClipRes, curr_frame: int, root_layer_index: int = -1) -> void:
	var children: Dictionary[int, Dictionary] = parent_res.get_children()
	var curr_clips: Dictionary[int, int] = parent_res.get_curr_clips()
	var new_clips: Dictionary[int, int]
	
	for layer_index: int in children.keys():
		var media_clips: Dictionary = children[layer_index].media_clips
		for time_begin: int in media_clips.keys():
			var media_res: MediaClipRes = media_clips.get(time_begin)
			if is_frame_on_media(curr_frame, time_begin, media_res.length):
				new_clips[layer_index] = time_begin
				break
	
	var removed_clips: Dictionary[int, int]
	var added_clips: Dictionary[int, int]
	
	for index: int in curr_clips.keys():
		if not children.has(index):
			continue
		var curr_clip_id: int = curr_clips[index]
		if new_clips.has(index) and curr_clip_id == new_clips[index]:
			continue
		removed_clips[index] = curr_clip_id
		var media_clips: Dictionary = children[index].media_clips
		if media_clips.has(curr_clip_id):
			free_object(media_clips[curr_clip_id])
	
	for index: int in new_clips.keys():
		var new_clip_id: int = new_clips[index]
		var media_res: MediaClipRes = parent_res.children[index].media_clips[new_clip_id]
		
		if root_layer_index == -1: root_layer_index = index
		
		if curr_clips.has(index) and new_clip_id == curr_clips[index]: pass
		else: instance_object(parent_res, media_res, index, new_clip_id, root_layer_index)
		
		media_res.process(curr_frame - new_clip_id)
		update_media_res_children(media_res, curr_frame, root_layer_index)
		added_clips[index] = new_clip_id
	
	parent_res.set_curr_clips(new_clips)

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var object: Node
	var instantiate_func: Callable
	
	if media_res is ImportedClipRes:
		var media_res_path: String = media_res.key_as_path
		var media_type: int = media_res.type
		match media_type:
			0: instantiate_func = Scene2.instance_sprite
			1: instantiate_func = Scene2.instance_video_viewer
			2: instantiate_func = Scene2.instance_audio_stream_player
	
	elif media_res is ObjectClipRes:
		instantiate_func = media_res.object_res.instance_object
	
	object = instantiate_func.call(parent_res, media_res, layer_index, frame_in, root_layer_index)
	
	media_res.enter(object)
	return object

func free_object(media_res: MediaClipRes) -> void:
	var object: Node = Scene2.get_object(media_res)
	if object:
		media_res.exit(object)
		Scene2.free_object(media_res)

func generate_clip_id(id_length: int = 12) -> String:
	return generate_new_id([], id_length)

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

func append_spacial_frame(pos: int) -> void:
	curr_spacial_frames.append(pos)

func erase_spacial_frame(pos: int) -> void:
	curr_spacial_frames.erase(pos)

func update_curr_length_and_curr_spacial_frames() -> void:
	var clips_result:= loop_media_clips({"length_needed": 0 as int, "new_frame_poss": [] as Array[int]},
		func(l: int, f: int, m: MediaClipRes, i: Dictionary[StringName, Variant]) -> void:
			var curr_result_needed: int = f + m.length
			if curr_result_needed > i.length_needed:
				i.length_needed = curr_result_needed
			i.new_frame_poss.append(curr_result_needed)
			i.new_frame_poss.append(f)
	)
	
	var clips_keyframes_result:= loop_layers({"new_frame_poss": [] as Array[int]},
		func(layer_index: int, layer_port: Dictionary, info: Dictionary) -> void:
			var layer: Variant = EditorServer.time_line.get_layer(layer_index)
			if layer is not Layer: return
			var displayed_clips: Dictionary[int, Dictionary] = layer.displayed_media_clips
			for frame_in: int in displayed_clips.keys():
				var clip_info: Dictionary = displayed_clips[frame_in]
				var clip: MediaClip = clip_info.clip
				var from: int = clip.clip_res.from
				if clip.focus_panel.visible:
					for key: int in clip.focus_panel.displayed_keys:
						info.new_frame_poss.append(key + frame_in - from))
	
	var start_and_end: Array[int] = get_start_and_end_frame()
	
	curr_length = max(default_length, clips_result.length_needed)
	curr_spacial_frames = start_and_end + clips_result.new_frame_poss + clips_keyframes_result.new_frame_poss + time_markers.keys()


# Generating
# ---------------------------------------------------

func generate_new_id(used_id: PackedStringArray, id_length: int = 12, append_new_id: bool = false) -> String:
	var id_keys: String = "_abcdefghijklmnopqrstuvwxyz"
	var keys_length: int = id_keys.length() - 1
	
	var result_id: String
	
	while not result_id or result_id in used_id:
		result_id = ""
		for time in id_length:
			result_id += id_keys[randi_range(0, keys_length)]
	
	if append_new_id:
		used_id.append(result_id)
	
	return result_id


