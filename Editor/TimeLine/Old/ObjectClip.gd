class_name ObjectClip extends MediaClip

func clamp_target_length(target_length: int) -> int:
	return clamp(target_length, 1, clip_res.object_res.get_max_length() - clip_res.from)

func clamp_target_clip_pos(target_clip_pos: int) -> int:
	var clip_end: int = clip_pos + clip_res.length
	var clip_pos_max: int = clip_end - 1
	return clamp(target_clip_pos, clip_pos - clip_res.from + clip_res.object_res.get_min_from(), clip_pos_max)
