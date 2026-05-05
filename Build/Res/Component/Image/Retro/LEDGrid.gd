#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompLEDGrid extends PassShaderComponentRes

@export_range(8, 256) var grid_columns: int = 64
@export_range(8, 256) var grid_rows: int = 64

@export_range(1., 5.) var led_brightness: float = 2.5
@export_range(.1, .8) var led_radius: float = .4
@export_range(.0, 1.) var glow_size: float = .3
@export_range(.0, 1.) var glow_strength: float = .5
@export_range(.0, 32.) var color_quantization: float = .0

@export var background_color: Color = Color(.0, .0, .0)
@export_range(.0, 1.) var background_opacity: float = .9

@export_range(.0, 1.) var glow_pulse: float = .0
@export_range(.0, .2) var curvature: float = .05

@export var enable_dither: bool = true
@export var enable_flicker: bool = true

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"grid_columns": export(int_args(grid_columns, 8, 256)),
		&"grid_rows": export(int_args(grid_rows, 8, 256)),
		&"led_brightness": export(float_args(led_brightness, 1., 5.)),
		&"led_radius": export(float_args(led_radius, .1, .8)),
		&"glow_size": export(float_args(glow_size, .0, 1.)),
		&"glow_strength": export(float_args(glow_strength, .0, 1.)),
		&"color_quantization": export(float_args(color_quantization, .0, 32.)),
		&"background_color": export(color_args(background_color)),
		&"background_opacity": export(float_args(background_opacity)),
		&"glow_pulse": export(float_args(glow_pulse, .0, 1.)),
		&"curvature": export(float_args(curvature, .0, .2)),
		&"enable_dither": export(bool_args(enable_dither)),
		&"enable_flicker": export(bool_args(enable_flicker))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/LEDGrid.gdshader")

func _process(frame: int) -> void:
	set_shader_props({
		&"grid_columns": grid_columns,
		&"grid_rows": grid_rows,
		&"led_brightness": led_brightness,
		&"led_radius": led_radius,
		&"glow_size": glow_size,
		&"glow_strength": glow_strength,
		&"color_quantization": color_quantization,
		&"background_color": background_color,
		&"background_opacity": background_opacity,
		&"glow_pulse": glow_pulse,
		&"curvature": curvature,
		&"enable_dither": enable_dither,
		&"enable_flicker": enable_flicker
	})
