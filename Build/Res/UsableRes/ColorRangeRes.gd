class_name ColorRangeRes extends UsableRes

enum INTERPOLATION_MODE {
	CONSTANT,
	LINEAR,
}

@export var keys: Dictionary[float, Color] = {
	.0: Color.BLACK,
	1.: Color.WHITE
}:
	set(val):
		keys = val
		emit_res_changed()

@export var interpolation_mode: INTERPOLATION_MODE = 1:
	set(val):
		interpolation_mode = val
		match val:
			0: interpolation_func = constant
			1: interpolation_func = linear
		emit_res_changed()

var keys_keys: Array[float]

var interpolation_func: Callable = linear

func _init() -> void:
	emit_res_changed()

static func preset_constant() -> ColorRangeRes:
	var crr:= ColorRangeRes.new()
	crr.interpolation_mode = 0
	return crr

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var colorrange_ctrlr: ColorRangeControl = IS.create_color_range_control(self, {})
	return {&"self_ctrlr": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, [colorrange_ctrlr])}

func get_keys() -> Dictionary:
	return keys

func get_custom_keys(function: Callable) -> Dictionary:
	var custom_keys: Dictionary
	for x_pos: float in keys:
		var color: Color = get_key_color(x_pos)
		if function.call(x_pos, color) == true:
			custom_keys[x_pos] = color
	return custom_keys

func set_keys(new_keys: Dictionary) -> void:
	keys = new_keys
	emit_res_changed()

func add_key(x_pos: float, color: Color) -> Dictionary:
	x_pos = clamp(x_pos, .0, 1.0)
	if keys.has(x_pos): 
		return {}
	keys[x_pos] = color
	emit_res_changed()
	return {x_pos: color}

func remove_key(x_pos: float) -> void:
	if keys.size() > 1:
		if keys.has(x_pos):
			keys.erase(x_pos)
			emit_res_changed()

func get_key_color(x_pos: float) -> Color:
	if keys.has(x_pos):
		return keys[x_pos]
	return Color.BLACK

func get_key_by_index(index: int) -> Dictionary:
	if index < 0 or index >= keys.size():
		return {}
	var x_pos: float = keys_keys[index]
	var color: Color = get_key_color(x_pos)
	return {x_pos: color}

func move_key(from_x_pos: float, to_x_pos: float) -> Dictionary:
	if not keys.has(from_x_pos) or (keys.has(to_x_pos) and from_x_pos != to_x_pos):
		return {}
	var color: Color = keys[from_x_pos]
	remove_key(from_x_pos)
	var key: Dictionary = add_key(to_x_pos, color)
	return key

func update_key_color(x_pos: float, new_color: Color):
	if keys.has(x_pos):
		keys[x_pos] = new_color
		emit_res_changed()

func sample(offset: float) -> Color:
	
	var min: float = keys_keys.front()
	var max: float = keys_keys.back()
	
	if offset < min:
		return get_key_color(min)
	
	elif offset > max:
		return get_key_color(max)
	
	else:
		for index: int in keys.size() - 1:
			var key1_xpos: float = keys_keys[index]
			var key2_xpos: float = keys_keys[index + 1]
			if offset >= key1_xpos and offset <= key2_xpos:
				var color1: Color = keys[key1_xpos]
				var color2: Color = keys[key2_xpos]
				var local_offset: float = (offset - key1_xpos) / (key2_xpos - key1_xpos)
				return interpolation_func.call(color1, color2, local_offset)
	
	return Color.BLACK

func constant(a: Color, b: Color, t: float) -> Color:
	return a

func linear(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, t)

func emit_res_changed() -> void:
	keys.sort()
	keys_keys = keys.keys()
	super()

func create_image_texture() -> ImageTexture:
	var image: Image = Image.create_empty(256, 1, false, Image.FORMAT_RGB8)
	for index: int in 256:
		var x: float = index / 256.
		image.set_pixel(index, 0, sample(x))
	return ImageTexture.create_from_image(image)
