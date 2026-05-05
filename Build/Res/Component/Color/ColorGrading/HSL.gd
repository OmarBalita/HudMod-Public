#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompHSL extends SnippetShaderComponentRes

@export var hue_shift: float = .0
@export var saturation: float = 1.
@export var vibrance: float = .0
@export var luminance: float = 1.0

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"hue_shift": export(float_args(hue_shift, -1., 1., .001)),
		&"saturation": export(float_args(saturation, .0, 5., .001)),
		&"vibrance": export(float_args(vibrance, -1., 1., .001)),
		&"luminance": export(float_args(luminance, .0, 10., .001))
}

func _process(frame: int) -> void:
	set_shader_prop(&"hue_shift", hue_shift)
	set_shader_prop(&"saturation", saturation)
	set_shader_prop(&"vibrance", vibrance)
	set_shader_prop(&"luminance", luminance)

func _get_shader_global_params_snip() -> String:
	return "
uniform float {hue_shift}: hint_range(-1., 1.) = .0;
uniform float {saturation}: hint_range(.0, 10.) = 1.;
uniform float {vibrance}: hint_range(-1., 1.) = .0;
uniform float {luminance}: hint_range(.0, 10.) = 1.;
"

func _get_shader_fragment_snip() -> String:
	return "
	// Hue
	color = apply_hue(color, {hue_shift}); // Hue
	color *= {luminance}; // Luminance
	color = apply_sat(color, {saturation}); // Saturation
	color = apply_vibrance(color, {vibrance});
"
