#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompVoronoi extends PassShaderComponentRes

@export var size: float = 32.
@export var randomness: float = 1.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"size": export(float_args(size)),
		&"randomness": export(float_args(randomness))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Voronoi.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"size", size)
	set_shader_prop(&"randomness", randomness)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {size};
#uniform float {randomness};
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#float {ratio} = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
	#
	#vec2 {cell_size} = vec2(max({size}, 0.01) * {ratio}, max({size}, 0.01));
	#vec2 {_size} = 1. / {cell_size}; 
	#
	#vec2 {grid_uv} = UV / {_size};
	#vec2 {cell_index} = floor({grid_uv});
	#vec2 {cell_fract} = fract({grid_uv});
	#
	#float {min_dist} = 2.;
	#vec2 {closest_cell_offset};
	#
	#for (int y = -1; y <= 1; y++) {
		#for (int x = -1; x <= 1; x++) {
			#vec2 {neighbor} = vec2(float(x), float(y));
			#vec2 {curr_uv} = {cell_index} + {neighbor};
			#vec2 {point} = fract(
				#sin(
					#vec2(
						#dot({curr_uv}, vec2(127.1, 311.7)),
						#dot({curr_uv}, vec2(269.5, 183.3))
					#)
			#) * 43758.5453);
			#
			#{point} = .5 + .5 * sin({point} * 6.2831);
			#
			#{point} = mix(vec2(.5), {point}, {randomness});
			#
			#vec2 {diff} = {neighbor} + {point} - {cell_fract};
			#float {dist} = length({diff});
			#
			#if ({dist} < {min_dist}) {
				#{min_dist} = {dist};
				#{closest_cell_offset} = {neighbor} + {point};
			#}
		#}
	#}
	#
	#vec2 {target_uv} = ({cell_index} + {closest_cell_offset}) * {_size};
	#
	#vec4 {color} = texture(TEXTURE, {target_uv});
	#
	#color = {color}.rgb;
	#alpha = {color}.a;
#"
