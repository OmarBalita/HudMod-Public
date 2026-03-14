class_name CompTextPulse extends Text2DComponentRes

@export var pulse_intensity: float = .3
@export var pulse_speed: float = 20.
@export var phase_shift: float = 25.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"pulse_intensity": export(float_args(pulse_intensity)),
		&"pulse_speed": export(float_args(pulse_speed)),
		&"phase_shift": export(float_args(phase_shift))
	}

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var s: float = 1. + sin(deg_to_rad(global_idx * phase_shift + char.elapsed_time * pulse_speed)) * pulse_intensity
	char.transform.x.x *= s
	char.transform.y.y *= s
