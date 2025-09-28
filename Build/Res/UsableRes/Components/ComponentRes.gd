class_name ComponentRes extends UsableRes

@export var owner: MediaClipRes:
	set(val):
		owner = val
		_update()
		res_changed.connect(_update)
@export var properties: Dictionary[StringName, Dictionary]


func get_owner() -> MediaClipRes:
	return owner

func set_owner(new_owner: MediaClipRes) -> void:
	owner = new_owner

static func _set_component_property(component: ComponentRes, property_key: StringName, property_val: Variant, custom_frame: int) -> void:
	component.set_component_property(property_key, property_val, custom_frame)

static func create_custom_edit(name: String, usable_res: UsableRes, custom_set_func: Callable = _set_component_property, custom_frame: int = -1) -> Array[Control]:
	return super(name, usable_res, custom_set_func, custom_frame)

func set_component_property(property_key: StringName, property_val: Variant, frame: int = -1) -> void:
	properties[property_key] = {frame: property_val}

func register_properties(_properties: Dictionary[StringName, Variant]) -> void:
	for property_name: StringName in _properties:
		var property_default_val: Variant = _properties.get(property_name)
		register_property(property_name, property_default_val)

func register_property(property_name: StringName, property_default_val: Variant) -> void:
	properties[property_name] = {-1: property_default_val}

func _update_properties(node: Node, frame: int) -> void:
	for property_name: StringName in properties:
		var curr_property_val: Variant = get_prop(property_name, frame)
		node.set(property_name, curr_property_val)

func get_prop(property_name: StringName, frame: int = -1) -> Variant:
	var result: Variant
	var property_keys: Dictionary = properties[property_name]
	if property_keys.size() == 1: result = property_keys[-1]
	else: properties[property_name].get(frame)
	return result

func _enter(node: Node, custom_frame: int = -1) -> void:
	res_changed.connect(_update_properties.bind(node, custom_frame))

func _process(node: Node, frame: int) -> void:
	_update_properties(node, frame)

func _exit(node: Node, custom_frame: int = -1) -> void:
	res_changed.disconnect(_update_properties.bind(node, custom_frame))

func _update() -> void:
	pass








