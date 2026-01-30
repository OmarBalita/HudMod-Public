class_name CompAudioSettings extends ComponentRes

enum MixTarget {
	STEREO,
	SURROUND,
	CENTER
}

@export var volume_db: float = .0
@export var mix_target: AudioStreamPlayer.MixTarget

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"volume_db": export(float_args(volume_db, -80., 24.)),
		&"mix_target": export(options_args(mix_target, MixTarget))
	}

func _process(frame: int) -> void:
	submit_stacked_value(&"volume_db", volume_db)
	submit_stacked_value_with_custom_method(&"mix_target", mix_target, MethodType.SET)
