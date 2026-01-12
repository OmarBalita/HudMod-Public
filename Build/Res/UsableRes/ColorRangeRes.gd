class_name ColorRangeRes extends UsableRes

signal color_range_changed()

@export var keys: Dictionary = {}

func _init() -> void:
	set_res_id("ColorRangeRes")
	add_key(.0, Color.WHITE)
	add_key(1.0, Color.BLACK)

func get_keys() -> Dictionary:
	return keys

func get_custom_keys(function: Callable) -> Dictionary:
	var custom_keys: Dictionary
	for x_pos: float in keys:
		var color = get_key_color(x_pos)
		if function.call(x_pos, color) == true:
			custom_keys[x_pos] = color
	return custom_keys

func set_keys(new_keys: Dictionary) -> void:
	keys = new_keys
	color_range_changed.emit()

func add_key(x_pos: float, color: Color) -> Dictionary:
	x_pos = clamp(x_pos, .0, 1.0)
	if keys.has(x_pos): 
		return {}
	keys[x_pos] = color
	keys.sort()
	color_range_changed.emit()
	return {x_pos: color}

func remove_key(x_pos: float) -> void:
	if keys.size() > 1:
		if keys.has(x_pos):
			keys.erase(x_pos)
			color_range_changed.emit()

func get_key_color(x_pos: float) -> Color:
	if keys.has(x_pos):
		return keys[x_pos]
	return Color.BLACK

func get_key_by_index(index: int) -> Dictionary:
	if index < 0 or index >= keys.size():
		return {}
	var x_pos = keys[index]
	var color = get_key_color(x_pos)
	return {x_pos: color}

func move_key(from_x_pos: float, to_x_pos: float) -> Dictionary:
	if not keys.has(from_x_pos) or (keys.has(to_x_pos) and from_x_pos != to_x_pos):
		return {}
	var color = keys[from_x_pos]
	remove_key(from_x_pos)
	var key = add_key(to_x_pos, color)
	return key

func update_key_color(x_pos: float, new_color: Color):
	if keys.has(x_pos):
		keys[x_pos] = new_color
		color_range_changed.emit()

func sample(offset: float) -> Color:
	
	offset = clamp(offset, .0, 1.0)
	
	var min = keys.keys().min()
	var max = keys.keys().max()
	
	if offset < min:
		return get_key_color(min)
	elif offset > max:
		return get_key_color(max)
	else:
		for index: int in keys.size() - 1:
			var key1_xpos = keys.keys()[index]
			var key2_xpos = keys.keys()[index + 1]
			
			if offset >= key1_xpos and offset <= key2_xpos:
				var color1 = keys[key1_xpos]
				var color2 = keys[key2_xpos]
				var local_offset = (offset - key1_xpos) / (key2_xpos - key1_xpos)
				return color1.lerp(color2, local_offset)
	
	return Color.BLACK


