@abstract class_name MediaClipRes extends UsableRes

signal processed(frame: int)

signal comp_animation_res_added(comp: ComponentRes, usable_res: UsableRes, property_key: StringName, animation_res: AnimationRes)
signal comp_animation_res_removed(comp: ComponentRes, usable_res: UsableRes, property_key: StringName)
signal comp_keyframe_added(comp: ComponentRes, usable_res: UsableRes, prop_key: StringName, prop_val: Variant, frame: int)
signal comp_keyframe_removed(comp: ComponentRes, usable_res: UsableRes, prop_key: StringName, frame: int)

signal layer_added(layer_idx: int, layer: LayerRes)
signal layer_removed(layer_idx: int, layer: LayerRes)
signal layer_moved(from_idx: int, to_idx: int, layer: LayerRes)

signal clips_added(clips: Dictionary[Vector2i, MediaClipRes])
signal clips_removed(coords: Array[Vector2i])
signal clips_moved(from_coords: Array[Vector2i], to: Dictionary[Vector2i, MediaClipRes])
signal clips_updated(coords: Array[Vector2i])

@export var id: String

@export var from: int = 0:
	set(val):
		if GlobalServer.is_global_cache_loaded:
			from = max(get_min_from(), val)
			update()
		else:
			from = val

@export var length: int = 10:
	set(val):
		if GlobalServer.is_global_cache_loaded:
			length = clamp(val, 1, get_max_length() - from)
			update()
		else:
			length = val

@export var layers: Array[LayerRes]
@export var components: Dictionary[String, Array]

var curr_clips: Dictionary[int, int] = {}

var stacked_values: Dictionary[StringName, Array]

var curr_node: Node
var curr_frame: int:
	get():
		var result: int
		if curr_frame == -1:
			var global_frame: int = EditorServer.get_frame()
			result = clamp(global_frame - clip_pos, 0, length)
		else:
			result = curr_frame
		return result

var shared_data: Dictionary

var layer_index: int
var clip_pos: int


static func get_explorer_section() -> StringName: return &"Object"
static func get_properties_section() -> StringName: return &""

func get_display_name() -> String: return get_classname()
func get_thumbnail() -> Texture2D: return ClassServer.media_clip_classes[get_script().get_global_name()].icon

static func get_media_clip_info() -> Dictionary[StringName, String]: return {}
static func is_media_clip_spawnable() -> bool: return true

func get_min_from() -> float: return -INF
func get_max_length() -> float: return +INF
func get_minmax() -> Vector2: return Vector2(-get_min_from(), get_max_length())


func emit_res_changed() -> void:
	update()

func is_frame_exists(frame: Variant = null) -> bool:
	if frame == null: frame = curr_frame
	return frame >= 0 and frame <= length

func get_frame_or_curr_frame(frame: Variant = null) -> int:
	return curr_frame + from if frame == null else frame

func has_clips() -> bool:
	for layer_res: LayerRes in layers:
		if layer_res.clips:
			return true
	return false

func get_curr_clips() -> Dictionary[int, int]:
	return curr_clips

func set_curr_clips(_curr_clips: Dictionary[int, int]) -> void:
	curr_clips = _curr_clips

func get_components() -> Dictionary[String, Array]:
	return components

func set_components(_components: Dictionary[String, Array]) -> void:
	components = _components

func get_curr_frame() -> int: return curr_frame
func set_curr_frame(new_frame: int) -> void: curr_frame = new_frame

func get_curr_node() -> Node: return curr_node
func set_curr_node(new_node: Node) -> void: curr_node = new_node

func call_node_method_if(method_name: StringName, args: Array = []) -> void:
	if curr_node: curr_node.callv(method_name, args)

func duplicate_media_res() -> MediaClipRes:
	var duplicated: MediaClipRes = duplicate()
	
	# Duplicate Components
	var new_components: Dictionary[String, Array]
	
	for section_key: String in components:
		
		var curr_section_comp: Array = components.get(section_key)
		var new_section_comp: Array[ComponentRes]
		
		for curr_component: ComponentRes in curr_section_comp:
			var new_component: ComponentRes = curr_component.duplicate_component_res()
			new_component.set_owner(duplicated)
			new_component.properties = new_component.properties.duplicate(true)
			new_section_comp.append(new_component)
		
		new_components[section_key] = new_section_comp
	
	duplicated.components = new_components
	
	# Duplicate Layers
	var dupl_layers: Array[LayerRes] = []
	
	for layer: LayerRes in layers:
		dupl_layers.append(layer.duplicate_layer_res())
	
	duplicated.layers = dupl_layers
	duplicated.emit_res_changed()
	
	# Return New One
	return duplicated

