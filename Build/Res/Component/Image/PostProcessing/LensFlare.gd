#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompLensFlare extends PassShaderComponentRes

@export var sun_position: Vector2
@export var tint: Vector3 = Vector3(1.4, 1.2, 1.)

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"sun_position": export(vec2_args(sun_position)),
		&"tint": export(vec3_args(tint))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/LensFlare.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"sun_position", sun_position)
	set_shader_prop(&"tint", tint)
