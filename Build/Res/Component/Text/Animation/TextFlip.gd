#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompTextFlip extends Text2DComponentRes

@export var phase_shift: float = 10.
@export var speed: float = 10.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"phase_shift": export(float_args(phase_shift)),
		&"speed": export(float_args(speed))
	}

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var flip_scale: float = sin(deg_to_rad(global_idx * phase_shift + char.elapsed_time * -speed))
	char.transform.x.x = flip_scale

