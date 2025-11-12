class_name SelectionGroupRes extends Resource

signal selected_objects_changed()

var selected_objects: Dictionary[String, Dictionary]
var focused: Dictionary


func add_object(key: String, object: FocusControl, metadata: Dictionary, activate_grouping: bool = true, emit_change: bool = false) -> void:
	
	if not activate_grouping:
		clear_objects({}, false)
	
	selected_objects[key] = {"object": object, "metadata": metadata}
	object.is_selected = true
	
	if emit_change:
		update_focused(selected_objects[key])
		selected_objects_changed.emit()

func remove_object(key: String, emit_change: bool = false) -> void:
	if selected_objects.has(key):
		
		var object: FocusControl = selected_objects[key].object
		if focused and object == focused.object:
			focused.clear()
		
		object.is_selected = false
		selected_objects.erase(key)
	
	if emit_change:
		selected_objects_changed.emit()

func add_objects(objects: Dictionary[String, Control], metadata_keys: Array[String]) -> void:
	for key: String in objects:
		var object: FocusControl = objects[key]
		if not is_instance_valid(object):
			continue
		#for meta: String in metadata_keys:
			#metadata[meta] = object.get(meta)
		add_object(key, object, object.get_metadata())
	
	if selected_objects.size():
		update_focused(selected_objects.values().back())
	selected_objects_changed.emit()

func remove_objects(objects: Dictionary[String, Control], emit_change: bool = true) -> void:
	for key: String in objects: remove_object(key)
	if emit_change: selected_objects_changed.emit()

func clear_objects(filter_meta: Dictionary = {}, emit_change: bool = true) -> void:
	for key: String in selected_objects:
		
		if filter_meta:
			var can_remove: bool = is_metadata_filtered(key, filter_meta)
			if not can_remove:
				continue
		
		var object: Variant = selected_objects[key].object
		if is_instance_valid(object):
			object.is_selected = false
	
	selected_objects.clear()
	update_focused()
	
	if emit_change:
		selected_objects_changed.emit()

func get_objects(filter_meta: Dictionary = {}) -> Dictionary[String, Dictionary]:
	var objects: Dictionary[String, Dictionary]
	if filter_meta.size():
		for key: String in selected_objects:
			if is_metadata_filtered(key, filter_meta):
				objects[key] = selected_objects[key]
	else: objects = selected_objects
	return objects


func update_focused(new_focused: Dictionary = {}) -> void:
	if focused and focused.object:
		focused.object.focus_exit()
	if new_focused and new_focused.object:
		new_focused.object.focus_enter()
	focused = new_focused

func get_focused() -> Dictionary:
	return focused

func get_selected_meta() -> Array[Dictionary]:
	var meta: Array[Dictionary]
	for info in selected_objects.values():
		meta.append(info.metadata)
	return meta

func get_selected_objects_property(property: String) -> Array[Variant]:
	var property_arr: Array[Variant]
	for info: Dictionary in selected_objects.values():
		if is_instance_valid(info.object):
			property_arr.append(info.object.get(property))
	return property_arr


func is_metadata_filtered(key: String, filter_metadata: Dictionary) -> bool:
	var metadata: Dictionary = selected_objects[key].metadata
	for meta_key in filter_metadata:
		if metadata.get(meta_key) != filter_metadata.get(meta_key):
			return false
	return true





