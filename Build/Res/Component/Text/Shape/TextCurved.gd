class_name CompTextCurved extends Text2DComponentRes

@export var curve: CurveProfile = CurveProfile.preset_constant_line(-1.):
	set(val):
		if curve: curve.res_changed.disconnect(_process_parent_here)
		if val: val.res_changed.connect(_process_parent_here)
		curve = val
@export var domain: float = 250.

func _init() -> void:
	curve.res_changed.connect(_process_parent_here)

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"curve": export([curve]),
		&"domain": export(float_args(domain))
	}

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var ratio: float = char.env.offset_ratio
	char.transform.origin.y += curve.sample_func.call(ratio * 256.) * domain
