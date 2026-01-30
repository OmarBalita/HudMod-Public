class_name ProjectRes extends Resource

signal resolution_changed(resolution: Vector2i)
signal curr_length_changed(length: float)
signal fps_changed(fps: int)

static var default_length: int = 900 # as Frames

@export var resolution: Vector2i = Vector2i(1024, 720):
	set(val):
		resolution = val
		resolution_changed.emit(resolution)
@export var curr_length: int = default_length:
	set(val):
		val = max(default_length, val)
		if curr_length != val:
			curr_length = val
			curr_length_changed.emit(curr_length)
@export var fps: int = 30:
	set(val):
		fps = val
		delta = 1.0 / fps
		fps_changed.emit(fps)

@export var root_clip_res: RootClipRes = RootClipRes.new()

var aspect_ratio: Vector2
var delta: float = 1.0 / fps

func get_resolution() -> Vector2i: return Vector2i(1024, 720)
func get_curr_length() -> int: return curr_length
func get_fps() -> int: return fps
func get_root_clip_res() -> RootClipRes: return root_clip_res

func set_resolution(new_val: Vector2) -> void: resolution = new_val
func set_curr_length(new_val: int) -> void: curr_length = new_val
func set_fps(new_val: int) -> void: fps = new_val
func set_root_clip_res(new_val: RootClipRes) -> void: root_clip_res = new_val


