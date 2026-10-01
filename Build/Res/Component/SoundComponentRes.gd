#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
@abstract class_name SoundComponentRes extends ComponentRes

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	return buffer

func _reset_audio() -> void:
	pass
