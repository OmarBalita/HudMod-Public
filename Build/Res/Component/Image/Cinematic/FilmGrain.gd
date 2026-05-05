#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompFilmGrain extends SnippetShaderComponentRes

@export var intensity: float = .3
@export var grain_size: float = 3.
@export var monochrome: bool = true

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"intensity": export(float_args(intensity, .0, 1.)),
		&"grain_size": export(float_args(grain_size, 1., 20.)),
		&"monochrome": export(bool_args(monochrome))
	}

func _process(frame: int) -> void:
	set_shader_prop(&"intensity", intensity)
	set_shader_prop(&"grain_size", grain_size)
	set_shader_prop(&"monochrome", monochrome)

func _get_shader_global_params_snip() -> String:
	return "
uniform float {intensity}: hint_range(.0, 1.);
uniform float {grain_size}: hint_range(1., 20.);
uniform bool {monochrome};
"

func _get_shader_fragment_snip() -> String:
	return "
	vec2 {grain_uv} = floor(UV / (TEXTURE_PIXEL_SIZE * {grain_size})) * (TEXTURE_PIXEL_SIZE * {grain_size});
	
	float {luminance} = get_luminance(color);
	float {mask} = pow({luminance}, .5) * (1. - {luminance});
	
	float {noise_time} = sin(time);
	vec3 {noise_output};
	if ({monochrome}) {
		float {noise} = random({grain_uv} + fract({noise_time}));
		{noise_output} = vec3({noise});
	} else {
		{noise_output} = vec3(
			random({grain_uv} + fract({noise_time} + .1)),
			random({grain_uv} + fract({noise_time} + .2)),
			random({grain_uv} + fract({noise_time} + .3))
		);
	}
	color += ({noise_output} - .5) * {intensity} * ({mask} * 4.);
"

