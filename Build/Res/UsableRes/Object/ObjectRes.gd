class_name ObjectRes extends ComponentRes

func _enter() -> void: pass
func _process(frame: int) -> void: pass
func _exit() -> void: pass

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	return null

static func get_object_category_name() -> StringName: return &""
static func get_object_info() -> Dictionary[StringName, String]:
	return {
		&"title": "ObjectRes",
		&"description": ""
	}

