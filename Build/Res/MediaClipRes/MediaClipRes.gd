class_name MediaClipRes extends Resource

signal component_property_changed(property_key: StringName, property_new_val: Variant)
signal shader_code_compiled_successfully()
signal shader_material_changed()

signal comp_animation_res_added(comp: ComponentRes, usable_res: UsableRes, property_key: StringName, animation_res: AnimationRes)
signal comp_animation_res_removed(comp: ComponentRes, usable_res: UsableRes, property_key: StringName)
signal comp_keyframe_added(comp: ComponentRes, usable_res: UsableRes, prop_key: StringName, prop_val: Variant, frame: int)
signal comp_keyframe_removed(comp: ComponentRes, usable_res: UsableRes, prop_key: StringName, frame: int)

@export var id: String

@export var clip_pos: int

@export var from: int = 0:
	set(val):
		if GlobalServer.is_global_cache_loaded:
			var min_from: int = MediaServer.get_media_default_from_and_length(self).x
			if min_from == -1: from = max(0, val)
			else: from = val
			update()
		else:
			from = val

@export var length: int = 10: # as frames
	set(val):
		if GlobalServer.is_global_cache_loaded:
			var max_length: int = MediaServer.get_media_default_from_and_length(self).y
			if max_length == 0: length = val
			else: length = clamp(val, 1, max_length - from)
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
var curr_clips: Dictionary[int, int] = {}

@export var components: Dictionary[String, Array]
#{
	#section_key: [],
	#section_key2: [],
	#section_key3: []
#}

var stacked_values: Dictionary[StringName, Array]

var shader_code: String:
	set(val):
		shader_code = val
		if not shader_code.is_empty():
			shader_code_compiled_successfully.emit()
			var new_shader_material:= ShaderMaterial.new()
			var new_shader:= Shader.new()
			new_shader.set_code(shader_code)
			new_shader_material.set_shader(new_shader)
			shader_material = new_shader_material

var shader_material: ShaderMaterial:
	set(val):
		shader_material = val
		for section_key: StringName in components:
			for comp_res: ComponentRes in components[section_key]:
				if comp_res is not ShaderComponentRes:
					continue
				var shader_init_params: Dictionary[StringName, Variant] = comp_res._get_shader_init_params()
				for param_key: StringName in shader_init_params:
					var param_val: Variant = shader_init_params[param_key]
					var param_code_key: String = comp_res.get_shader_param_code_name(String(param_key))
					shader_material.set_shader_parameter(param_code_key, param_val)
		shader_material_changed.emit()

var curr_node: Node # Curr Node Instanced
var curr_frame: int: # Curr Frame Locally
	get():
		var result: int
		if curr_frame == -1:
			var global_frame: int = EditorServer.get_frame()
			result = clamp(global_frame - clip_pos, 0, length)
		else:
			result = curr_frame
		return result


func is_frame_exists(frame: Variant = null) -> bool:
	if frame == null: frame = curr_frame
	return frame >= 0 and frame <= length

func get_frame_or_curr_frame(frame: Variant = null) -> int:
	return curr_frame + from if frame == null else frame

func get_display_name() -> String: return "MediaClip"
func get_thumbnail() -> Texture2D: return null

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

func get_shader_code() -> String:
	return shader_code

func set_shader_code(new_shader_code: String) -> void:
	shader_code = new_shader_code

func get_shader_material() -> ShaderMaterial:
	return shader_material

func set_shader_material(new_shader_material: ShaderMaterial) -> void:
	shader_material = new_shader_material


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
	# Return New ONE
	return duplicated_res


func get_section_absolute(section_key: String) -> Array:
	return components.get_or_add(section_key, [])

func add_component(section_key: String, component: ComponentRes) -> void:
	get_section_absolute(section_key).append(component)
	component.set_owner(self)
	if curr_node: component._enter()
	compile_shader_snips()

func erase_component(section_key: String, component: ComponentRes) -> void:
	get_section_absolute(section_key).erase(component)
	if curr_node:
		component._exit()
		process(curr_frame)
	compile_shader_snips()

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
	
	process(curr_frame)
	compile_shader_snips()

