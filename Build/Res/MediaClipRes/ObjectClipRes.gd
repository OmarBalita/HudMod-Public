class_name ObjectClipRes extends MediaClipRes

@export var object_res: ObjectRes

func get_object_res() -> ObjectRes:
	return object_res

func set_object_res(new_val: ObjectRes) -> void:
	object_res = new_val

func get_display_name() -> String:
	return object_res.get_res_id()
