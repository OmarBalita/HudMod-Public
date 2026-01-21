class_name TextOutlineRes extends UsableRes

@export var size: int = 0
@export var color: Color = Color.WHITE
@export var offset: Vector2 = Vector2.ZERO

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"size": export(int_args(size)),
		&"color": export(color_args(color)),
		&"offset": export(vec2_args(offset))
	}
