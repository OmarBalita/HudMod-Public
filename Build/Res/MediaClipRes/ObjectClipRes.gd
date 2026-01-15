class_name ObjectClipRes extends MediaClipRes

@export var object_res: ObjectRes:
	set(val):
		object_res = val
		add_component(&"Text", object_res)

func get_object_res() -> ObjectRes:
	return object_res

func set_object_res(new_val: ObjectRes) -> void:
	object_res = new_val

func get_display_name() -> String: return object_res.get_res_id()
func get_thumbnail() -> Texture2D: return TypeServer.objects[object_res.get_res_id()].icon
