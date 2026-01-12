class_name CharacterData extends Object

signal character_property_changed()

var char: String
var code: int
var index: int
var font_rid: RID
var text_slice: TextSliceRes

# Transform Properties
@export var position: Vector2 = Vector2.ZERO:
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

# Visual Properties
@export var color: Color = Color.WHITE:
	set(val):
		color = val
		character_property_changed.emit()

# Metadata
var global_position: Vector2 = Vector2.ZERO
var width: float = 0.0


func _init(p_char: String, p_code: int, p_index: int, p_pos: Vector2, p_width: float, p_font_rid: RID, p_text_slice: TextSliceRes) -> void:
	char = p_char
	code = p_code
	index = p_index
	global_position = p_pos
	font_rid = p_font_rid
	text_slice = p_text_slice


func get_transform() -> Transform2D:
	var transform: Transform2D = Transform2D()
	transform = transform.translated(global_position + position)
	transform = transform.rotated(rotation)
	transform = transform.scaled(scale)
	return transform
