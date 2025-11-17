class_name TextOutlineRes extends Resource

signal outline_property_changed()

@export var size: int = 0:
	set(val):
		size = val
		outline_property_changed.emit()
@export var color: Color = Color.WHITE:
	set(val):
		color = val
		outline_property_changed.emit()
@export var offset: Vector2 = Vector2.ZERO:
	set(val):
		offset = val
		outline_property_changed.emit()
