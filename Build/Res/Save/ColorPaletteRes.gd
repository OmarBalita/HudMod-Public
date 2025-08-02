class_name ColorPaletteRes extends Resource

@export var palette_name: String
@export var colors: Array
@export var built_in: bool = false


func get_palette_name() -> String:
	return palette_name

func set_palette_name(new_val: String) -> void:
	palette_name = new_val

func get_colors() -> Array:
	return colors

func set_colors(new_val: Array) -> void:
	colors = new_val

func get_built_in() -> bool:
	return built_in

func set_built_in(new_val: bool) -> void:
	built_in = new_val


static func new_res(_palette_name: String, _colors: Array, _built_in: bool = true) -> ColorPaletteRes:
	var res:= ColorPaletteRes.new()
	res.palette_name = _palette_name
	res.colors = _colors
	res.built_in = _built_in
	return res













