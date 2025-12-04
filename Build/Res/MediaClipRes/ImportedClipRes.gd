class_name ImportedClipRes extends MediaClipRes

enum ImportedMediaType {
	MEDIA_TYPE_IMAGE,
	MEDIA_TYPE_VIDEO,
	MEDIA_TYPE_AUDIO
}

@export var type: ImportedMediaType
@export_file() var key_as_path: String

func get_display_name() -> String:
	return key_as_path.get_file()

