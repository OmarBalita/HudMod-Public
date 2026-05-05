#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompHexagon extends PassShaderComponentRes

@export var size: float = 16.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {&"size": export(float_args(size))}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Hexagon.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"size", size)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {size} = 16.;
#const float {ratio} = 1.142857142;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {norm_size} = vec2({size} * {ratio}, {size}) * TEXTURE_PIXEL_SIZE;
	#bool {less_than_half} = mod(UV.y / 2., {norm_size}.y) / {norm_size}.y < .5;
	#vec2 {uv} = UV + vec2({norm_size}.x * .5 * float({less_than_half}), .0);
	#vec2 {center_uv} = floor({uv} / {norm_size}) * {norm_size};
	#vec2 {norm_uv} = mod({uv}, {norm_size}) / {norm_size};
	#{center_uv} += mix(vec2(.0, .0),
		#mix(mix(vec2({norm_size}.x, -{norm_size}.y),
			#vec2(.0, -{norm_size}.y),
			#float({norm_uv}.x < .5)),
			#mix(vec2(.0, -{norm_size}.y),
			#vec2(-{norm_size}.x, -{norm_size}.y),
			#float({norm_uv}.x < .5)),
			#float({less_than_half})),
		#float({norm_uv}.y < .3333333) * float({norm_uv}.y / .3333333 < (abs({norm_uv}.x - .5) * 2.)));
	#
	#color = textureLod(TEXTURE, {center_uv}, .0).rgb;
#"

