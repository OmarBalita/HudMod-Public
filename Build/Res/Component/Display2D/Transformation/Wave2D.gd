#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompWave2D extends ComponentRes

enum WaveMethod {
	WAVE_METHOD_SIN = 0,
	WAVE_METHOD_COS
}

@export var enable_x: bool = false
@export var enable_y: bool = true
@export var wave_method: WaveMethod
@export var x_offset: float = .0
@export var speed: float = 10.
@export var domain: float = 100.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var enabled_cond: Array = [
		func() -> bool:
			return self.enable_x or self.enable_y,
		[true]
	]
	return {
		&"enable_x": export(bool_args(enable_x)),
		&"enable_y": export(bool_args(enable_y)),
		&"wave_method": export(options_args(wave_method, WaveMethod)),
		&"x_offset": export(float_args(x_offset)),
		&"speed": export(float_args(speed), enabled_cond),
		&"domain": export(float_args(domain), enabled_cond)
	}

func _process(frame: int) -> void:
	submit_stacked_value(&"position", get_wave_result_at(frame, enable_x, enable_y, wave_method, x_offset, speed, domain))

func _apply_custom_stacked_values(frame: int, dict: Dictionary[StringName, Array]) -> void:
	apply_stacked_value(dict, &"position", get_wave_result_at(frame,
		sample_or_get(self, &"enable_x", frame),
		sample_or_get(self, &"enable_y", frame),
		sample_or_get(self, &"wave_method", frame),
		sample_or_get(self, &"x_offset", frame),
		sample_or_get(self, &"speed", frame),
		sample_or_get(self, &"domain", frame)
	))

func get_wave_result_at(frame: int, enable_x: bool, enable_y: bool, wave_method: WaveMethod, x_offset: float, speed: float, domain: float) -> Vector2:
	var method: Callable
	if wave_method == 0:
		method = sin
	else:
		method = cos
	
	var result: float = method.call(deg_to_rad(x_offset + frame) * speed) * domain
	var vec2_result: Vector2
	
	if enable_x: vec2_result.x = result
	if enable_y: vec2_result.y = result
	return vec2_result
