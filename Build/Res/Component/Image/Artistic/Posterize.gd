#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompPosterize extends PassShaderComponentRes

@export var levels: float = 256.
@export var use_gradient: bool = false
@export var gradient: ColorRangeRes = ColorRangeRes.preset_constant()
@export var filter_radius: float = 5.
@export var filter_quality: float = .2

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"levels": export(float_args(levels, 2., 1024., .001)),
		&"Gradient": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"use_gradient": export(bool_args(use_gradient)),
		&"gradient": export([gradient]),
		&"_Gradient": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		&"Filter": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"filter_radius": export(float_args(filter_radius, .0, 50., .001)),
		&"filter_quality": export(float_args(filter_quality, .1, 1., .001)),
		&"_Filter": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Posterize.gdshader")

func _process(frame: int) -> void:
	set_shader_props({
		&"levels": levels,
		&"use_gradient": use_gradient,
		&"filter_radius": filter_radius,
		&"filter_quality": filter_quality
	})

func _ready_shader() -> void:
	update_gradient()
	gradient.res_changed.connect(update_gradient)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {levels}: hint_range(2., 1024.);
#uniform bool {use_gradient};
#uniform sampler2D {gradient}: hint_default_black;
#uniform float {filter_radius}: hint_range(.0, 50.) = 5.;
#uniform float {filter_quality}: hint_range(.1, 1.) = .2;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {tex_size} = vec2(textureSize(TEXTURE, 0));
	#vec2 {pixel_size} = 1. / {tex_size};
	#
	#vec3 {accumulated_color} = vec3(.0);
	#float {total_weights} = .0;
	#
	#float {step_size} = 1. / max({filter_quality}, .01);
	#
	#for (float x = -{filter_radius}; x <= {filter_radius}; x += {step_size}) {
		#for (float y = -{filter_radius}; y <= {filter_radius}; y += {step_size}) {
			#vec2 {offset} = vec2(x, y) * {pixel_size};
			#{accumulated_color} += texture(TEXTURE, UV + {offset}).rgb;
			#{total_weights} += 1.;
		#}
	#}
	#
	#vec4 {color} = texture(TEXTURE, UV);
	#
	#vec3 {smooth_col} = ({total_weights} > .0) ? ({accumulated_color} / {total_weights}) : {color}.rgb;
	#
	#float {luma} = get_luminance({smooth_col});
	#float {v} = {luma} * ({levels} - 1.);
	#float {delta} = fwidth({v});
	#
	#vec3 {result_rgb};
	#if ({use_gradient}) {
		#float {posterized_luma} = (floor({v}) + smoothstep(.5 - {delta}, .5 + {delta}, fract({v}))) / ({levels} - 1.);
		#{result_rgb} = texture({gradient}, vec2({posterized_luma}, .0)).rgb;
	#} else {
		#vec3 {v_rgb} = {smooth_col}.rgb * ({levels} - 1.);
		#vec3 {delta_rgb} = fwidth({v_rgb});
		#{result_rgb} = (floor({v_rgb}) + smoothstep(vec3(.5) - {delta_rgb}, vec3(.5) + {delta_rgb}, fract({v_rgb}))) / ({levels} - 1.);
	#}
	#
	#color = {result_rgb};
	#alpha = {color}.a;
#"

func update_gradient() -> void:
	set_shader_prop(&"gradient", gradient.create_image_texture())
	emit_res_changed()
