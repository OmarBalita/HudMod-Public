#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompSoundEQ extends SoundComponentRes

@export var low_gain_db: float = 0.0
@export var mid_gain_db: float = 0.0
@export var high_gain_db: float = 0.0

@export var low_freq: float = 250.0
@export var mid_freq: float = 1000.0
@export var high_freq: float = 4000.0

var _state_low: PackedFloat32Array
var _state_mid: PackedFloat32Array
var _state_high: PackedFloat32Array

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"low_gain_db": export(float_args(low_gain_db, -24.0, 24.0, 0.1)),
		&"mid_gain_db": export(float_args(mid_gain_db, -24.0, 24.0, 0.1)),
		&"high_gain_db": export(float_args(high_gain_db, -24.0, 24.0, 0.1)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var c_low: PackedFloat32Array = AudioMixer.compute_biquad_peaking_eq(low_freq, 0.707, low_gain_db, sample_rate)
	var res_low: Dictionary = AudioMixer.process_biquad(buffer, c_low, _state_low)
	_state_low = res_low["state"]

	var c_mid: PackedFloat32Array = AudioMixer.compute_biquad_peaking_eq(mid_freq, 1.0, mid_gain_db, sample_rate)
	var res_mid: Dictionary = AudioMixer.process_biquad(res_low["output"], c_mid, _state_mid)
	_state_mid = res_mid["state"]

	var c_high: PackedFloat32Array = AudioMixer.compute_biquad_peaking_eq(high_freq, 0.707, high_gain_db, sample_rate)
	var res_high: Dictionary = AudioMixer.process_biquad(res_mid["output"], c_high, _state_high)
	_state_high = res_high["state"]

	return res_high["output"]

func _reset_audio() -> void:
	_state_low = PackedFloat32Array()
	_state_mid = PackedFloat32Array()
	_state_high = PackedFloat32Array()
