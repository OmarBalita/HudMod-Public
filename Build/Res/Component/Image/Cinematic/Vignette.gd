#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompVignette extends PassShaderComponentRes

@export var intensity: float = .75
@export var smoothness: float = .3
@export var roundness: float = .4
@export var chromatic_aberration: float = .01
@export var vignette_color: Color
@export var vignette_texture: String:
	set(val):
		vignette_texture = val
		texture = MediaCache.get_texture(vignette_texture)
@export var texture_opacity: float

var texture: Texture2D

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"intensity": export(float_args(intensity, .0, 5., .001)),
		&"smoothness": export(float_args(smoothness, .0, 1., .001)),
		&"roundness": export(float_args(roundness, .0, 1., .001)),
		&"chromatic_aberration": export(float_args(chromatic_aberration, .0, .05, .001, .001)),
		&"vignette_color": export(color_args(vignette_color)),
		&"vignette_texture": export(string_args(vignette_texture)),
		&"texture_opacity": export(float_args(texture_opacity, .0, 1., .001))
	}

func _process(frame: int) -> void:
	set_shader_props({
		&"intensity": intensity,
		&"smoothness": smoothness,
		&"roundness": roundness,
		&"chromatic_aberration": chromatic_aberration,
		&"vignette_color": vignette_color,
		&"vignette_texture": texture,
		&"texture_opacity": texture_opacity
	})

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Vignette.gdshader")


