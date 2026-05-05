#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompRays extends PassShaderComponentRes

@export var position: Vector2
@export var tint: Color = Color.WHITE
@export var brightness: float  = 1.2
@export var length: float = .8
@export var threshold: float = .5
@export var radius: float = 1.
@export var darkness: float = .5
@export var darkness_threshold: float = .5
@export var quality: int = 32

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"position": export(vec2_args(position)),
		&"tint": export(color_args(tint)),
		&"brightness": export(float_args(brightness, .0, 5.)),
		&"length": export(float_args(length, .0, 1.)),
		&"threshold": export(float_args(threshold, .0, 1.)),
		&"radius": export(float_args(radius, .0, 2.)),
		&"darkness": export(float_args(darkness, .0, 1.)),
		&"darkness_threshold": export(float_args(darkness_threshold, .0, 1.)),
		&"quality": export(int_args(quality, 8, 256))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Rays.gdshader")

func _process(frame: int) -> void:
	set_shader_props({
		&"position": position,
		&"tint": tint,
		&"brightness": brightness,
		&"_length": length,
		&"threshold": threshold,
		&"radius": radius,
		&"darkness": darkness,
		&"darkness_threshold": darkness_threshold,
		&"quality": quality
	})

