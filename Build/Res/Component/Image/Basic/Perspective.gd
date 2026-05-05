#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompPerspective extends PassShaderComponentRes

@export var fov: float = 90.
@export var cull_back: bool
@export var y_rot: float = .0
@export var x_rot: float = .0

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"fov": export(float_args(fov, 1., 179., .01, .2)),
		&"cull_back": export(bool_args(cull_back)),
		&"y_rot": export(float_args(y_rot, -180., 180., .01, .2)),
		&"x_rot": export(float_args(y_rot, -180., 180., .01, .2))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Perspective.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"fov", fov)
	set_shader_prop(&"cull_back", cull_back)
	set_shader_prop(&"y_rot", y_rot)
	set_shader_prop(&"x_rot", x_rot)

