#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompTextWind extends Text2DComponentRes

@export var offset: float = .0
@export var force: float = .5
@export var speed: float = 5.
@export var phase_shift: float = 5.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"offset": export(float_args(offset)),
		&"force": export(float_args(force)),
		&"speed": export(float_args(speed)),
		&"phase_shift": export(float_args(phase_shift))
	}

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var wind: float = sin(offset + deg_to_rad(global_idx * phase_shift + char.elapsed_time * speed)) * force
	var half_height: float = line_data.height / 2.
	
	# made by Gemini
	var to_base:= Transform2D(.0, Vector2(.0, -half_height))
	var shear:= Transform2D(Vector2(1., .0), Vector2(wind, 1.), Vector2.ZERO)
	var to_center:= Transform2D(.0, Vector2(.0, half_height))
	
	char.transform = to_center * shear * to_base * char.transform
