class_name DrawableRect extends ColorRect

@export var drawn_entities: Array[Dictionary]

var draw_indexer: Dictionary[StringName, Callable] = {
	&"rect": draw_rect,
	&"circle": draw_circle,
	&"string": draw_string,
}

func draw_new_rect(rect: Rect2, color: Color = Color.GRAY, filled: bool = true, width: int = -1, antialiased: bool = false) -> int:
	drawn_entities.append({&"rect": [rect, color, filled, width, antialiased]})
	queue_redraw()
	return get_entities_back_index()

func draw_new_string(font: Font, pos: Vector2 = Vector2.ZERO, text: String = "", width: float = 0, font_size: int = 16, modulate: Color = Color.WHITE) -> int:
	drawn_entities.append({&"string": [font, pos, text, -1, width, font_size, modulate]})
	queue_redraw()
	return get_entities_back_index()

func draw_new_theme_rect(rect2: Rect2, custom_color: Color = IS.COLOR_ACCENT_BLUE) -> void:
	draw_new_rect(rect2, Color(custom_color, .4))
	draw_new_rect(rect2, custom_color, false, 5.0)

func clear_drawn_entities() -> void:
	drawn_entities.clear()
	queue_redraw()

func get_entities_back_index() -> int:
	return drawn_entities.size() - 1

func _draw() -> void:
	for info: Dictionary in drawn_entities:
		var type: StringName = info.keys()[0]
		var args: Variant = info.values()[0]
		draw_indexer[type].callv(args)










