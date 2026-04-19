class_name DrawableRect extends ColorRect

@export var drawn_entities: Array[Dictionary]

var draw_indexer: Dictionary[StringName, Callable] = {
	&"line": draw_line,
	&"dashed_line": draw_dashed_line,
	&"rect": draw_rect,
	&"circle": draw_circle,
	&"string": draw_string,
	&"string_outline": draw_string_outline
}

func draw_new_line(from: Vector2, to: Vector2, color: Color = Color.WHITE, width: float = 1.0, antialised: bool = false, redraw: bool = true) -> int:
	drawn_entities.append({&"line": [from, to, color, width, antialised]})
	if redraw: queue_redraw()
	return get_entities_back_index()

func draw_new_dashed_line(from: Vector2, to: Vector2, color: Color = Color.WHITE, width: float = 1.0, dash: int = 2, aligned: bool = true, redraw: bool = true) -> int:
	drawn_entities.append({&"dashed_line": [from, to, color, width, dash, aligned]})
	if redraw: queue_redraw()
	return get_entities_back_index()

func draw_new_rect(rect: Rect2, color: Color = Color.GRAY, filled: bool = true, width: int = -1, antialiased: bool = false, redraw: bool = true) -> int:
	drawn_entities.append({&"rect": [rect, color, filled, width, antialiased]})
	if redraw: queue_redraw()
	return get_entities_back_index()

func draw_new_string_outline(font: Font, pos: Vector2 = Vector2.ZERO, text: String = "", width: float = 0, font_size: int = 16, size: int = 1, modulate: Color = Color.WHITE) -> int:
	drawn_entities.append({&"string_outline": [font, pos, text, -1, width, font_size, size, modulate]})
	return get_entities_back_index()

func draw_new_string(font: Font, pos: Vector2 = Vector2.ZERO, text: String = "", width: float = 0, font_size: int = 16, modulate: Color = Color.WHITE, redraw: bool = true) -> int:
	drawn_entities.append({&"string": [font, pos, text, -1, width, font_size, modulate]})
	if redraw: queue_redraw()
	return get_entities_back_index()

func draw_new_theme_rect(rect2: Rect2, custom_color: Color = IS.color_accent, redraw: bool = true) -> void:
	draw_new_rect(rect2, Color(custom_color, .4), true, -1, false, false)
	draw_new_rect(rect2, custom_color, false, 5.0, false, redraw)

func draw_new_selection_box_rect(rect: Rect2, color: Color = IS.color_accent, redraw: bool = true) -> void:
	var start_pos:= rect.position
	var end_pos:= start_pos + rect.size
	var to_x_pos:= Vector2(end_pos.x, start_pos.y)
	var to_y_pos:= Vector2(start_pos.x, end_pos.y)
	
	draw_new_rect(rect, Color(color, .5))
	draw_new_dashed_line(start_pos, to_x_pos, color, 2., 10., true, false)
	draw_new_dashed_line(to_x_pos, end_pos, color, 2., 10., true, false)
	draw_new_dashed_line(end_pos, to_y_pos, color, 2., 10., true, false)
	draw_new_dashed_line(to_y_pos, start_pos, color, 2., 10., true, redraw)

func draw_new_cursor(pos: Vector2, color: Color = Color.WHITE, redraw: bool = true) -> void:
	draw_new_line(pos + Vector2(10., .0), pos - Vector2(10., .0), color, 1., false, false)
	draw_new_line(pos + Vector2(.0, 10.), pos - Vector2(.0, 10.), color, 1., false, redraw)

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










