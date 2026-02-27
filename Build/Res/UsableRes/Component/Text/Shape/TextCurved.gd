class_name CompTextCurved extends Text2DComponentRes

@export var curve: CurveProfile = CurveProfile.preset_constant_line()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"curve": export([curve])
	}

func _process_char_fx(line_idx: int, line_data: Text2DRes.LineData, idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	char.transform.origin
