#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompSoundDelay extends SoundComponentRes

@export var delay_time: float = 0.3
@export var feedback: float = 0.35
@export var mix: float = 0.5

var _state: Dictionary

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"delay_time": export(float_args(delay_time, 0.01, 2.0, .001)),
		&"feedback": export(float_args(feedback, 0.0, 0.95, .001)),
		&"mix": export(float_args(mix, 0.0, 1.0, .001)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var delay_samples: int = int(delay_time * sample_rate)
	var result: Dictionary = AudioMixer.process_delay_line(buffer, _state, delay_samples, feedback, mix)
	_state = result["state"]
	return result["output"]

func _reset_audio() -> void:
	_state = {}
