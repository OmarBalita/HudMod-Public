class_name DrawableRect extends ColorRect

@export var drawed_entities: Array[Dictionary]

func draw_new_rect(rect: Rect2, color: Color = Color.GRAY, filled: bool = true, width: int = -1, antialiased: bool = false) -> void:
	drawed_entities.append({"rect": [rect, color, filled, width, antialiased]})
	queue_redraw()

func draw_new_theme_rect(rect2: Rect2, custom_color: Color = IS.COLOR_ACCENT_BLUE) -> void:
	draw_new_rect(rect2, Color(custom_color, .4))
	draw_new_rect(rect2, custom_color, false, 5.0)

func clear_drawed_entities() -> void:
	drawed_entities.clear()
	queue_redraw()

func _draw() -> void:
	for info: Dictionary in drawed_entities:
		var type: String = info.keys()[0]
		var args: Variant = info.values()[0]
		match type:
			'rect': draw_rect.callv(args)

