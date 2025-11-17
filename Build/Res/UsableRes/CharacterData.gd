class_name CharacterData extends Object

signal character_property_changed()

var char: String
var code: int
var index: int
var font_rid: RID
var text_slice: TextSliceRes

# Transform Properties
@export var position: Vector2: 
	set(val):
		position = val
		character_property_changed.emit()

@export var rotation: float = 0.0:
	set(val):
		rotation = val
		character_property_changed.emit()

@export var scale: Vector2 = Vector2.ONE:
	set(val):
		scale = val
		character_property_changed.emit()

@export var skew: float = 0.0:
	set(val):
		skew = val
		character_property_changed.emit()

# Metadata
var base_position: Vector2 = Vector2.ZERO
var width: float = 0.0

func _init(p_char: String, p_code: int, p_index: int, p_pos: Vector2, p_width: float, p_font_rid: RID, p_text_slice: TextSliceRes) -> void:
	char = p_char
	code = p_code
	index = p_index
	base_position = p_pos
	position = p_pos
	width = p_width
	font_rid = p_font_rid
	text_slice = p_text_slice

func get_transform() -> Transform2D:
	var t := Transform2D()
	t = t.translated(position)
	t = t.rotated(rotation)
	t = t.scaled(scale)
	return t