func loop_components(method: Callable, args: Array = []) -> void:
	for section_key: String in components:
		var section_components: Array = components[section_key]
		for component: ComponentRes in section_components:
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

func _emit_component_property_changed(property_key: StringName, property_new_val: Variant) -> void:
	component_property_changed.emit(property_key, property_new_val)


func enter(node: Node) -> void:
	curr_node = node
	loop_components(enter_component)

func process(frame: int) -> void:
	curr_frame = frame
	clear_stacked_values()
	loop_components(process_component, [frame])
	if curr_node:
		loop_stacked_values(curr_node.set)
		if shader_material:
			shader_material.set_shader_parameter(&"time", frame)

func exit(node: Node) -> void:
	curr_frame = -1
	process(curr_frame)
	loop_components(exit_component)
	curr_node = null

func update() -> void:
	loop_components(update_component)


func enter_component(component: ComponentRes) -> void:
	component._enter()

func process_component(component: ComponentRes, frame: int) -> void:
	component.request_push_animations_result(frame)
	component._process(frame)

func exit_component(component: ComponentRes) -> void:
	component._exit()

func update_component(component: ComponentRes, frame: int) -> void:
	component._update()

func compile_shader_snips() -> String:
	if components.size() == 0:
		return shader_code
	
	var used_names: PackedStringArray
	
	var global_params_section: String
	var fragment_section: String
	var vertex_section: String
	
	for section_key: StringName in components.keys():
		for comp_res: ComponentRes in components[section_key]:
			if comp_res is not ShaderComponentRes:
				continue
			
			var params_names_list: Dictionary[String, String]
			
			var global_params_snip:= _format_shader_snip(comp_res._get_shader_global_params_snip(), params_names_list, used_names, true)
			var fragment_snip:= _format_shader_snip(comp_res._get_shader_fragment_snip(), params_names_list, used_names, false)
			var vertex_snip:= _format_shader_snip(comp_res._get_shader_vertex_snip(), params_names_list, used_names, false)
			
			if global_params_snip: global_params_section += "\n" + global_params_snip
			if fragment_snip: fragment_section += "\n" + fragment_snip
			if vertex_snip: vertex_section += "\n" + vertex_snip
			
			comp_res.set_shader_params_names_list(params_names_list)
	
	fragment_section = "void fragment() {\n" + fragment_section + "\n}"
	vertex_section = "void vertex() {\n" + vertex_section + "\n}"
	shader_code = str(
		_get_shader_header(), "\n",
		"\nuniform float time;",
		global_params_section, "\n",
		fragment_section, "\n",
		vertex_section
	)
	
	return shader_code

static func _get_shader_header() -> String:
	return "shader_type canvas_item;"

static func _format_shader_snip(shader_snip: String, params_names_list: Dictionary[String, String], used_names: PackedStringArray, is_global: bool) -> String:
	var gen_id_func: Callable = ProjectServer.generate_new_id.bind(used_names, 12, true)
	var shader_placeholders: PackedStringArray = StringHelper.extract_placeholders(shader_snip)
	var format_values: Dictionary[String, String] = {}
	
	for key: String in shader_placeholders:
		var code_key: String
		if is_global:
			code_key = gen_id_func.call()
			params_names_list[key] = code_key
		elif not params_names_list.has(key):
			code_key = gen_id_func.call()
		else:
			code_key = params_names_list[key]
		format_values[key] = code_key
	
	return shader_snip.format(format_values)


func clear_stacked_values() -> void:
	stacked_values.clear()

func add_stacked_value(key: StringName, value: Variant, method: ComponentRes.MethodType) -> void:
	stacked_values.get_or_add(key, []).append([value, method])

func remove_stacked_value(key: StringName, index: int) -> void:
	stacked_values.get_or_add(key, []).remove_at(index)

func get_stacked_values_key_result(key: StringName) -> Variant:
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

func loop_stacked_values(method: Callable) -> void:
	for key: StringName in stacked_values:
		var key_result: Variant = get_stacked_values_key_result(key)
		method.call(key, key_result)


