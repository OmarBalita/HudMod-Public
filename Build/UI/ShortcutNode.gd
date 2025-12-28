class_name ShortcutNode extends Control

@export var shortcuts: Dictionary[Shortcut, ShortcutInfo]

static func new_event_key(key_code: Key, ctrl_pressed: bool = false, shift_pressed: bool = false, alt_pressed: bool = false) -> InputEventKey:
	var event_key:= InputEventKey.new()
	event_key.keycode = key_code
	event_key.ctrl_pressed = ctrl_pressed
	event_key.shift_pressed = shift_pressed
	event_key.alt_pressed = alt_pressed
	return event_key

static func new_shortcut(events: Array) -> Shortcut:
	var shortcut:= Shortcut.new()
	shortcut.events = events
	return shortcut

func get_shortcuts() -> Dictionary[Shortcut, ShortcutInfo]:
	return shortcuts

func set_shortcuts(new_val: Dictionary[Shortcut, ShortcutInfo]) -> void:
	shortcuts = new_val

func register_shortcut_quickly(name: StringName, function: Callable, events: Array) -> void:
	register_shortcut(new_shortcut(events), ShortcutInfo.new(name, function))

func register_shortcut(key_as_shortcut: Shortcut, val_as_shortcut_info: ShortcutInfo) -> void:
	shortcuts[key_as_shortcut] = val_as_shortcut_info

func register_shortcuts(new_shortcuts: Dictionary[Shortcut, ShortcutInfo]) -> void:
	shortcuts.merge(new_shortcuts)

func _init() -> void:
	set_process_input(get_global_rect().has_point(get_global_mouse_position()) and visible)
	mouse_entered.connect(set_process_input.bind(true))
	mouse_exited.connect(set_process_input.bind(false))
	
	mouse_filter = Control.MOUSE_FILTER_PASS
	IS.expand(self, true, true)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			for shortcut: Shortcut in shortcuts:
				if shortcut.matches_event(event):
					shortcuts[shortcut].function.call()

