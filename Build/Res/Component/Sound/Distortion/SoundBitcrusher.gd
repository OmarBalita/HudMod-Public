#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
## ----------------------------------------------------------------------- ##
##  GPLv3                                                                  ##
#############################################################################
class_name CompSoundBitcrusher extends SoundComponentRes

@export var bit_depth: float = 8.0
@export var downsample: int = 4
@export var mix: float = 1.0

var _held: Vector2
var _counter: int

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"bit_depth": export(float_args(bit_depth, 1.0, 16.0, .01)),
		&"downsample": export(int_args(downsample, 1, 64)),
		&"mix": export(float_args(mix, 0.0, 1.0, .001)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var levels: float = pow(2.0, bit_depth - 1.0)
	var hold_length: int = maxi(downsample, 1)

	var output: PackedVector2Array = buffer.duplicate()
	for i in buffer.size():
		var dry: Vector2 = buffer[i]
		if _counter <= 0:
			_held = (dry * levels).round() / levels
			_counter = hold_length
		_counter -= 1
		output[i] = dry * (1.0 - mix) + _held * mix

	return output

func _reset_audio() -> void:
	_held = Vector2.ZERO
	_counter = 0