func get_section_comps_absolute(section_key: String) -> Array:
	return components.get_or_add(section_key, [])

func add_component(section_key: String, component: ComponentRes, forced: bool = false) -> void:
	get_section_comps_absolute(section_key).append(component)
	component.set_owner(self)
	component.set_forced(forced)
	emit_res_changed()
	
	if curr_node:
		component._enter()
		process_here()

func erase_component(section_key: String, component: ComponentRes) -> void:
	get_section_comps_absolute(section_key).erase(component)
	emit_res_changed()
	if curr_node:
		component._delete()
		process_here()

func remove_component(section_key: String, component_id: StringName) -> void:
	for component: ComponentRes in get_section_comps_absolute(section_key):
		if component.get_classname() == component_id:
			erase_component(section_key, component)
			return

func move_component(section_key: String, index_from: int, index_to: int) -> void:
	
	var section: Array = get_section_comps_absolute(section_key)
	var section_size:= section.size()
	
	if index_from < 0 or index_from >= section_size: return
	if index_to < 0 or index_to >= section_size: return
	if section[index_to].forced: return
	
	var component: ComponentRes = section[index_from]
	section.remove_at(index_from)
	section.insert(index_to, component)
	
	emit_res_changed()
	process(curr_frame)

func loop_components(method: Callable, args: Array = []) -> void:
	for section_key: String in components:
		var section_components: Array = components[section_key]
		for component: ComponentRes in section_components:
			if component.enabled:
				method.callv([component] + args)

func loop_components_animations_keys(info: Dictionary[StringName, Variant], method: Callable) -> Dictionary[StringName, Variant]:
	for section_key: String in components:
		var section_comps: Array = components[section_key]
		
		for comp_res: ComponentRes in section_comps:
			
			var anims: Dictionary[UsableRes, Dictionary] = comp_res.animations
			
			for usable_res: UsableRes in anims:
				var res_anims: Dictionary = anims[usable_res]
				
				for anim_key: String in res_anims:
					var anim_res: AnimationRes = res_anims[anim_key]
					
					for channel_index: int in anim_res.profiles.size():
						var channel_profile: CurveProfile = anim_res.profiles[channel_index]
						var anim_keys: Dictionary[int, CurveKey] = channel_profile.keys
						
						for key_pos: int in anim_keys:
							method.call(
								anim_key,
								key_pos,
								anim_keys[key_pos],
								info
							)
	return info

func wait_until_media_res_processed(media_res: MediaClipRes) -> int:
	if media_res.layer_index > layer_index:
		return await media_res.processed
	return -1

func init_node(layer_idx: int, frame: int) -> Node:
	return null

func enter(node: Node) -> void:
	curr_node = node
	loop_components(enter_component)

func process(frame: int) -> void:
	_before_process_comps(frame)
	_process_comps(frame)
	_after_process_comps(frame)

func _before_process_comps(frame: int) -> void:
	curr_frame = frame
	clear_stacked_values()

func _process_comps(frame: int) -> void:
	var loop_args: Array = [frame]
	loop_components(process_component, loop_args)
	loop_components(postprocess_component, loop_args)

func _after_process_comps(frame: int) -> void:
	loop_stacked_values(curr_node.set)
	processed.emit(frame)

func process_here() -> void:
	process(curr_frame)

func exit(node: Node) -> void:
	curr_frame = -1
	loop_components(exit_component)
	shared_data_clear()
	curr_node = null

func return_custom_stacked_values_at(frame: int) -> Dictionary[StringName, Array]:
	var custom_dict: Dictionary[StringName, Array] = {}
	for section_key: String in components:
		var section_components: Array = components[section_key]
		for component: ComponentRes in section_components:
			component._apply_custom_stacked_values(frame, custom_dict)
	return custom_dict

func update() -> void:
	if curr_node:
		process_here()

func enter_component(component: ComponentRes) -> void:
	component._enter()

