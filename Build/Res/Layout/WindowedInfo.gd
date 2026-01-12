class_name WindowedInfo extends Resource

@export var editor_name: StringName
@export var screen: int = 0
@export var window_pos: Vector2i
@export var window_size: Vector2i
@export var window_mode: Window.Mode

static func new_windowed_info(_editor_name: StringName, _screen: int, _window_pos: Vector2i, _window_size: Vector2i, _window_mode: Window.Mode) -> WindowedInfo:
	var windowed_info:= WindowedInfo.new()
	windowed_info.editor_name = _editor_name
	windowed_info.screen = _screen
	windowed_info.window_pos = _window_pos
	windowed_info.window_size = _window_size
	windowed_info.window_mode = _window_mode
	return windowed_info

func get_screen() -> int: return screen
func get_window_pos() -> Vector2i: return window_pos
func get_window_size() -> Vector2i: return window_size
func get_window_mode() -> Window.Mode: return window_mode

func set_screen(new_val: int) -> void: screen = new_val
func set_wdinow_pos(new_val: Vector2i) -> void: window_pos = new_val
func set_window_size(new_val: Vector2i) -> void: window_size = new_val
func set_window_mode(new_val: Window.Mode) -> void: window_mode = new_val

func register_window(window: Window) -> void:
	window.current_screen = screen
	window.position = window_pos
	window.size = window_size
	window.mode = window_mode






