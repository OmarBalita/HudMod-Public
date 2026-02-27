class_name CompCharWave extends Text2DComponentRes

@export var offset: float = .0
@export var speed: float = 5.
@export var domain: float = 10.
@export var frequency: float = 5.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"offset": export(float_args(offset)),
		&"speed": export(float_args(speed)),
		&"domain": export(float_args(domain)),
		&"frequency": export(float_args(frequency))
	}

func _process_char_fx(line_idx: int, line_data: Text2DRes.LineData, idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var time_factor: float = char.elapsed_time * speed
	var space_factor: float = idx * frequency
	char.transform.origin.y += sin(offset + deg_to_rad(time_factor + space_factor)) * domain

