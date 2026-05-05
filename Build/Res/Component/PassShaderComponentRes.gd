#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
@abstract class_name PassShaderComponentRes extends ShaderComponentRes

var curr_shader_mat: ShaderMaterial

static func _shader() -> Shader:
	return null

func set_shader_prop(prop_key: StringName, prop_val: Variant) -> void:
	curr_shader_mat.set_shader_parameter(prop_key, prop_val)

func create_pass_shader_material() -> ShaderMaterial:
	var shader_mat:= ShaderMaterial.new()
	shader_mat.shader = _shader()
	curr_shader_mat = shader_mat
	return shader_mat
