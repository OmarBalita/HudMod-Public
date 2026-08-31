#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
## GPLv3																   ##
#############################################################################
class_name CompLGG extends SnippetShaderComponentRes

@export var lift:= Color(0.5, 0.5, 0.5)
@export var gamma:= Color(0.5, 0.5, 0.5)
@export var gain:= Color(0.5, 0.5, 0.5)
@export var offset: float

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"lift": export(color_args(lift)),
		&"gamma": export(color_args(gamma)),
		&"gain": export(color_args(gain)),
		&"offset": export(float_args(offset, -1., 1., .001))
	}

func has_color_correction_editor() -> bool: return true
func _get_color_correction_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"lift": export(color_args(lift, IS.EDIT_BOX_MIN_SIZE, 0, 1)),
		&"gamma": export(color_args(gamma, IS.EDIT_BOX_MIN_SIZE, 0, 1)),
		&"gain": export(color_args(gain, IS.EDIT_BOX_MIN_SIZE, 0, 1)),
	}

func _process(frame: int) -> void:
	set_shader_prop(&"lift", (lift - Color(0.5, 0.5, 0.5)) * 2.0)
	set_shader_prop(&"gamma", gamma * 2.0)
	set_shader_prop(&"gain", gain * 2.0)
	set_shader_prop(&"offset", offset)

func _get_shader_global_params_snip() -> String:
	return "
uniform vec3 {lift}: source_color;
uniform vec3 {gamma}: source_color = vec3(1.);
uniform vec3 {gain}: source_color = vec3(1.);
uniform float {offset}: hint_range(-1., 1.);
"

func _get_shader_fragment_snip() -> String:
	return "
	// LGG + Offset method
	color = pow(max(vec3(.0), color * {gain} + {lift} + {offset}), 1. / {gamma});
"
