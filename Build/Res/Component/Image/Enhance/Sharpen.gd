#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompSharpen extends PassShaderComponentRes

@export var amount: float = .2
@export var radius: float = 2.
@export var threshold: float = .05

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"amount": export(float_args(amount, .0, 5.)),
		&"radius": export(float_args(radius, .1, 3.)),
		&"threshold": export(float_args(threshold, .0, 1.))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Sharpen.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"amount", amount)
	set_shader_prop(&"radius", radius)
	set_shader_prop(&"threshold", threshold)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {amount}: hint_range(.0, 5.);
#uniform float {radius}: hint_range(.1, 3.);
#uniform float {threshold}: hint_range(.0, 1.);
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {texel_size} = 1. / vec2(textureSize(TEXTURE, 0)) * {radius};
	#vec3 {center_color} = color.rgb;
	#
	#float {luma_c} = get_luminance({center_color});
	#float {luma_t} = get_luminance(texture(TEXTURE, UV + vec2(.0, -{texel_size}.y)).rgb);
	#float {luma_b} = get_luminance(texture(TEXTURE, UV + vec2(.0, {texel_size}.y)).rgb);
	#float {luma_l} = get_luminance(texture(TEXTURE, UV + vec2(-{texel_size}.x, .0)).rgb);
	#float {luma_r} = get_luminance(texture(TEXTURE, UV + vec2({texel_size}.x, .0)).rgb);
	#
	#float {sharp} = 4.0 * {luma_c} - ({luma_t} + {luma_b} + {luma_l} + {luma_r});
	#
	#float {mask} = smoothstep({threshold}, {threshold} + .2, abs({sharp}));
	#
	#vec3 {final_color} = {center_color} + ({sharp} * {amount} * {mask});
	#
	#color.rgb = clamp({final_color}, .0, 1.);
#"

