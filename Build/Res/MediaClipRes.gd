class_name MediaClipRes extends Resource

signal component_property_changed(property_key: StringName, property_new_val: Variant)

@export var id: String

@export_file() var media_resource_path: String
# files types:
# Image: svg, png, jpeg, jif ...
# Video: mp4, avi, av1, mkv, gif ...
# Audio: mp3, wav, ogg ...
# Text: res => Resource:TextResource
# Shape: res => Resource:ShapeResource
# Effect: res => Resource:EffectResource
# Code: res => Resource:CodeResource

@export var from: int = 0:
	set(val):
		from = val
		update()
@export var length: int = 10: # as frames
	set(val):
		length = val
		update()

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

func add_child() -> void:
	pass

func remove_child() -> void:
	pass

func get_section_absolute(section_key: String) -> Array:
	return components.get_or_add(section_key, [])

func add_component(section_key: String, component: ComponentRes, node: Node) -> void:
	get_section_absolute(section_key).append(component)
	component.set_owner(self)
	if node: component._enter(node)

func erase_component(section_key: String, component: ComponentRes, node: Node) -> void:
	get_section_absolute(section_key).erase(component)
	if node: component._exit(node)

func remove_component(section_key: String, component_id: StringName, node: Node) -> void:
	for component: ComponentRes in get_section_absolute(section_key):
		if component.get_res_id() == component_id:
			erase_component(section_key, component, node)
			return


func move_component(section_key: String, index_from: int, index_to: int) -> void:
	
	var section: Array = get_section_absolute(section_key)
	var section_size:= section.size()
	
	if index_from < 0 or index_from >= section_size: return
	if index_to < 0 or index_to >= section_size: return
	
	var component: ComponentRes = section[index_from]
	section.remove_at(index_from)
	section.insert(index_to, component)

func loop_components(node: Node, method: Callable, frame: int = -1) -> void:
	for section_key: String in components:
		var section_components: Array = components[section_key]
		for component: ComponentRes in section_components:
			method.call(node, component, frame)

func _emit_component_property_changed(property_key: StringName, property_new_val: Variant) -> void:
	component_property_changed.emit(property_key, property_new_val)



func enter(node: Node) -> void:
	loop_components(node, enter_component)

func process(node: Node, frame: int) -> void:
	loop_components(node, process_component, frame)

func exit(node: Node) -> void:
	loop_components(node, exit_component)

func update() -> void:
	loop_components(null, update_component)


func enter_component(node: Node, component: ComponentRes, custom_frame: int) -> void:
	component._enter(node, custom_frame)

func process_component(node: Node, component: ComponentRes, frame: int) -> void:
	component._process(node, frame)

func exit_component(node: Node, component: ComponentRes, custom_frame: int) -> void:
	component._exit(node, custom_frame)

func update_component(node: Node, component: ComponentRes, frame: int) -> void:
	component._update()
