#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompSoundFilter extends SoundComponentRes

enum Mode { LOW_PASS, HIGH_PASS }

@export var mode: Mode = Mode.LOW_PASS
@export var cutoff_hz: float = 2000.0
@export var resonance: float = 0.707

var _state: PackedFloat32Array

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"mode": export(options_args(mode, Mode)),
		&"cutoff_hz": export(float_args(cutoff_hz, 20.0, 20000.0, 1.0)),
		&"resonance": export(float_args(resonance, 0.1, 10.0, .01)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var coeffs: PackedFloat32Array
	match mode:
		Mode.LOW_PASS: coeffs = AudioMixer.compute_biquad_lowpass(cutoff_hz, resonance, sample_rate)
		Mode.HIGH_PASS: coeffs = AudioMixer.compute_biquad_highpass(cutoff_hz, resonance, sample_rate)

	var result: Dictionary = AudioMixer.process_biquad(buffer, coeffs, _state)
	_state = result["state"]
	return result["output"]

func _reset_audio() -> void:
	_state = PackedFloat32Array()
