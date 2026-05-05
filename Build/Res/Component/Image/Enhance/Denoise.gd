#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompDenoise extends PassShaderComponentRes

@export var sigma: float = 2.
@export var k_sigma: float = .1
@export var size: float = 3.
@export var sharpness: float = .5

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"sigma": export(float_args(sigma, .001, 5., .001)),
		&"k_sigma": export(float_args(k_sigma, .001, 1., .001)),
		&"size": export(float_args(size, 1., 10., .001)),
		&"sharpness": export(float_args(sharpness, .0, 10., .001)),
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Denoise.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"sigma", sigma)
	set_shader_prop(&"k_sigma", k_sigma)
	set_shader_prop(&"size", size)
	set_shader_prop(&"sharpness", sharpness)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {sigma}: hint_range(.001, 5.);
#uniform float {k_sigma}: hint_range(.001, 1.);
#uniform float {size}: hint_range(1., 10.);
#uniform float {sharpness}: hint_range(.0, 10.);
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {tex_size} = TEXTURE_PIXEL_SIZE;
	#vec3 {center_col} = color;
	#
	#float {kernel_size} = floor({size});
	#float {inv_sigma_sq} = 1. / (2. * {sigma} * {sigma});
	#float {inv_ksigma_sq} = 1. / (2. * {k_sigma} * {k_sigma});
	#
	#vec3 {final_color} = vec3(.0);
	#float {total_weight} = .0;
	#
	#for (float i = -{kernel_size}; i <= {kernel_size}; ++i) {
		#for (float j = -{kernel_size}; j <= {kernel_size}; ++j) {
			#vec2 {offset} = vec2(i, j) * {tex_size};
			#vec3 {sample_col} = texture(TEXTURE, UV + {offset}).rgb;
			#
			#float {dist_sq} = i * i + j * j;
			#float {factor_spatial} = exp(-{dist_sq} * {inv_sigma_sq});
			#
			#float {color_dist_sq} = dot({sample_col} - {center_col}, {sample_col} - {center_col});
			#float {factor_color} = exp(-{color_dist_sq} * {inv_ksigma_sq});
			#
			#float {weight} = {factor_spatial} * {factor_color};
			#
			#float {sw} = {weight} * (1. + {sharpness} * {factor_spatial});
			#
			#{total_weight} += {sw};
			#{final_color} += {sample_col} * {sw};
		#}
	#}
	#
	#color = vec3({final_color} / {total_weight});
#"