func process_component(component: ComponentRes, frame: int) -> void:
	component.push_animations_result(frame)
	component._process(frame)

func postprocess_component(component: ComponentRes, frame: int) -> void:
	component._postprocess(frame)

func exit_component(component: ComponentRes) -> void:
	component._exit()

func update_component(component: ComponentRes, frame: int) -> void:
	component._update()


func clear_stacked_values() -> void:
	stacked_values.clear()

func add_stacked_value(key: StringName, value: Variant, method: ComponentRes.MethodType = MethodType.SET) -> void:
	stacked_values.get_or_add(key, []).append([value, method])

func remove_stacked_value(key: StringName, index: int) -> void:
	stacked_values.get_or_add(key, []).remove_at(index)

func get_stacked_values_key_result(key: StringName) -> Variant:
	return get_custom_stacked_values_key_result(stacked_values, key)

func loop_stacked_values(method: Callable) -> void:
	loop_custom_stacked_values(stacked_values, method)

func get_custom_stacked_values_key_result(stacked_values: Dictionary[StringName, Array], key: StringName) -> Variant:
	var key_stacked_values: Array = stacked_values.get(key)
	var result: Variant = key_stacked_values[0][0]
	
	for index: int in range(1, key_stacked_values.size()):
		var stacked_info: Array = key_stacked_values[index]
		var val: Variant = stacked_info[0]
		match stacked_info[1]:
			0: result = val
			1: result += val
			2: result -= val
			3: result *= val
			4: result /= val
	
	return result

func loop_custom_stacked_values(stacked_values: Dictionary[StringName, Array], method: Callable) -> void:
	for key: StringName in stacked_values:
		var key_result: Variant = get_custom_stacked_values_key_result(stacked_values, key)
		method.call(key, key_result)


func shared_data_add(key: StringName, val: Variant) -> void:
	shared_data.set(key, val)

func shared_data_get(key: StringName) -> Variant:
	return shared_data.get(key)

func shared_data_get_or_call(key: StringName, val_func: Callable) -> Variant:
	if shared_data.has(key):
		return shared_data.get(key)
	else:
		var val: Variant = val_func.call()
		shared_data.set(key, val)
		return val

func shared_data_get_stacked_at(frame: int) -> Dictionary[StringName, Array]:
	return shared_data_get_or_call(&"stacked%s" % str(frame), return_custom_stacked_values_at.bind(frame))

func shared_data_delete(key: StringName) -> bool:
	return shared_data.erase(key)

func shared_data_clear() -> void:
	shared_data.clear()


# old system
#func loop_children_deep(info: Dictionary[StringName, Variant], media_res_method: Callable, media_ress_pre_method: Callable = Callable(), media_ress_post_method: Callable = Callable()) -> void:
	#var dupl_info: Dictionary[StringName, Variant] = info.duplicate(true)
	#var pre_valid: bool = media_ress_pre_method.is_valid()
	#var post_valid: bool = media_ress_post_method.is_valid()
	#for layer_index: int in children:
		#var media_ress: Dictionary = children[layer_index].media_clips
		#if pre_valid: media_ress_pre_method.call(children, layer_index, dupl_info)
		#for frame: int in media_ress:
			#media_res_method.call(children, layer_index, frame, dupl_info)
			#media_ress[frame].loop_children_deep(info, media_res_method, media_ress_pre_method, media_ress_post_method)
		#if post_valid: media_ress_post_method.call(children, layer_index, dupl_info)

# old system
#func move_children_deep(offset: int) -> void:
	#loop_children_deep(
		#{&"media_ress": {} as Dictionary[int, Dictionary]},
		#func(children: Dictionary[int, Dictionary], layer_index: int, frame: int, info: Dictionary[StringName, Variant]) -> void:
			#info.media_ress[layer_index][frame + offset] = children[layer_index].media_clips[frame],
		#func(children: Dictionary[int, Dictionary], layer_index: int, info: Dictionary[StringName, Variant]) -> void:
			#info.media_ress[layer_index] = {},
		#func(children: Dictionary[int, Dictionary], layer_index: int, info: Dictionary[StringName, Variant]) -> void:
			#children[layer_index].media_clips = info.media_ress[layer_index]
	#)

