#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompGlow extends PassShaderComponentRes

@export var color: Color = Color.WHITE
@export var power: float = 4.
@export var radius: float = 5.
@export var quality: int = 8

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"color": export(color_args(color)),
		&"power": export(float_args(power, .0, 20.)),
		&"radius": export(float_args(radius, .0, 30.)),
		&"quality": export(int_args(quality, 1, 20))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Glow.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"color", color)
	set_shader_prop(&"power", power)
	set_shader_prop(&"radius", radius)
	set_shader_prop(&"quality", quality)
