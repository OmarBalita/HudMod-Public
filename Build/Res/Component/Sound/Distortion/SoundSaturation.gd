#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompSoundSaturation extends SoundComponentRes

@export var drive: float = 0.3
@export var mix: float = 1.0

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"drive": export(float_args(drive, 0.0, 1.0, .001)),
		&"mix": export(float_args(mix, 0.0, 1.0, .001)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	return AudioMixer.process_saturation(buffer, drive, mix)
