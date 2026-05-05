#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompGlitch extends PassShaderComponentRes

@export var power: float = .03
@export var rate: float = .2
@export var speed: float = 5.
@export var block_size: float = 30.5
@export var color_rate: float = .01

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"power": export(float_args(power)),
		&"rate": export(float_args(rate, .0, 1.)),
		&"speed": export(float_args(speed)),
		&"block_size": export(float_args(block_size)),
		&"color_rate": export(float_args(color_rate, .0, 1.))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Glitch.gdshader")

func _process(frame: int) -> void:
	set_shader_props({
		&"power": power,
		&"rate": rate,
		&"speed": speed,
		&"block_size": block_size,
		&"color_rate": color_rate
	})
