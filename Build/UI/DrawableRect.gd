class_name DrawableRect extends ColorRect

@export var drawed_entities: Array[Dictionary]


func draw_new_rect(rect: Rect2, color: Color = Color.GRAY, filled: bool = true, width: int = -1, antialiased: bool = false) -> void:
	drawed_entities.append({"rect": [rect, color, filled, width, antialiased]})
	queue_redraw()

func clear_drawed_entities() -> void:
	drawed_entities.clear()
	queue_redraw()


func _draw() -> void:
	for info in drawed_entities:
		var type = info.keys()[0]
		var args = info.values()[0]
		match type:
			'rect':
				draw_rect.callv(args)

