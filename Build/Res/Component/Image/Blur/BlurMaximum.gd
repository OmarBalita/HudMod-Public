#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompBlurMax extends PassShaderComponentRes

@export var blur_amount: float = 1.
@export var circular: bool = false
@export_range(1, 32) var quality: int = 4

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"blur_amount": export(float_args(blur_amount, .0, 500., .001)),
		&"circular": export(bool_args(circular)),
		&"quality": export(int_args(quality, 1, 32))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/BlurMaximum.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"blur_amount", blur_amount)
	set_shader_prop(&"circular", circular)
	set_shader_prop(&"quality", quality)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {blur_amount}: hint_range(.0, 96.);
#uniform bool {circular};
#uniform int {quality}: hint_range(1, 32);
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#float {step_size} = max(1., {blur_amount} / float({quality})); 
	#
	#vec4 {max_color} = vec4(.0);
	#float {blur_amount_sq} = max(1., {blur_amount} * {blur_amount});
	#
	#for (float x = -{blur_amount}; x <= {blur_amount}; x += {step_size}) {
		#for (float y = -{blur_amount}; y <= {blur_amount}; y += {step_size}) {
			#
			#if ({circular} && (x*x + y*y > {blur_amount_sq})) continue;
			#
			#vec2 {offset} = vec2(x, y) * TEXTURE_PIXEL_SIZE;
			#vec4 {curr_color} = texture(TEXTURE, UV + {offset});
			#
			#{max_color} = max({max_color}, {curr_color});
		#}
	#}
	#
	#color = {max_color}.rgb;
	#alpha = {max_color}.a;
#"
