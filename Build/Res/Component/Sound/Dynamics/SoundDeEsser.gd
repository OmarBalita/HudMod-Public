#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Founded by Omar Mohammed Balita.                                       ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
## ----------------------------------------------------------------------- ##
##  GPLv3                                                                  ##
#############################################################################
class_name CompSoundDeEsser extends SoundComponentRes

const BAND_Q: float = 1.2
const RATIO: float = 4.0
const ATTACK_MS: float = 1.0
const RELEASE_MS: float = 60.0

@export var frequency_hz: float = 6500.0
@export var threshold_db: float = -30.0
@export var max_reduction_db: float = 12.0

var _band_state: PackedFloat32Array
var _envelope: float

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"frequency_hz": export(float_args(frequency_hz, 2000.0, 12000.0, 1.0)),
		&"threshold_db": export(float_args(threshold_db, -60.0, 0.0, .1)),
		&"max_reduction_db": export(float_args(max_reduction_db, 0.0, 24.0, .1)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var coeffs: PackedFloat32Array = AudioMixer.compute_biquad_bandpass(frequency_hz, BAND_Q, sample_rate)
	var result: Dictionary = AudioMixer.process_biquad(buffer, coeffs, _band_state)
	_band_state = result["state"]
	var band: PackedVector2Array = result["output"]

	var attack_coeff: float = exp(-1.0 / (ATTACK_MS * 0.001 * sample_rate))
	var release_coeff: float = exp(-1.0 / (RELEASE_MS * 0.001 * sample_rate))

	# Only the sibilant band is attenuated, the rest of the voice passes untouched.
	var output: PackedVector2Array = buffer.duplicate()
	for i in buffer.size():
		var band_frame: Vector2 = band[i]
		var level: float = maxf(absf(band_frame.x), absf(band_frame.y))
		var coeff: float = attack_coeff if level > _envelope else release_coeff
		_envelope = coeff * _envelope + (1.0 - coeff) * level

		var envelope_db: float = linear_to_db(maxf(_envelope, 1e-6))
		if envelope_db <= threshold_db:
			continue

		var reduction_db: float = minf((envelope_db - threshold_db) * (1.0 - 1.0 / RATIO), max_reduction_db)
		output[i] += band_frame * (db_to_linear(-reduction_db) - 1.0)

	return output

func _reset_audio() -> void:
	_band_state = PackedFloat32Array()
	_envelope = 0.0
