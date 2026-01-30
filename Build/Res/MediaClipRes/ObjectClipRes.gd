class_name ObjectClipRes extends MediaClipRes

@export var object_res: ObjectRes

func get_object_res() -> ObjectRes:
	return object_res

func set_object_res(new_val: ObjectRes, insert_to_comps: bool = true) -> void:
	if insert_to_comps:
		if object_res: erase_component(object_res.get_object_section(), object_res)
		if new_val: add_component(new_val.get_object_section(), new_val)
	object_res = new_val

func get_display_name() -> String: return object_res.get_script().get_global_name()
func get_thumbnail() -> Texture2D: return ClassServer.object_res_classes[object_res.get_script().get_global_name()].icon

func duplicate_media_res() -> MediaClipRes:
	var dupl_res: ObjectClipRes = super()
	dupl_res.object_res = dupl_res.components[object_res.get_object_section()][0]
	return dupl_res

func format_path(paths_for_format: Dictionary[String, String]) -> void:
	object_res.format_path(paths_for_format)
