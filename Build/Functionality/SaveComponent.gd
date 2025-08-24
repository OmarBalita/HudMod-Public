class_name SaveComponent extends Node

@export var save_path: String
@export var properties: Array[StringName]


func save_data() -> void:
	if not save_path.is_absolute_path():
		return
	
	var parent_node = get_parent()
	
	var res:= EditorRes.new()
	res.data = {}
	
	for prop in properties:
		res.data[prop] = parent_node.get(prop)
	
	var error = ResourceSaver.save(res, save_path)
	if error != OK:
		push_error("Failed to save resource: %s" % save_path)


func load_data() -> void:
	var res = ResourceLoader.load(save_path)
	if res == null:
		push_error("Failed to load resource: %s" % save_path)
		return
	if not res is EditorRes:
		push_error("Invalid resource type: %s" % save_path)
		return
	
	var parent_node = get_parent()
	if parent_node == null:
		push_error("No parent node to apply properties to.")
		return
	
	for key in res.data.keys():
		parent_node.set(key, res.data[key])





