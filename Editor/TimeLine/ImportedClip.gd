class_name ImportedClip extends MediaClip

@export var type: int

func clamp_target_length(target_length: int) -> int:
	var max_length: int = MediaServer.get_media_default_length(type, clip_res.key_as_path) * ProjectServer.fps
	return clamp(target_length, 1, max_length - clip_res.from if type in [2, 3] else +INF)

func clamp_target_clip_pos(target_clip_pos: int) -> int:
	var clip_end: int = clip_pos + clip_res.length
	var clip_pos_max: int = clip_end - 1
	return clamp(target_clip_pos, clip_pos - clip_res.from if type in [2, 3] else -INF, clip_pos_max)
