#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompClarity extends PassShaderComponentRes

@export var clarity_amount: float = 2.
@export var detail_radius: float = 1.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"clarity_amount": export(float_args(clarity_amount, .0, 4., .001)),
		&"detail_radius": export(float_args(detail_radius, .1, 5., .001))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Clarity.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"clarity_amount", clarity_amount)
	set_shader_prop(&"detail_radius", detail_radius)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {clarity_amount}: hint_range(.0, 4.);
#uniform float {detail_radius}: hint_range(.1, 5.);
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {ps} = (1. / vec2(textureSize(TEXTURE, 0))) * {detail_radius};
	#
	#vec3 {neighbors} = vec3(.0);
	#{neighbors} += texture(TEXTURE, UV + vec2(-{ps}.x, .0)).rgb;
	#{neighbors} += texture(TEXTURE, UV + vec2({ps}.x, .0)).rgb;
	#{neighbors} += texture(TEXTURE, UV + vec2(.0, -{ps}.y)).rgb;
	#{neighbors} += texture(TEXTURE, UV + vec2(.0, {ps}.y)).rgb;
	#vec3 {blurred} = {neighbors} / 4.;
	#
	#vec3 {high_pass} = (color.rgb - {blurred}) + 0.5;
	#
	#vec3 {result};
	#for (int i = 0; i < 3; i++) {
		#float {a} = color.rgb[i];
		#float {b} = {high_pass}[i];
		#{result}[i] = (1. - 2. * {b}) * ({a} * {a}) + 2. * {b} * {a};
	#}
	#vec3 {final_rgb} = mix(color.rgb, {result}, {clarity_amount});
	#color = {final_rgb};
#"