# old system
#func check_children_for_paths_deep(paths_for_check: PackedStringArray) -> PackedStringArray:
	#var result: PackedStringArray
	#
	#for layer_index: int in children:
		#var media_ress: Dictionary = children[layer_index].media_clips
		#
		#for frame: int in media_ress:
			#
			#var media_res: MediaClipRes = media_ress[frame]
			#if media_res is ImportedClipRes:
				#if not paths_for_check.has(media_res.key_as_path):
					#result.append(media_res.key_as_path)
			#result.append_array(media_res.check_children_for_paths_deep(paths_for_check))
	#
	#return result

# old system
#func format_children_paths_deep(paths_for_format: Dictionary[String, String]) -> void:
	#loop_children_deep({},
		#func(children: Dictionary[int, Dictionary], layer_index: int, frame: int, info: Dictionary[StringName, Variant]) -> void:
			#var child_res: MediaClipRes = children[layer_index].media_clips[frame]
			#child_res.format_path(paths_for_format)
	#)

# old system
#func format_path(paths_for_format: Dictionary[String, String]) -> void:
	#pass


func _new_layer() -> LayerRes:
	return LayerRes.new()

func get_layer(idx: int) -> LayerRes:
	return layers[idx]

func get_layer_absolute(idx: int) -> LayerRes:
	return get_layer(idx) if layers.size() - 1 >= idx else add_layer(idx)

func add_layer(idx: int = 0) -> LayerRes:
	idx = min(idx, layers.size())
	var layer: LayerRes = _new_layer()
	layers.insert(idx, layer)
	layer_added.emit(idx, layer)
	return layer

func remove_layer(idx: int) -> LayerRes:
	var layer: LayerRes = layers[idx]
	layers.remove_at(idx)
	layer_removed.emit(idx, layer)
	return layer

func move_layer(from_idx: int, to_idx: int) -> void:
	var layer: LayerRes = layers[from_idx]
	layers.erase(layer)
	layers.insert(to_idx, layer)
	layer_moved.emit(from_idx, to_idx, layer)

func get_clip_place_method(method_idx: int) -> Callable:
	var method: Callable
	match method_idx:
		-1: method = just_place_clip
		0: method = place_on_top_clip
		1: method = insert_clip
		2: method = overwrite_clip
		3: method = fit_to_fill_clip
		4: method = replace_clip
	return method

func loop_intersected_media_clips(layer_idx: int, frame: int, clip_res: MediaClipRes, method: Callable, info: Dictionary[StringName, Variant] = {}) -> Dictionary[StringName, Variant]:
	
	var frame_out: int = frame + clip_res.length
	var clips: Dictionary[int, MediaClipRes] = get_layer(layer_idx).clips
	
	clips.sort()
	
	for other_frame: int in clips:
		var other_media_res: MediaClipRes = clips[other_frame]
		var other_frame_out: int = other_frame + other_media_res.length
		if not (other_frame_out <= frame or frame_out <= other_frame):
			method.call(other_frame, other_media_res, info)
	
	return info


func get_intersected_media_clips(layer_idx: int, frame: int, clip_res: MediaClipRes) -> Array[Dictionary]:
	return loop_intersected_media_clips(layer_idx, frame, clip_res, add_intersected_clip_func, {&"clips": [] as Array[Dictionary]}).clips

func add_intersected_clip_func(frame: int, clip_res: MediaClipRes, info: Dictionary[StringName, Variant]) -> void:
	info.clips.append({&"frame": frame, &"clip_res": clip_res})

func place_clip(layer_idx: int, frame: int, clip_res: MediaClipRes, place_method_idx: int) -> Vector2i:
	return get_clip_place_method(place_method_idx).call(layer_idx, frame, clip_res)

func place_on_top_clip(layer_idx: int, frame: int, clip_res: MediaClipRes) -> Vector2i:
	var loop_times: int
	var target_layer_idx: int
	
	while true:
		target_layer_idx = layer_idx + loop_times
		if get_layer_absolute(target_layer_idx).is_place_unoccupied(frame, clip_res.length):
			break
		elif loop_times <= layer_idx:
			target_layer_idx = layer_idx - loop_times
			if get_layer_absolute(target_layer_idx).is_place_unoccupied(frame, clip_res.length):
				break
		loop_times += 1
	
	return just_place_clip(target_layer_idx, frame, clip_res)

