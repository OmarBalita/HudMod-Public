class_name KeyboardControl extends PanelContainer

signal key_pressed(key: String)
signal shortcut_recorded(combo: String)

@export_group("Theme")
@export var key_min_size: Vector2 = Vector2(44, 44)
@export var space_key_scale: float = 6.0
@export var key_spacing: float = 6.0

@export_group("Record Mode")
@export var record_mode: bool = false:
	set(value):
		record_mode = value
		_apply_record_mode()


const SPECIAL_KEYS: Dictionary = {
	"Esc": {label = "Esc"},
	
	"F1": {label = "F1"}, "F2": {label = "F2"}, "F3": {label = "F3"}, "F4": {label = "F4"},
	"F5": {label = "F5"}, "F6": {label = "F6"}, "F7": {label = "F7"}, "F8": {label = "F8"},
	"F9": {label = "F9"}, "F10": {label = "F10"}, "F11": {label = "F11"}, "F12": {label = "F12"},
	
	"Backspace": {label = "⌫", wide = 1.8},
	"Tab": {label = "Tab", wide = 1.5},
	"CapsLock": {label = "Caps", wide = 1.8, toggle = true},
	"Enter": {label = "⏎", wide = 1.8},
	"KpEnter": {label = "Enter"},
	"Shift": {label = "⇧", wide = 2.2, toggle = true},
	"Ctrl": {label = "Ctrl", wide = 1.3},
	"Alt": {label = "Alt", wide = 1.3},
	
	"Space": {label = "", wide = 6.0},
	"Left": {label = "←"}, "Up": {label = "↑"}, "Down": {label = "↓"}, "Right": {label = "→"}
}

const SHIFT_SYMBOLS: Dictionary = {
	"`": "~", "1": "!", "2": "@", "3": "#", "4": "$", "5": "%",
	"6": "^", "7": "&", "8": "*", "9": "(", "0": ")",
	"-": "_", "=": "+", "[": "{", "]": "}", "\\": "|",
	";": ":", "'": "\"", ",": "<", ".": ">", "/": "?"
}

