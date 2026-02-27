class_name Outline extends UsableRes

@export var size: int
@export var offset: Vector2
@export var color: Color

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"size": export(int_args(size, 0)),
		&"offset": export(vec2_args(offset)),
		&"color": export(color_args(color))
	}

