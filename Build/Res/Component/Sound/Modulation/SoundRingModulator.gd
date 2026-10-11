#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompSoundRingModulator extends SoundComponentRes

@export var frequency_hz: float = 120.0
@export var mix: float = 1.0

var _phase: float

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"frequency_hz": export(float_args(frequency_hz, 1.0, 4000.0, .1)),
		&"mix": export(float_args(mix, 0.0, 1.0, .001)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var phase_step: float = frequency_hz / sample_rate

	var output: PackedVector2Array = buffer.duplicate()
	for i in buffer.size():
		var carrier: float = sin(_phase * TAU)
		output[i] *= (1.0 - mix) + carrier * mix
		_phase = fmod(_phase + phase_step, 1.0)

	return output

func _reset_audio() -> void:
	_phase = 0.0
