class_name GraphEditor extends ColorRect

@export var keys_res: KeysRes

@export_range(1, 1e10) var frame_count: int = 100:
	set(val):
		frame_count = val
		queue_redraw()




func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					pass
				MOUSE_BUTTON_RIGHT:
					pass



func _draw() -> void:
	
	# Draw Basic Time Lines
	var _color = color.lightened(.1)
	var between_dist = size.x / frame_count
	for frame in frame_count:
		var x_pos = frame * between_dist
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, size.y), _color)





