@abstract class_name MediaClipRes extends UsableRes

signal processed(frame: int)

signal media_clip_res_updated()

signal comp_animation_res_added(comp: ComponentRes, usable_res: UsableRes, property_key: StringName, animation_res: AnimationRes)
signal comp_animation_res_removed(comp: ComponentRes, usable_res: UsableRes, property_key: StringName)
signal comp_keyframe_added(comp: ComponentRes, usable_res: UsableRes, prop_key: StringName, prop_val: Variant, frame: int)
signal comp_keyframe_removed(comp: ComponentRes, usable_res: UsableRes, prop_key: StringName, frame: int)

@export var id: String

@export var layer_index: int
@export var clip_pos: int

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

@export var children: Dictionary[int, Dictionary]
#{
	#index_x: {time_x: MediaClipRes.new(), time_y: MediaClipRes.new() ...},
	#index_y: {},
	#index_z: {},
	#index_w: {},
	#...
#}
@export var components: Dictionary[String, Array]
#{
	#section_key: [],
	#section_key2: [],
	#section_key3: []
#}

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

func set_children(_children: Dictionary[int, Dictionary]) -> void:
	children = _children

func get_children() -> Dictionary[int, Dictionary]:
	return children

func has_clips() -> bool:
	for layer_index: int in children.keys():
		var media_clips: Dictionary = children[layer_index].media_clips
		if media_clips.size(): return true
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
	var duplicated_res: MediaClipRes = self.duplicate()
	# Generate new ID
	duplicated_res.id = ProjectServer.generate_clip_id()
	# Duplicate Components
	var new_components: Dictionary[String, Array]
	for section_key: String in components:
		var curr_section_comp: Array = components.get(section_key)
		var new_section_comp: Array[ComponentRes]
		for curr_component: ComponentRes in curr_section_comp:
			var new_component: ComponentRes = curr_component.duplicate_component_res()
			new_component.set_owner(duplicated_res)
			new_component.properties = new_component.properties.duplicate(true)
			new_section_comp.append(new_component)
		new_components[section_key] = new_section_comp
	duplicated_res.components = new_components
	# Duplicate Children
	var children: Dictionary[int, Dictionary] = duplicated_res.children.duplicate(true)
	for layer_index: int in children:
		var curr_media_clips: Dictionary = children[layer_index].media_clips
		for frame_in: int in curr_media_clips:
			curr_media_clips[frame_in] = curr_media_clips[frame_in].duplicate_media_res()
	duplicated_res.children = children
	duplicated_res._emit_media_clip_res_updated()
	# Return New ONE
	return duplicated_res

func get_section_comps_absolute(section_key: String) -> Array:
	return components.get_or_add(section_key, [])

func add_component(section_key: String, component: ComponentRes, forced: bool = false) -> void:
	get_section_comps_absolute(section_key).append(component)
	component.set_owner(self)
	component.set_forced(forced)
	_emit_media_clip_res_updated()
	
	if curr_node:
		component._enter()
		process_here()

func erase_component(section_key: String, component: ComponentRes) -> void:
	get_section_comps_absolute(section_key).erase(component)
	_emit_media_clip_res_updated()
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
	
	_emit_media_clip_res_updated()
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
						var anim_keys: Dictionary[float, CurveKey] = channel_profile.keys
						
						for key_pos: float in anim_keys:
							method.call(
								anim_key,
								key_pos,
								anim_keys[key_pos],
								info
							)
	return info

func _emit_media_clip_res_updated(_from: int = -1, _length: int = -1) -> void:
	from = from if _from == -1 else _from
	length = length if _length == -1 else _length
	media_clip_res_updated.emit()

func wait_until_media_res_processed(media_res: MediaClipRes) -> int:
	if media_res.layer_index > layer_index:
		return await media_res.processed
	return -1

func init_node(layer_idx: int, frame_in: int) -> Node:
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


func loop_custom_stacked_values(stacked_values: Dictionary[StringName, Array], method: Callable) -> void:
	for key: StringName in stacked_values:
		var key_result: Variant = get_custom_stacked_values_key_result(stacked_values, key)
		method.call(key, key_result)

func loop_children_deep(info: Dictionary[StringName, Variant], media_res_method: Callable, media_ress_pre_method: Callable = Callable(), media_ress_post_method: Callable = Callable()) -> void:
	var dupl_info: Dictionary[StringName, Variant] = info.duplicate(true)
	var pre_valid: bool = media_ress_pre_method.is_valid()
	var post_valid: bool = media_ress_post_method.is_valid()
	for layer_index: int in children:
		var media_ress: Dictionary = children[layer_index].media_clips
		if pre_valid: media_ress_pre_method.call(children, layer_index, dupl_info)
		for frame_in: int in media_ress:
			media_res_method.call(children, layer_index, frame_in, dupl_info)
			media_ress[frame_in].loop_children_deep(info, media_res_method, media_ress_pre_method, media_ress_post_method)
		if post_valid: media_ress_post_method.call(children, layer_index, dupl_info)

func move_children_deep(offset: int) -> void:
	loop_children_deep(
		{&"media_ress": {} as Dictionary[int, Dictionary]},
		func(children: Dictionary[int, Dictionary], layer_index: int, frame_in: int, info: Dictionary[StringName, Variant]) -> void:
			info.media_ress[layer_index][frame_in + offset] = children[layer_index].media_clips[frame_in],
		func(children: Dictionary[int, Dictionary], layer_index: int, info: Dictionary[StringName, Variant]) -> void:
			info.media_ress[layer_index] = {},
		func(children: Dictionary[int, Dictionary], layer_index: int, info: Dictionary[StringName, Variant]) -> void:
			children[layer_index].media_clips = info.media_ress[layer_index]
	)

func check_children_for_paths_deep(paths_for_check: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray
	
	for layer_index: int in children:
		var media_ress: Dictionary = children[layer_index].media_clips
		
		for frame_in: int in media_ress:
			
			var media_res: MediaClipRes = media_ress[frame_in]
			if media_res is ImportedClipRes:
				if not paths_for_check.has(media_res.key_as_path):
					result.append(media_res.key_as_path)
			result.append_array(media_res.check_children_for_paths_deep(paths_for_check))
	
	return result

func format_children_paths_deep(paths_for_format: Dictionary[String, String]) -> void:
	loop_children_deep({},
		func(children: Dictionary[int, Dictionary], layer_index: int, frame_in: int, info: Dictionary[StringName, Variant]) -> void:
			var child_res: MediaClipRes = children[layer_index].media_clips[frame_in]
			child_res.format_path(paths_for_format)
	)

func format_path(paths_for_format: Dictionary[String, String]) -> void:
	pass

