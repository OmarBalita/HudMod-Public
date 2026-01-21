class_name CharacterData extends RefCounted

@export var position: Vector2 = Vector2.ZERO
@export var rotation: float = 0.0
@export var scale: Vector2 = Vector2.ONE
@export var skew: float = 0.0
@export var color: Color = Color.WHITE

var global_position: Vector2 = Vector2.ZERO
var width: float = .0

var transform: Transform2D

func get_transform() -> Transform2D:
	return transform

func set_transform(new_val: Transform2D) -> void:
	transform = new_val

func update_transform() -> void:
	transform = Transform2D()
	transform = transform.translated(global_position + position)
	transform = transform.rotated(rotation)
	transform = transform.scaled(scale)

