#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Founded by Omar Mohammed Balita.                                       ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
## ----------------------------------------------------------------------- ##
##  GPLv3                                                                  ##
#############################################################################
class_name CompSoundNoiseGate extends SoundComponentRes

const DETECTOR_RELEASE_MS: float = 20.0

@export var threshold_db: float = -45.0
@export var floor_db: float = -80.0
@export var attack_ms: float = 1.0
@export var hold_ms: float = 50.0
@export var release_ms: float = 150.0

var _envelope: float
var _gain: float = 1.0
var _hold_counter: int

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"threshold_db": export(float_args(threshold_db, -90.0, 0.0, .1)),
		&"floor_db": export(float_args(floor_db, -80.0, 0.0, .1)),
		&"attack_ms": export(float_args(attack_ms, 0.1, 100.0, .1)),
		&"hold_ms": export(float_args(hold_ms, 0.0, 1000.0, 1.0)),
		&"release_ms": export(float_args(release_ms, 1.0, 2000.0, 1.0)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var threshold: float = db_to_linear(threshold_db)
	var floor_gain: float = db_to_linear(floor_db)
	var detector_coeff: float = exp(-1.0 / (DETECTOR_RELEASE_MS * 0.001 * sample_rate))
	var attack_coeff: float = exp(-1.0 / (maxf(attack_ms, 0.01) * 0.001 * sample_rate))
	var release_coeff: float = exp(-1.0 / (maxf(release_ms, 0.01) * 0.001 * sample_rate))
	var hold_samples: int = int(hold_ms * 0.001 * sample_rate)

	var output: PackedVector2Array = buffer.duplicate()
	for i in buffer.size():
		var frame: Vector2 = buffer[i]
		var level: float = maxf(absf(frame.x), absf(frame.y))
		_envelope = level if level > _envelope else detector_coeff * _envelope + (1.0 - detector_coeff) * level

		var target: float
		if _envelope >= threshold:
			_hold_counter = hold_samples
			target = 1.0
		elif _hold_counter > 0:
			_hold_counter -= 1
			target = 1.0
		else:
			target = floor_gain

		var coeff: float = attack_coeff if target > _gain else release_coeff
		_gain = coeff * _gain + (1.0 - coeff) * target
		output[i] = frame * _gain

	return output

func _reset_audio() -> void:
	_envelope = 0.0
	_gain = 1.0
	_hold_counter = 0
