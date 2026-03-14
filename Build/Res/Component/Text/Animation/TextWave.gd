class_name CompTextWave extends Text2DComponentRes

@export var offset: float = .0
@export var speed: float = 5.
@export var domain: float = 20.
@export var horizontal_domain: CurveProfile = CurveProfile.preset_linear():
	set(val):
		if horizontal_domain: horizontal_domain.res_changed.disconnect(emit_res_changed)
		if val: val.res_changed.connect(emit_res_changed)
		horizontal_domain = val

@export var phase_shift: float = 100.

func _init() -> void:
	horizontal_domain.res_changed.connect(emit_res_changed)

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"offset": export(float_args(offset)),
		&"speed": export(float_args(speed)),
		&"domain": export(float_args(domain)),
		&"Horzontal Domain": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"horizontal_domain": export([horizontal_domain]),
		&"_Horzontal Domain": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		&"phase_shift": export(float_args(phase_shift))
	}

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var offset_ratio: float = char.env.offset_ratio
	var time_factor: float = char.elapsed_time * speed
	var space_factor: float = offset_ratio * phase_shift
	char.transform.origin.y += sin(offset + deg_to_rad(time_factor + space_factor)) * domain * horizontal_domain.sample(offset_ratio * 256.)





