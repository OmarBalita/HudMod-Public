class_name ImportedClipRes extends MediaClipRes

enum ImportedMediaType {
	MEDIA_TYPE_IMAGE = 0,
	MEDIA_TYPE_VIDEO,
	MEDIA_TYPE_AUDIO
}

static var imported_media_type_str_indexer: Dictionary[int, StringName] = {
	0: &"Image", 1: &"Video", 2: &"Audio"
}

@export var type: ImportedMediaType
@export_file() var key_as_path: String

func get_type() -> ImportedMediaType: return type
func get_type_str() -> String: return imported_media_type_str_indexer[type]
func get_key_as_path() -> String: return key_as_path

func get_display_name() -> String: return str(get_type_str(), ":", key_as_path.get_file())
func get_thumbnail() -> Texture2D: return MediaServer.get_thumbnail(key_as_path).texture

func format_path(paths_for_format: Dictionary[String, String]) -> void:
	if paths_for_format.has(key_as_path):
		key_as_path = paths_for_format[key_as_path]

func check_children_for_paths_deep(paths_for_check: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = super(paths_for_check)
	if not paths_for_check.has(key_as_path):
		result.append(key_as_path)
	return result

