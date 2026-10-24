#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Founded by Omar Mohammed Balita.                                       ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
## ----------------------------------------------------------------------- ##
##  GPLv3                                                                  ##
#############################################################################
class_name CompSoundStereoWidth extends SoundComponentRes

## 0 = mono, 1 = unchanged, 2 = extra wide.
@export var width: float = 1.0
@export var swap_channels: bool = false

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"width": export(float_args(width, 0.0, 2.0, .001)),
		&"swap_channels": export(bool_args(swap_channels)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var output: PackedVector2Array = buffer.duplicate()
	for i in buffer.size():
		var frame: Vector2 = buffer[i]
		var mid: float = (frame.x + frame.y) * 0.5
		var side: float = (frame.x - frame.y) * 0.5 * width
		output[i] = Vector2(mid - side, mid + side) if swap_channels else Vector2(mid + side, mid - side)

	return output
