class_name CompTextRainbow extends Text2DComponentRes

@export var offset: float = .0
@export var distance: float = 25.
@export var hue_range: Vector2 = Vector2(.0, 1.)
@export_range(.0, 1.) var saturation: float = 1.
@export_range(.0, 1.) var value: float = 1.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"offset": export(float_args(offset)),
		&"distance": export(float_args(distance)),
		&"hue_range": export(vec2_args(hue_range)),
		&"saturation": export(float_args(saturation, .0, 1.)),
		&"value": export(float_args(value, .0, 1.))
	}

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var angle: float = (idx / distance) + offset
	var t: float = (sin(angle) + 1.0) / 2.0
	var hue: float = lerpf(hue_range.x, hue_range.y, t)
	char.color *= Color.from_hsv(hue, saturation, value)
