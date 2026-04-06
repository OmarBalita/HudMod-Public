class_name LayerRes extends Resource

signal lock_changed(to: bool)
signal hidden_changed(to: bool)

@export var clips: Dictionary[int, MediaClipRes]:
	set(val):
		clips = val
		clips.sort()

@export var locked: bool:
	set(val):
		locked = val
		lock_changed.emit(val)

@export var hidden: bool:
	set(val):
		
		hidden = val
		hidden_changed.emit(val)
		
		if displayed_clip_res and displayed_clip_res is Display2DClipRes:
			(displayed_clip_res.curr_node as CanvasItem).visible = not hidden

@export_group("Customization", "custom")
@export var custom_name: StringName
@export var custom_color: Color = Color.GRAY
@export var custom_size: int = 50

var displayed_frame: int
var displayed_clip_res: MediaClipRes

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
	clips.sort()

func remove_clip_res(frame: int) -> void:
	if frame == displayed_frame and displayed_clip_res:
		PlaybackServer.free_clip(displayed_clip_res)
		displayed_clip_res = null
	clips.erase(frame)

func pop_clip_res(frame: int) -> MediaClipRes:
	var clip_res: MediaClipRes = clips[frame]
	remove_clip_res(frame)
	return clip_res



func is_place_unoccupied(frame: int, media_length: int, ignored_clips: Array[MediaClipRes] = []) -> bool:
	
	var frame_out: int = frame + media_length
	
	for other_frame: int in clips.keys():
		var clip_res: MediaClipRes = clips.get(other_frame)
		if ignored_clips.has(clip_res): continue
		var time_end: int = other_frame + clip_res.length
		if not (time_end <= frame or frame_out <= other_frame):
			return false
	
	return not locked


func get_left_limit_at(pos: int) -> float:
	var target: float = -INF
	for frame: int in clips:
		var end: int = frame + clips[frame].length
		if end > pos:
			break
		target = end
	return target

func get_right_limit_at(pos: int) -> float:
	for frame: int in clips:
		if frame >= pos:
			return frame
	return INF


func duplicate_layer_res() -> LayerRes:
	
	var dupl_res: LayerRes = duplicate()
	var new_clips: Dictionary[int, MediaClipRes] = {}
	
	for frame: int in clips:
		new_clips[frame] = clips[frame].duplicate_media_res()
	
	dupl_res.clips = new_clips
	
	return dupl_res