func insert_clip(layer_index: int, frame: int, clip_res: MediaClipRes) -> Vector2i:
	var target_frame: int = frame
	var intersected_infos: Array[Dictionary] = get_intersected_media_clips(layer_index, frame, clip_res)
	target_frame += just_get_insert_offset(frame, intersected_infos)
	intersected_infos = get_intersected_media_clips(layer_index, target_frame, clip_res)
	
	if intersected_infos:
		
		var clips: Dictionary[int, MediaClipRes] = get_layer_absolute(layer_index).clips
		var frames: Array[int] = clips.keys()
		
		var from_coords: Array[Vector2i]
		var to_coords: Array[Vector2i]
		
		var idx_from: int = frames.find(intersected_infos[0].frame)
		
		var end: int = target_frame + clip_res.length
		
		for idx: int in range(idx_from, clips.size()):
			
			var other_frame: int = frames[idx]
			var other_clip_res: MediaClipRes = clips[other_frame]
			
			if end > other_frame:
				from_coords.append(Vector2i(layer_index, other_frame))
				to_coords.append(Vector2i(layer_index, end))
				end += other_clip_res.length
			else:
				break
		
		move_clips(from_coords, to_coords, -1)
	
	return just_place_clip(layer_index, target_frame, clip_res)

func overwrite_clip(layer_index: int, frame: int, clip_res: MediaClipRes) -> Vector2i:
	var frame_out: int = frame + clip_res.length
	
	var result: Dictionary[StringName, Variant] = loop_intersected_media_clips(layer_index, frame, clip_res,
	func(_frame: int, _clip_res: MediaClipRes, info: Dictionary[StringName, Variant]) -> void:
		
		var coords: Vector2i = Vector2i(layer_index, _frame)
		
		var _frame_out: int = _frame + _clip_res.length
		var frame_delta: int = frame - _frame
		var frame_out_delta: int = frame_out - _frame_out
		var cut_left: bool = frame_delta <= 0
		var cut_right: bool = frame_out_delta >= 0
		
		if cut_left and cut_right:
			info.fordelete.append(Vector2i(layer_index, _frame))
		else:
			var left_cut: int = frame_out - _frame
			var right_cut: int = _frame_out - frame
			
			if not cut_left and not cut_right:
				
				var splited_res: MediaClipRes = _clip_res.duplicate_media_res()
				splited_res.from += left_cut
				splited_res.length = -frame_out_delta
				
				_clip_res.length -= right_cut
				
				info.foradd[Vector2i(layer_index, frame_out)] = splited_res
				info.forupdate.append(coords)
			
			elif cut_left:
				_clip_res.length -= left_cut
				_clip_res.from += left_cut
				info.formove.append(coords)
				info.moveto.append(Vector2i(layer_index, frame_out))
			
			else:
				_clip_res.length -= right_cut
				info.forupdate.append(coords),
		
		{
			&"foradd": {} as Dictionary[Vector2i, MediaClipRes],
			&"fordelete": [] as Array[Vector2i],
			&"formove": [] as Array[Vector2i],
			&"moveto": [] as Array[Vector2i],
			&"forupdate": [] as Array[Vector2i]
		}
	)
	
	add_clips_by_coords(result.foradd, -1)
	remove_clips(result.fordelete)
	move_clips(result.formove, result.moveto, -1)
	clips_updated.emit(result.forupdate)
	
	return just_place_clip(layer_index, frame, clip_res)

func fit_to_fill_clip(layer_index: int, frame: int, clip_res: MediaClipRes) -> Vector2i:
	var intersected_infos: Array[Dictionary] = get_intersected_media_clips(layer_index, frame, clip_res)
	
	var target_frame: int = frame + just_get_insert_offset(frame, intersected_infos)
	var target_length: int
	
	var clips: Dictionary[int, MediaClipRes] = get_layer_absolute(layer_index).clips
	
	for other_frame: int in clips:
		if other_frame > target_frame:
			target_length = other_frame - target_frame
			break
	
	if target_length == 0:
		target_length = length - target_frame
	
	clip_res.length = target_length
	
	return just_place_clip(layer_index, target_frame, clip_res)

