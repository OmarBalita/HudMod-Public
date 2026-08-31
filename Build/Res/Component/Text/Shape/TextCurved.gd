#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
## GPLv3																   ##
#############################################################################
class_name CompTextCurved extends Text2DComponentRes

@export var curve: CurveProfile = CurveProfile.preset_constant_line(-1.):
	set(val):
		if curve: curve.res_changed.disconnect(emit_res_changed)
		if val: val.res_changed.connect(emit_res_changed)
		curve = val
@export var domain: float = 250.

func _init() -> void:
	curve.res_changed.connect(emit_res_changed)

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"curve": export([curve]),
		&"domain": export(float_args(domain))
	}

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var ratio: float = char.env.offset_ratio
	char.transform.origin.y += curve.sample_func.call(ratio * 256.) * domain
