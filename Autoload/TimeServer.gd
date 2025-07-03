extends Node

func frame_to_timecode(frame: int, fps: int = 0) -> String:
	if fps <= 0:
		fps = ProjectServer.fps
	var total_seconds := frame / fps
	var hours := int(total_seconds / 3600)
	var minutes := int((total_seconds % 3600) / 60)
	var seconds := int(total_seconds % 60)
	var frames := int(frame % fps)
	return "%02d:%02d:%02d:%02d" % [hours, minutes, seconds, frames]
