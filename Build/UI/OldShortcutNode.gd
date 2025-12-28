class_name OldShortcutNode extends Node

signal shortcut_key_pressed(key: Array)
signal shortcut_key_released(key: Array)
signal shortcut_button_pressed(key: Array)
signal shortcut_button_released(key: Array)


@export var enabled:= true

func set_enabled(val: bool) -> void:
	enabled = val
func get_enabled() -> bool:
	return enabled

@export var focus_control: FocusControl


var key_shortcuts: Dictionary[Array, Callable]
var key_release_shortcuts: Dictionary[Array, Callable]
var button_shortcuts: Dictionary[Array, Callable]
var button_release_shortcuts: Dictionary[Array, Callable]


var events_pressed: Array



func _input(event: InputEvent) -> void:
	
	if not enabled or not focus_control.is_focus:
		return
	
	var is_pressed = event.is_pressed()
	
	if event is InputEventMouseButton:
		var key = event.button_index
		var result_key = [event.get_modifiers_mask(), key]
		call_method_from_shortcut(button_shortcuts if is_pressed else button_release_shortcuts, result_key)
		if is_pressed: events_pressed.append(key)
		else: events_pressed.erase(key)
	elif event is InputEventKey:
		var key = event.keycode
		var result_key = [event.get_modifiers_mask(), key]
		call_method_from_shortcut(key_shortcuts if is_pressed else key_release_shortcuts, result_key)
		if is_pressed: events_pressed.append(key)
		else: events_pressed.erase(key)


func call_method_from_shortcut(shortcut_lib: Dictionary[Array, Callable], key: Array) -> void:
	if key in shortcut_lib:
		var callable = shortcut_lib[key]
		if callable:
			callable.call()
		match shortcut_lib:
			key_shortcuts: shortcut_key_pressed.emit(key)
			key_release_shortcuts: shortcut_key_released.emit(key)
			button_shortcuts: shortcut_button_pressed.emit(key)
			button_release_shortcuts: shortcut_button_released.emit(key)


func create_key_shortcut(key_mask: int, key: int, callable: Callable) -> void:
	key_shortcuts[[key_mask, key]] = callable

func create_key_release_shortcut(key_mask: int, key: int, callable: Callable) -> void:
	key_release_shortcuts[[key_mask, key]] = callable

func create_button_shortcut(key_mask: int, key: int, callable: Callable) -> void:
	button_shortcuts[[key_mask, key]] = callable

func create_button_release_shortcut(key_mask: int, key: int, callable: Callable) -> void:
	button_release_shortcuts[[key_mask, key]] = callable






