#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompSoundCompressor extends SoundComponentRes

@export var threshold_db: float = -18.0
@export var ratio: float = 4.0
@export var attack_ms: float = 10.0
@export var release_ms: float = 100.0

var _state: Dictionary

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"threshold_db": export(float_args(threshold_db, -60.0, 0.0, .1)),
		&"ratio": export(float_args(ratio, 1.0, 20.0, .1)),
		&"attack_ms": export(float_args(attack_ms, 0.1, 200.0, .1)),
		&"release_ms": export(float_args(release_ms, 1.0, 1000.0, 1.0)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var result: Dictionary = AudioMixer.process_compressor(buffer, _state, threshold_db, ratio, attack_ms, release_ms, sample_rate)
	_state = result["state"]
	return result["output"]

func _reset_audio() -> void:
	_state = {}
