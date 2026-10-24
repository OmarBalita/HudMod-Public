#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Founded by Omar Mohammed Balita.                                       ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
## ----------------------------------------------------------------------- ##
##  GPLv3                                                                  ##
#############################################################################
class_name CompSoundTremolo extends SoundComponentRes

enum Shape { SINE, TRIANGLE, SQUARE }

const SQUARE_SOFTNESS: float = 6.0

@export var shape: Shape = Shape.SINE
@export var rate_hz: float = 5.0
@export var depth: float = 0.5

var _phase: float

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"shape": export(options_args(shape, Shape)),
		&"rate_hz": export(float_args(rate_hz, 0.1, 30.0, .01)),
		&"depth": export(float_args(depth, 0.0, 1.0, .001)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var phase_step: float = rate_hz / sample_rate

	var output: PackedVector2Array = buffer.duplicate()
	for i in buffer.size():
		var lfo: float
		match shape:
			Shape.SINE: lfo = sin(_phase * TAU)
			Shape.TRIANGLE: lfo = 1.0 - 4.0 * absf(_phase - 0.5)
			Shape.SQUARE: lfo = clampf(sin(_phase * TAU) * SQUARE_SOFTNESS, -1.0, 1.0)

		output[i] *= 1.0 - depth * (0.5 - 0.5 * lfo)
		_phase = fmod(_phase + phase_step, 1.0)

	return output

func _reset_audio() -> void:
	_phase = 0.0
