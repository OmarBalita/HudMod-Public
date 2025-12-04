class_name MediaClipRes extends Resource

signal component_property_changed(property_key: StringName, property_new_val: Variant)

@export var id: String

@export var from: int = 0:
	set(val):
		var min_from: int = MediaServer.get_media_default_from_and_length(self).x
		if min_from == -1: from = max(0, val)
		else: from = val
		update()

@export var length: int = 10: # as frames
	set(val):
		var max_length: int = MediaServer.get_media_default_from_and_length(self).y
		if max_length == 0: length = val
		else: length = clamp(val, 1, max_length - from)
		update()

@export var children: Dictionary[int, Dictionary]
#{
	#index_x: {time_x: MediaClipRes.new(), time_y: MediaClipRes.new() ...},
	#index_y: {},
	#index_z: {},
	#index_w: {},
	#...
#}
var curr_clips: Dictionary[int, int] = {}

@export var components: Dictionary[String, Array]
#{
	#section_key: [],
	#section_key2: [],
	#section_key3: []
#}

var curr_node: Node # Curr Node Instanced
var curr_frame: int # Curr Frame Locally

var stacked_values: Dictionary[StringName, Array]


func is_frame_exists(frame: Variant = null) -> bool:
	if frame == null: frame = curr_frame
	return frame >= 0 and frame <= length

func get_frame_or_curr_frame(frame: Variant = null) -> int:
	return curr_frame if frame == null else frame

func get_display_name() -> String:
	return "MediaClip"

func get_children() -> Dictionary[int, Dictionary]:
	return children

func set_children(_children: Dictionary[int, Dictionary]) -> void:
	children = _children

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


func duplicate_media_res() -> MediaClipRes:
	var duplicated_res: MediaClipRes = self.duplicate(true)
	# Generate new ID
	duplicated_res.id = ProjectServer.generate_clip_id()
	# Duplicate Components
	var new_components: Dictionary[String, Array]
	for section_key: String in components:
		var curr_section_comp: Array = components.get(section_key)
		var new_section_comp: Array[ComponentRes]
		for curr_component: ComponentRes in curr_section_comp:
			var new_component: ComponentRes = curr_component.duplicate(true)
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
	# Return New ONE
	return duplicated_res


func get_section_absolute(section_key: String) -> Array:
	return components.get_or_add(section_key, [])

func add_component(section_key: String, component: ComponentRes) -> void:
	get_section_absolute(section_key).append(component)
	component.set_owner(self)
	if curr_node: component._enter()

func erase_component(section_key: String, component: ComponentRes) -> void:
	get_section_absolute(section_key).erase(component)
	if curr_node: component._exit()

func remove_component(section_key: String, component_id: StringName) -> void:
	for component: ComponentRes in get_section_absolute(section_key):
		if component.get_res_id() == component_id:
			erase_component(section_key, component)
			return

func move_component(section_key: String, index_from: int, index_to: int) -> void:
	
	var section: Array = get_section_absolute(section_key)
	var section_size:= section.size()
	
	if index_from < 0 or index_from >= section_size: return
	if index_to < 0 or index_to >= section_size: return
	
	var component: ComponentRes = section[index_from]
	section.remove_at(index_from)
	section.insert(index_to, component)

func loop_components(method: Callable, args: Array = []) -> void:
	#print("loop_components ----------------------------- ", method)
	for section_key: String in components:
		var section_components: Array = components[section_key]
		for component: ComponentRes in section_components:
			method.callv([component] + args)
			#print(component)

func _emit_component_property_changed(property_key: StringName, property_new_val: Variant) -> void:
	component_property_changed.emit(property_key, property_new_val)



func enter(node: Node) -> void:
	loop_components(enter_component)
	curr_node = node

func process(frame: int) -> void:
	curr_frame = frame
	if curr_node:
		clear_stacked_values()
		loop_components(process_component, [frame])
		loop_stacked_values(curr_node.set)

func exit(node: Node) -> void:
	loop_components(exit_component)
	curr_node = null
	curr_frame = -1

func update() -> void:
	loop_components(update_component)


func enter_component(component: ComponentRes) -> void:
	component._enter()

func process_component(component: ComponentRes, frame: int) -> void:
	component._process(frame)

func exit_component(component: ComponentRes) -> void:
	component._exit()

func update_component(component: ComponentRes, frame: int) -> void:
	component._update()



func clear_stacked_values() -> void:
	stacked_values.clear()

func add_stacked_value(key: StringName, value: Variant, method: ComponentRes.MethodType) -> void:
	stacked_values.get_or_add(key, []).append({"v": value, "m": method})

func remove_stacked_value(key: StringName, index: int) -> void:
	stacked_values.get_or_add(key, []).remove_at(index)

func get_stacked_values_key_result(key: StringName) -> Variant:
	var key_stacked_values: Array = stacked_values.get(key)
	var result: Variant = key_stacked_values[0].v
	
	for index: int in range(1, key_stacked_values.size()):
		var stacked_info: Dictionary = key_stacked_values[index]
		var val = stacked_info.v
		match stacked_info.m:
			0: result = val
			1: result += val
			2: result -= val
			3: result *= val
			4: result /= val
	
	return result

func loop_stacked_values(method: Callable) -> void:
	for key: StringName in stacked_values:
		var key_result: Variant = get_stacked_values_key_result(key)
		method.call(key, key_result)




