#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompTextShake extends Text2DComponentRes

@export var speed: float = 1.
@export var domain: float = 25.
@export var normalized: bool

var noise: FastNoiseLite

func _init() -> void:
	await GlobalServer.until_load()
	noise = GlobalServer.global_usable_res.noise_texture.noise

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"speed": export(float_args(speed, .0, INF)),
		&"domain": export(float_args(domain, .0, INF)),
		&"normalized": export(bool_args(normalized))
	}

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var x: float = idx + char.elapsed_time * speed
	var position: Vector2 = Vector2(noise.get_noise_1d(x), noise.get_noise_1d(x + 20.))
	if normalized: position = position.normalized() * domain
	else: position *= domain
	char.transform.origin += position

