class_name Shape2DObject extends Node2D

func _draw() -> void:
	draw_rect(Rect2(
		Vector2(-100., -100.),
		Vector2(200., 200.)
	), Color.WHITE, true)
	

