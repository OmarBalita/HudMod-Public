extends Node


func frame_to_seconds(frame: int, fps: int = 0) -> float:
	if fps == 0: fps = ProjectServer.fps
	return float(frame) / fps

func seconds_to_frame(seconds: float, fps: int = 0) -> int:
	if fps == 0: fps = ProjectServer.fps
	return int(seconds * fps)

func map_frames_between_fps(frame: int, from_fps: int = 0, to_fps: int = 0) -> int:
	return seconds_to_frame(frame_to_seconds(frame, from_fps), to_fps)

func localize_frame(curr_frame: int, clip_pos: int) -> int:
	return curr_frame - clip_pos

func globalize_frame(local_frame: int, clip_pos: int) -> int:
	return local_frame + clip_pos

func frame_to_timecode(frame: int, fps: int = 0) -> String:
	if fps == 0: fps = ProjectServer.fps
	var total_seconds := frame / fps
	var hours = int(total_seconds / 3600)
	var minutes = int((total_seconds % 3600) / 60)
	var seconds = int(total_seconds % 60)
	var frames = int(frame % fps)
	return "%02d:%02d:%02d:%02d" % [hours, minutes, seconds, frames]
