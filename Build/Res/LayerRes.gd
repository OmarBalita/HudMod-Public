class_name LayerRes extends Resource


@export var clips: Dictionary[int, MediaClipRes]

@export var locked: bool
@export var hidden: bool

@export_group("Customization", "custom")
@export var custom_name: StringName
@export var custom_color: Color = Color.GRAY
@export var custom_size: int = 50

func get_clips() -> Dictionary[int, MediaClipRes]: return clips
func set_clips(new_val: Dictionary[int, MediaClipRes]) -> void: clips = new_val
func get_locked() -> bool: return locked
func set_locked(new_val: bool) -> void: locked = new_val
func get_hidden() -> bool: return hidden
func set_hidden(new_val: bool) -> void: hidden = new_val

func get_custom_name() -> StringName: return custom_name
func set_custom_name(new_val: StringName) -> void: custom_name = new_val
func get_custom_color() -> Color: return custom_color
func set_custom_color(new_val: Color) -> void: custom_color = new_val
func get_custom_size() -> int: return custom_size
func set_custom_size(new_val: int) -> void: custom_size = new_val

func get_clip_res(frame: int) -> MediaClipRes:
	return clips[frame]

func add_clip_res(frame: int, clip_res: MediaClipRes) -> void:
	clips[frame] = clip_res

func remove_clip_res(frame: int) -> void:
	clips.erase(frame)

func is_place_unoccupied(frame: int, media_length: int, media_ignored: Array = []) -> bool:
	
	var frame_out: int = frame + media_length
	
	for other_frame: int in clips.keys():
		var media: MediaClipRes = clips.get(other_frame)
		if media_ignored.has(media): continue
		var time_end: int = other_frame + media.length
		if not (time_end <= frame or frame_out <= other_frame):
			return false
	
	return true

func duplicate_layer_res() -> LayerRes:
	
	var dupl_res: LayerRes = duplicate()
	var new_clips: Dictionary[int, MediaClipRes] = {}
	
	for frame: int in clips:
		new_clips[frame] = clips[frame].duplicate_media_res()
	
	dupl_res.clips = new_clips
	
	return dupl_res