const MAIN_KEYS: Array = [
	["Esc", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"],
	["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "Backspace"],
	["Tab", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]", "\\"],
	["CapsLock", "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "Enter"],
	["Shift", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/", "Shift"],
	["Ctrl", "Alt", "Space", "Alt", "Ctrl"],
]

const NAVIGATION_KEYS: Array = [
	["Insert", "Home", "Page Up"],
	["Delete", "End", "Page Down"],
	["Up"],
	["Left", "Down", "Right"]
]

const KEYPAD_KEYS: Array = [
	["Num", "/", "*", "-"],
	["7", "8", "9", "+"],
	["1", "2", "3", "KpEnter"],
	["0", "."]
]

const NON_CHAR_EMIT_KEYS: Array = [
	"Esc", "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
	"Backspace", "Tab", "Enter", "Ctrl", "Alt", "Left", "Up", "Down", "Right"
]

const MODIFIER_KEYS: Array = ["Shift", "Ctrl", "Alt"]

var shift_active: bool = false
var caps_lock_active: bool = false

var keys_box: BoxContainer
var key_buttons: Dictionary = {}

var active_keys: Dictionary = {}

var _physical_key_map: Dictionary = {}
var _string_to_key_map: Dictionary = {}


func _ready() -> void:
	IS.set_base_panel_settings(self, IS.style_body)
	
	var margin = IS.create_margin_container()
	keys_box = IS.create_box_container(16, false)
	
	add_child(margin)
	margin.add_child(keys_box)
	
	_build_physical_key_map()
	spawn_keys()
	_apply_record_mode()
	update_keys_display()
	
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

func spawn_keys() -> void:
	spawn_main_keys()
	spawn_navigation_keys()
	spawn_keypad_keys()
 
func spawn_main_keys() -> void:
	var rows_box: BoxContainer = IS.create_box_container(key_spacing, true)
	keys_box.add_child(rows_box)
	
	var keys_shaping: Dictionary = {
		"Esc": {size_flags_horizontal = Control.SIZE_EXPAND, custom_minimum_size = Vector2(key_min_size.x * 1.7,key_min_size.y)},
		"Backspace": {size_flags_horizontal = Control.SIZE_EXPAND_FILL},
		"Tab": {size_flags_horizontal = Control.SIZE_EXPAND_FILL},
		"\\": {size_flags_horizontal = Control.SIZE_EXPAND_FILL},
		"CapsLock": {size_flags_horizontal = Control.SIZE_EXPAND_FILL},
		"Enter": {size_flags_horizontal = Control.SIZE_EXPAND_FILL},
		"Shift": {size_flags_horizontal = Control.SIZE_EXPAND_FILL},
		"Space": {size_flags_horizontal = Control.SIZE_EXPAND_FILL},
	}
	
	for row: Array in MAIN_KEYS:
		var row_box: BoxContainer = IS.create_box_container(key_spacing, false, {alignment = BoxContainer.ALIGNMENT_CENTER})
		rows_box.add_child(row_box)
		
		for key: String in row:
			row_box.add_child(create_key_button(key, keys_shaping))

func spawn_navigation_keys() -> void:
	var rows_box: BoxContainer = IS.create_box_container(key_spacing, true)
	keys_box.add_child(rows_box)
	
	for row: Array in NAVIGATION_KEYS:
		var row_box: BoxContainer = IS.create_box_container(key_spacing, false, {alignment = BoxContainer.ALIGNMENT_CENTER})
		rows_box.add_child(row_box)
		
		var keys_shaping: Dictionary = {
			"Home": {size_flags_horizontal = Control.SIZE_EXPAND_FILL},
			"End": {size_flags_horizontal = Control.SIZE_EXPAND_FILL},
		}
		
		for key: String in row:
			row_box.add_child(create_key_button(key, keys_shaping, false, 12))
	
	var separation = IS.create_h_line_panel()
	separation.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows_box.add_child(separation)
	rows_box.move_child(separation, 2)


func spawn_keypad_keys() -> void:
	var right_keys: Array = [
		"-", "+", "KpEnter"
	]
	
	var keys_shaping: Dictionary = {
		"0": {size_flags_horizontal = Control.SIZE_EXPAND_FILL, size_flags_stretch_ratio = 2.0},
		".": {size_flags_horizontal = Control.SIZE_EXPAND_FILL},
		"-": {size_flags_vertical = Control.SIZE_EXPAND_FILL, size_flags_stretch_ratio = 1.0},
		"+": {size_flags_vertical = Control.SIZE_EXPAND_FILL, size_flags_stretch_ratio = 2.0},
		"KpEnter": {size_flags_vertical = Control.SIZE_EXPAND_FILL, size_flags_stretch_ratio = 1.0},
	}
	
	var main_row: BoxContainer = IS.create_box_container(key_spacing, false)
	keys_box.add_child(main_row)
	
	var left_col: BoxContainer = IS.create_box_container(key_spacing, true)
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 3.0
	main_row.add_child(left_col)
	
	for row: Array in KEYPAD_KEYS:
		var row_box: BoxContainer = IS.create_box_container(key_spacing, false)
		row_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		left_col.add_child(row_box)
		
		for key: String in row:
			if !right_keys.has(key):
				var btn = create_key_button(key, keys_shaping, true, 12)
				btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row_box.add_child(btn)
	
	var right_col: BoxContainer = IS.create_box_container(key_spacing, true)
	main_row.add_child(right_col)
	
	for key: String in right_keys:
		right_col.add_child(create_key_button(key, keys_shaping, true, 12))

func create_key_button(key: String, more: Dictionary = {}, is_keypad: bool = false, font_size: int = 16) -> Button:
	var button: Button = IS.create_button(
		get_display_text(key, is_keypad), null,
		key, false, false, true,
		{custom_minimum_size = get_key_size(key)}
	)
	
	button.add_theme_font_size_override("font_size", font_size)
	button.set_meta("is_keypad", is_keypad)
	button.button_group = null
	
	if more.has(key):
		ObjectServer.describe(button, more[key])
	
	if is_toggle_key(key) or record_mode:
		button.toggle_mode = true
	
	var button_id: String = key if not key_buttons.has(key) else key + "_2"
	key_buttons[button_id] = button
	
	button.pressed.connect(_on_key_button_pressed.bind(key, is_keypad))
	return button


func is_toggle_key(key: String) -> bool:
	return SPECIAL_KEYS.has(key) and SPECIAL_KEYS[key].get("toggle", false)


func is_letter(key: String) -> bool:
	return key.length() == 1 and key >= "A" and key <= "Z"


func get_key_size(key: String) -> Vector2:
	var wide: float = SPECIAL_KEYS[key].get("wide", 1.0) if SPECIAL_KEYS.has(key) else 1.0
	return Vector2(key_min_size.x * wide, key_min_size.y)


func is_letter_upper() -> bool:
	return shift_active != caps_lock_active


func get_display_text(key: String, is_keypad: bool = false) -> String:
	if SPECIAL_KEYS.has(key):
		return SPECIAL_KEYS[key].label
	
	if is_keypad:
		return key
	
	if is_letter(key):
		return key if is_letter_upper() else key.to_lower()
	if SHIFT_SYMBOLS.has(key):
		return SHIFT_SYMBOLS[key] if shift_active else key
	return key


func update_keys_display() -> void:
	for button_id: String in key_buttons:
		var key: String = button_id.trim_suffix("_2")
		var button: Button = key_buttons[button_id]
		
		var is_keypad: bool = button.get_meta("is_keypad", false)
		button.text = get_display_text(key, is_keypad)
		
		if record_mode:
			button.set_pressed_no_signal(active_keys.has(key))
			continue
		
		if key == "Shift":
			button.set_pressed_no_signal(shift_active)
		elif key == "CapsLock":
			button.set_pressed_no_signal(caps_lock_active)


func consume_shift() -> void:
	if shift_active:
		shift_active = false
		update_keys_display()


func _on_key_button_pressed(key: String, is_keypad: bool = false) -> void:
	if record_mode:
		_toggle_recorded_key(key)
		return
	
	if key == "CapsLock":
		caps_lock_active = !caps_lock_active
		update_keys_display()
		return
	
	if key == "Shift":
		shift_active = !shift_active
		update_keys_display()
		return
	
	if key == "Space":
		key_pressed.emit(" ")
		consume_shift()
		return
	
	if NON_CHAR_EMIT_KEYS.has(key):
		key_pressed.emit(key)
		consume_shift()
		return
	
	key_pressed.emit(get_display_text(key, is_keypad))
	consume_shift()

func _apply_record_mode() -> void:
	if not is_inside_tree():
		return
	
	active_keys.clear()
	for button_id: String in key_buttons:
		var key: String = button_id.trim_suffix("_2")
		var button: Button = key_buttons[button_id]
		button.toggle_mode = is_toggle_key(key) or record_mode
		button.set_pressed_no_signal(false)
	
	update_keys_display()


func _clear_non_modifier_keys() -> void:
	for k: String in active_keys.keys():
		if not MODIFIER_KEYS.has(k):
			active_keys.erase(k)


func _toggle_recorded_key(key: String) -> void:
	if active_keys.has(key):
		active_keys.erase(key)
	else:
		if not MODIFIER_KEYS.has(key):
			_clear_non_modifier_keys()
		active_keys[key] = true
	
	_sync_recorded_buttons()
	_emit_recorded_combo()


func _set_recorded_key(key: String, pressed: bool) -> void:
	if pressed == active_keys.has(key):
		return
	
	if pressed:
		if not MODIFIER_KEYS.has(key):
			_clear_non_modifier_keys()
		active_keys[key] = true
	else:
		active_keys.erase(key)
	
	_sync_recorded_buttons()
	_emit_recorded_combo()


func _sync_recorded_buttons() -> void:
	for button_id: String in key_buttons:
		var key: String = button_id.trim_suffix("_2")
		var button: Button = key_buttons[button_id]
		button.set_pressed_no_signal(active_keys.has(key))


func _emit_recorded_combo() -> void:
	var combo: String = "+".join(active_keys.keys())
	shortcut_recorded.emit(combo)
	if not combo.is_empty():
		key_pressed.emit(combo)


func clear_recorded_combo() -> void:
	if active_keys.is_empty():
		return
	active_keys.clear()
	_sync_recorded_buttons()
	_emit_recorded_combo()

func _build_physical_key_map() -> void:
	_physical_key_map = {
		KEY_ESCAPE: "Esc",
		KEY_F1: "F1", KEY_F2: "F2", KEY_F3: "F3", KEY_F4: "F4",
		KEY_F5: "F5", KEY_F6: "F6", KEY_F7: "F7", KEY_F8: "F8",
		KEY_F9: "F9", KEY_F10: "F10", KEY_F11: "F11", KEY_F12: "F12",
		KEY_BACKSPACE: "Backspace",
		KEY_TAB: "Tab",
		KEY_CAPSLOCK: "CapsLock",
		KEY_ENTER: "Enter",
		KEY_KP_ENTER: "KpEnter",
		KEY_SHIFT: "Shift",
		KEY_CTRL: "Ctrl",
		KEY_ALT: "Alt",
		KEY_SPACE: "Space",
		KEY_LEFT: "Left", KEY_UP: "Up", KEY_DOWN: "Down", KEY_RIGHT: "Right",
		KEY_QUOTELEFT: "`", KEY_MINUS: "-", KEY_EQUAL: "=",
		KEY_BRACKETLEFT: "[", KEY_BRACKETRIGHT: "]", KEY_BACKSLASH: "\\",
		KEY_SEMICOLON: ";", KEY_APOSTROPHE: "'",
		KEY_COMMA: ",", KEY_PERIOD: ".", KEY_SLASH: "/",
		KEY_INSERT: "Insert", KEY_HOME: "Home", KEY_PAGEUP: "Page Up",
		KEY_DELETE: "Delete", KEY_END: "End", KEY_PAGEDOWN: "Page Down",
		KEY_KP_ADD: "+", KEY_KP_SUBTRACT: "-", KEY_KP_MULTIPLY: "*", KEY_KP_DIVIDE: "/",
		KEY_KP_0: "0", KEY_KP_1: "1", KEY_KP_2: "2", KEY_KP_3: "3", KEY_KP_4: "4",
		KEY_KP_5: "5", KEY_KP_6: "6", KEY_KP_7: "7", KEY_KP_8: "8", KEY_KP_9: "9",
		KEY_KP_PERIOD: ".",
	}
	
	_string_to_key_map.clear()
	for code: int in _physical_key_map:
		_string_to_key_map[_physical_key_map[code]] = code
	
	for code: int in range(KEY_A, KEY_Z + 1):
		_string_to_key_map[char(code)] = code
	for code: int in range(KEY_0, KEY_9 + 1):
		_string_to_key_map[char(code)] = code


func string_to_key(key: String) -> Key:
	return _string_to_key_map.get(key, KEY_NONE) as Key


func _physical_key_to_string(event: InputEventKey) -> String:
	var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	
	if code >= KEY_A and code <= KEY_Z:
		return char(code)
	if code >= KEY_0 and code <= KEY_9:
		return char(code)
	
	return _physical_key_map.get(code, "")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or event.echo:
		return
	
	var key: String = _physical_key_to_string(event)
	if not (key_buttons.has(key) or key_buttons.has(key + "_2")) or key.is_empty():
		return
	
	if record_mode:
		_set_recorded_key(key, event.pressed)
	elif event.pressed:
		_on_key_button_pressed(key)
