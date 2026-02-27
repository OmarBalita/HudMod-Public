class_name CompCharShake extends Text2DComponentRes

@export var speed: float = 1.
@export var domain: float = 25.
@export var normalized: bool

var noise: FastNoiseLite = GlobalServer.global_usable_res.noise_texture.noise

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"speed": export(float_args(speed, .0, INF)),
		&"domain": export(float_args(domain, .0, INF)),
		&"normalized": export(bool_args(normalized))
	}

func _process_char_fx(line_idx: int, line_data: Text2DRes.LineData, idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	
	var x: float = idx + char.elapsed_time * speed
	var position: Vector2 = Vector2(noise.get_noise_1d(x), noise.get_noise_1d(x + 20.))
	if normalized: position = position.normalized() * domain
	else: position *= domain
	
	char.transform.origin += position