func replace_clip(layer_index: int, frame: int, clip_res: MediaClipRes) -> Vector2i:
	
	var intersected_infos: Array[Dictionary] = get_intersected_media_clips(layer_index, frame, clip_res)
	
	if intersected_infos:
		
		var first_info: Dictionary = intersected_infos[0]
		var _frame: int = first_info.frame
		
		if frame - _frame >= 0:
			var _clip_res: MediaClipRes = first_info.clip_res
			
			frame = first_info.frame
			clip_res.from = _clip_res.from
			clip_res.length = _clip_res.length
			
			return just_place_clip(layer_index, frame, clip_res)
	
	return place_on_top_clip(layer_index, frame, clip_res)

func just_place_clip(layer_idx: int, frame: int, clip_res: MediaClipRes) -> Vector2i:
	if not clip_res.length:
		return Vector2i.ZERO
	clip_res.layer_index = layer_idx
	clip_res.clip_pos = frame
	get_layer_absolute(layer_idx).add_clip_res(frame, clip_res)
	return Vector2i(layer_idx, frame)

func just_get_insert_offset(frame: int, intersected_infos: Array[Dictionary]) -> int:
	if intersected_infos:
		var first_info: Dictionary = intersected_infos[0]
		var frame_delta: int = frame - first_info.frame
		if frame_delta > 0:
			var frame_offset: int = first_info.clip_res.length - frame_delta
			intersected_infos.remove_at(0)
			return frame_offset
	return 0


func add_clips(layer_idx: int, frame: int, clips_ress: Array[MediaClipRes], place_method_idx: int = 0, emit_add: bool = true) -> Dictionary[Vector2i, MediaClipRes]:
	var placed_clips_ress: Dictionary[Vector2i, MediaClipRes]
	for clip_res: MediaClipRes in clips_ress:
		placed_clips_ress[place_clip(layer_idx, frame, clip_res, place_method_idx)] = clip_res
	if emit_add:
		clips_added.emit(placed_clips_ress)
	return placed_clips_ress

func add_clips_by_coords(clips_ress: Dictionary[Vector2i, MediaClipRes], place_method_idx: int = 0, emit_add: bool = true) -> Dictionary[Vector2i, MediaClipRes]:
	var placed_clips_ress: Dictionary[Vector2i, MediaClipRes]
	for coord: Vector2i in clips_ress:
		var clip_res: MediaClipRes = clips_ress[coord]
		placed_clips_ress[place_clip(coord.x, coord.y, clip_res, place_method_idx)] = clip_res
	if emit_add:
		clips_added.emit(placed_clips_ress)
	return placed_clips_ress

func remove_clips(coords: Array[Vector2i], emit_remove: bool = true) -> void:
	for coord: Vector2i in coords:
		get_layer(coord.x).remove_clip_res(coord.y)
	if emit_remove:
		clips_removed.emit(coords)

func move_clips(from_coords: Array[Vector2i], to_coords: Array[Vector2i], place_method_idx: int, emit_move: bool = true) -> Dictionary[Vector2i, MediaClipRes]:
	
	var placed_clips_ress: Dictionary[Vector2i, MediaClipRes]
	
	for idx: int in range(from_coords.size() - 1, -1, -1):
		
		var from: Vector2i = from_coords[idx]
		var to: Vector2i = to_coords[idx]
		
		var from_layer: LayerRes = get_layer(from.x)
		var clip_res: MediaClipRes = from_layer.get_clip_res(from.y)
		
		from_layer.remove_clip_res(from.y)
		placed_clips_ress[place_clip(to.x, to.y, clip_res, place_method_idx)] = clip_res
	
	if emit_move:
		clips_moved.emit(from_coords, placed_clips_ress)
	
	return placed_clips_ress


func loop_layers_children_deep(info: Dictionary[StringName, Variant], method: Callable, premethod:= Callable(), postmethod:= Callable()) -> void:
	var dupl_info: Dictionary[StringName, Variant] = info.duplicate(true)
	var pre_valid: bool = premethod.is_valid()
	var post_valid: bool = postmethod.is_valid()
	
	for layer_idx: int in layers.size():
		var layer: LayerRes = layers[layer_idx]
		var clips: Dictionary[int, MediaClipRes] = layer.clips
		
		if pre_valid:
			premethod.call(layers, layer_idx, dupl_info)
		
		for frame: int in clips:
			method.call(layers, layer_idx, layer, frame, dupl_info)
			clips[frame].loop_layers_children_deep
		
		if post_valid:
			postmethod.call(layers, layer_idx, dupl_info)




