class_name RootClipRes extends MediaClipRes

static func is_media_clip_spawnable() -> bool: return false

func _new_layer() -> LayerRes:
	return RootLayerRes.new()

func add_clips(layer_idx: int, frame: int, clips_ress: Array[MediaClipRes], place_method_idx: int = 0, emit_add: bool = true) -> Dictionary[Vector2i, MediaClipRes]:
	var placed_clips_ress:= super(layer_idx, frame, clips_ress, place_method_idx, emit_add)
	update_root_length()
	return placed_clips_ress

func add_clips_by_coords(clips_ress: Dictionary[Vector2i, MediaClipRes], place_method_idx: int = 0, emit_add: bool = true) -> Dictionary[Vector2i, MediaClipRes]:
	var placed_clips_ress:= super(clips_ress, place_method_idx, emit_add)
	update_root_length()
	return placed_clips_ress

func remove_clips(coords: Array[Vector2i], emit_remove: bool = true) -> void:
	super(coords, emit_remove)
	update_root_length()

func move_clips(from_coords: Array[Vector2i], to_coords: Array[Vector2i], place_method_idx: int, emit_move: bool = true) -> Dictionary[Vector2i, MediaClipRes]:
	var placed_clips_ress:= super(from_coords, to_coords, place_method_idx, emit_move)
	update_root_length()
	return placed_clips_ress

func update_root_length() -> void:
	length = EditorServer.editor_settings.project_min_length_f
	for layer: LayerRes in layers:
		var clips: Dictionary[int, MediaClipRes] = layer.clips
		for frame: int in clips:
			var clip_res: MediaClipRes = clips[frame]
			length = max(length, frame + clip_res.length)


