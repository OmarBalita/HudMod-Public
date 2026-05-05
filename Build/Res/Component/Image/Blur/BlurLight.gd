#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompBlurLight extends PassShaderComponentRes

@export var rot_degrees: float = .0
@export var blur_amount: float = .01
@export var weight: float = .5

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"rot_degrees": export(float_args(rot_degrees)),
		&"blur_amount": export(float_args(blur_amount, .0, 1., .001)),
		&"weight": export(float_args(weight, .0, 1., .001))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/BlurLight.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"rot_degrees", rot_degrees)
	set_shader_prop(&"blur_amount", blur_amount)
	set_shader_prop(&"weight", weight)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {rot_degrees} = .0;
#uniform float {blur_amount}: hint_range(.0, 1.) = .01;
#uniform float {weight}: hint_range(.0, 1.) = .5;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#float {angle2} = {rot_degrees} + PI / 2.;
	#vec2 {offset1} = vec2(cos({rot_degrees}), sin({rot_degrees})) * {blur_amount};
	#vec2 {offset2} = vec2(cos({angle2}), sin({angle2})) * {blur_amount};
	#
	#vec4 {top} = texture(TEXTURE, UV + {offset1});
	#vec4 {down} = texture(TEXTURE, UV - {offset1});
	#vec4 {right} = texture(TEXTURE, UV + {offset2});
	#vec4 {left} = texture(TEXTURE, UV - {offset2});
	#
	#vec4 {result} = ({top} + {down} + {right} + {left}) / 4.;
	#{result} = mix(vec4(color, alpha), {result}, {weight});
	#
	#color = {result}.rgb;
	#alpha = {result}.q;
#"
