class_name SelectionGroupRes extends Resource

signal selected_objects_changed()


var selected_objects: Dictionary[String, Dictionary]

func add_object(key: String, object: FocusControl, metadata: Dictionary, activate_grouping: bool = true, emit_changes: bool = false) -> void:
	if not activate_grouping:
		clear_objects()
	object.is_selected = true
	selected_objects[key] = {"object": object, "metadata": metadata}
	if emit_changes:
		selected_objects_changed.emit()

func remove_object(key: String, emit_changes: bool = false) -> void:
	if selected_objects.has(key):
		selected_objects[key].object.is_selected = false
		selected_objects.erase(key)
	if emit_changes:
		selected_objects_changed.emit()

func add_objects(objects: Dictionary[String, Control], metadata_keys: Array[String]) -> void:
	for key in objects:
		var object = objects[key]
		if not is_instance_valid(object):
			continue
		var metadata: Dictionary
		for meta in metadata_keys:
			metadata[meta] = object.get(meta)
		add_object(key, object, metadata)
	selected_objects_changed.emit()

func remove_objects(objects: Dictionary[String, Control]) -> void:
	for key in objects: remove_object(key)
	selected_objects_changed.emit()

func clear_objects(filter_meta: Dictionary = {}) -> void:
	for key in selected_objects:
		
		if filter_meta:
			var can_remove: bool = is_metadata_filtered(key, filter_meta)
			if not can_remove:
				continue
		
		var object = selected_objects[key].object
		if is_instance_valid(object):
			object.is_selected = false
	
	selected_objects.clear()
	selected_objects_changed.emit()


func get_objects(filter_meta: Dictionary = {}) -> Dictionary[String, Dictionary]:
	var objects: Dictionary[String, Dictionary]
	if filter_meta.size():
		for key in selected_objects:
			if is_metadata_filtered(key, filter_meta):
				objects[key] = selected_objects[key]
	else:
		objects = selected_objects
	return objects


func get_selected_meta() -> Array[Dictionary]:
	var meta: Array[Dictionary]
	for info in selected_objects.values():
		meta.append(info.metadata)
	return meta

func get_selected_objects_property(property: String) -> Array[Variant]:
	var property_arr: Array[Variant]
	for info in selected_objects.values():
		if is_instance_valid(info.object):
			property_arr.append(info.object.get(property))
	return property_arr


func is_metadata_filtered(key: String, filter_metadata: Dictionary) -> bool:
	var metadata = selected_objects[key].metadata
	for meta_key in filter_metadata:
		if metadata.get(meta_key) != filter_metadata.get(meta_key):
			return false
	return true





