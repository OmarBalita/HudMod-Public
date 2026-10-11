#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
## ----------------------------------------------------------------------- ##
##  GPLv3                                                                  ##
#############################################################################
class_name CompSoundAutoPan extends SoundComponentRes

@export var rate_hz: float = 0.5
@export var depth: float = 1.0

var _phase: float

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"rate_hz": export(float_args(rate_hz, 0.01, 20.0, .01)),
		&"depth": export(float_args(depth, 0.0, 1.0, .001)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var phase_step: float = rate_hz / sample_rate

	# Same pan law as AudioMixer.apply_pan, so a centered sweep matches CompSoundGain.
	var output: PackedVector2Array = buffer.duplicate()
	for i in buffer.size():
		var pan: float = sin(_phase * TAU) * depth
		var left_gain: float = 1.0 if pan <= 0.0 else 1.0 - pan
		var right_gain: float = 1.0 if pan >= 0.0 else 1.0 + pan
		var frame: Vector2 = buffer[i]
		output[i] = Vector2(frame.x * left_gain, frame.y * right_gain)
		_phase = fmod(_phase + phase_step, 1.0)

	return output

func _reset_audio() -> void:
	_phase = 0.0
