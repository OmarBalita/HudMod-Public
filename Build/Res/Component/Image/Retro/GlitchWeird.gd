#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompGlitchWeird extends PassShaderComponentRes

@export var glitch_chance: float = .2
@export var glitch_speed: float = 7.
@export var slice_density: float = 14.
@export var slice_strength: float = .38
@export var shake_strength: float = .02
@export var chroma_offset: float = .016
@export var noise_strength: float = .2
@export var color_flash_strength: float = .4
@export var scanline_strength: float = .18
@export var local_warp_strength: float = .14
@export var flip_chance: float = .15

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"glitch_chance": export(float_args(glitch_chance, .0, 1.)),
		&"glitch_speed": export(float_args(glitch_speed)),
		&"slice_density": export(float_args(slice_density)),
		&"slice_strength": export(float_args(slice_strength)),
		&"shake_strength": export(float_args(shake_strength)),
		&"chroma_offset": export(float_args(chroma_offset)),
		&"noise_strength": export(float_args(noise_strength)),
		&"color_flash_strength": export(float_args(color_flash_strength)),
		&"scanline_strength": export(float_args(scanline_strength)),
		&"local_warp_strength": export(float_args(local_warp_strength)),
		&"flip_chance": export(float_args(flip_chance))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/GlitchWeird.gdshader")

func _process(frame: int) -> void:
	set_shader_props({
		&"glitch_chance": glitch_chance,
		&"glitch_speed": glitch_speed,
		&"slice_density": slice_density,
		&"slice_strength": slice_strength,
		&"shake_strength": shake_strength,
		&"chroma_offset": chroma_offset,
		&"noise_strength": noise_strength,
		&"color_flash_strength": color_flash_strength,
		&"scanline_strength": scanline_strength,
		&"local_warp_strength": local_warp_strength,
		&"flip_chance": flip_chance
	})
