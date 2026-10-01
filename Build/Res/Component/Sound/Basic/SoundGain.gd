#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
## GPLv3																   ##
#############################################################################
class_name CompSoundGain extends SoundComponentRes

const MAX_DB: float = 24.0
const MIN_DB: float = -80.0

@export var volume_db: float = 0.0
@export var pan: float = 0.0

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"volume_db": export(float_args(volume_db, MIN_DB, MAX_DB)),
		&"pan": export(float_args(pan, -1.0, 1.0, .01)),
	}

func _process_audio(buffer: PackedVector2Array, sample_rate: int) -> PackedVector2Array:
	var gain_linear: float = db_to_linear(volume_db)
	buffer = AudioMixer.apply_gain(buffer, gain_linear)
	buffer = AudioMixer.apply_pan(buffer, pan)
	return buffer
