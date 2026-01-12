class_name ImportedClipRes extends MediaClipRes

enum ImportedMediaType {
	MEDIA_TYPE_IMAGE = 0,
	MEDIA_TYPE_VIDEO,
	MEDIA_TYPE_AUDIO
}

@export var type: ImportedMediaType
@export_file() var key_as_path: String

func get_type() -> ImportedMediaType: return type
func get_key_as_path() -> String: return key_as_path

func get_display_name() -> String: return key_as_path.get_file()

