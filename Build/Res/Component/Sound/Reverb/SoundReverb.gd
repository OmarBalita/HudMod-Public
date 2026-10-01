#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompSoundReverb extends SoundComponentRes

@export var room_size: float = 0.5
@export var damping: float = 0.5
@export var wet: float = 0.3

const COMB_DELAYS_MS: Array[float] = [32.4, 33.7, 31.0, 29.6]
const ALLPASS_DELAYS_MS: Array[float] = [4.7, 11.6]
const ALLPASS_GAIN: float = 0.5

var _comb_states: Array[Dictionary] = [{}, {}, {}, {}]
var _allpass_states: Array[Dictionary] = [{}, {}]

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"room_size": export(float_args(room_size, 0.0, 0.98, .001)),
		&"damping": export(float_args(damping, 0.0, 1.0, .001)),
		&"wet": export(float_args(wet, 0.0, 1.0, .001)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var wet_buffer: PackedVector2Array
	
	for i in COMB_DELAYS_MS.size():
		var delay_samples: int = int(COMB_DELAYS_MS[i] * 0.001 * sample_rate)
		var result: Dictionary = AudioMixer.process_comb_filter(buffer, _comb_states[i], delay_samples, room_size, damping)
		_comb_states[i] = result["state"]
		wet_buffer = result["output"] if wet_buffer.is_empty() else AudioMixer.mix_two(wet_buffer, result["output"])
	
	for i in ALLPASS_DELAYS_MS.size():
		var delay_samples: int = int(ALLPASS_DELAYS_MS[i] * 0.001 * sample_rate)
		var result: Dictionary = AudioMixer.process_allpass_filter(wet_buffer, _allpass_states[i], delay_samples, ALLPASS_GAIN)
		_allpass_states[i] = result["state"]
		wet_buffer = result["output"]
	
	return AudioMixer.mix_dry_wet(buffer, wet_buffer, wet)

func _reset_audio() -> void:
	_comb_states = [{}, {}, {}, {}]
	_allpass_states = [{}, {}]
