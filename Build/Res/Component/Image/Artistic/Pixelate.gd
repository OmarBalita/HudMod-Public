#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompPixelate extends PassShaderComponentRes

@export var pixel_size: int = 32

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {&"pixel_size": export(int_args(pixel_size, 1, 12800))}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Pixelate.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"pixel_size", pixel_size)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform int {pixel_size}: hint_range(1, 12800);
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {size} = vec2(textureSize(TEXTURE, 0));
	#vec2 {pixelated_uv} = round(UV * {size} / float({pixel_size})) * float({pixel_size}) / {size};
	#color.rgb = texture(TEXTURE, {pixelated_uv}).rgb;
#"
