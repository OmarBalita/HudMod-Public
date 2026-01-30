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
static func get_object_section() -> StringName: return &""

func get_min_from() -> float: return -INF
func get_max_length() -> float: return +INF
func get_effected_max_length() -> float: return get_max_length()

func format_path(paths_for_format: Dictionary[String, String]) -> void: pass

