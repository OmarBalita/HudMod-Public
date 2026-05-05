#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompHalftone extends PassShaderComponentRes

@export var offset: Vector2
@export var size: float = 64.
@export var value_multiplier: float = .9
@export var dot_color: Color = Color.BLACK
@export var back_color: Color = Color.WHITE

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"offset": export(vec2_args(offset)),
		&"size": export(float_args(size)),
		&"value_multiplier": export(float_args(value_multiplier, .0, 32.)),
		&"dot_color": export(color_args(dot_color)),
		&"back_color": export(color_args(back_color))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Halftone.gdshader")

func _process(frame: int) -> void:
	set_shader_props({
		&"offset": offset,
		&"size": size,
		&"value_multiplier": value_multiplier,
		&"dot_color": dot_color,
		&"back_color": back_color
	})

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform vec2 {offset};
#uniform float {size};
#uniform float {value_multiplier}: hint_range(.0, 32.);
#uniform vec4 {dot_color}: source_color;
#uniform vec4 {back_color}: source_color;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {_offset} = {offset} * .01;
	#
	#vec2 {ratio} = vec2(1., TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y);
	#
	#vec2 {offset_uv} = UV + {_offset};
	#vec2 {pixelated_uv} = floor({offset_uv} * {size} * {ratio}) / ({size} * {ratio});
	#
	#float {dots} = length(fract({offset_uv} * {size} * {ratio}) - vec2(.5)) * 2.;
	#
	#float {value} = rgb2hsv(texture(TEXTURE, {pixelated_uv} - {_offset}).rgb).z;
	#
	#{dots} += {value} * {value_multiplier};
	#{dots} = pow({dots}, 5.);
	#{dots} = clamp({dots}, .0, 1.);
	#
	#vec4 {final_color} = mix({dot_color}, {back_color}, {dots});
	#
	#color = {final_color}.rgb;
	#alpha *= {final_color}.a;
#"
