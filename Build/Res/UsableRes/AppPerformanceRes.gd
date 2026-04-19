class_name AppPerformanceRes extends UsableRes

@export var low_quality_for_playback: bool = true
@export var frames_dropped: int = 0
@export_range(50, 5000) var video_max_frame_cache: int = 500
@export_range(.1, 1., .1) var video_scale_factor: float = 1.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"low_quality_for_playback": export(bool_args(low_quality_for_playback)),
		&"frames_dropped": export(int_args(frames_dropped, 0, 3)),
		&"video_max_frame_cache": export(int_args(video_max_frame_cache, 50, 5000)),
		&"video_scale_factor": export(float_args(video_scale_factor, .1, 1., .1))
	}
