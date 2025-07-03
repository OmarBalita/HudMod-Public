@tool class_name EditorRect extends FocusControl


signal l_button_downed(pos: Vector2)
signal l_button_upped(pos: Vector2)
signal r_button_downed(pos: Vector2)
signal r_button_upped(pos: Vector2)
signal m_button_downed(pos: Vector2)
signal m_button_upped(pos: Vector2)

signal wheel_downed(pos: Vector2)
signal wheel_upped(pos: Vector2)



@export_group("Theme")
@export_subgroup("Constant")
@export var header_size: int = 50.0:
	set(val):
		header_size = val
@export_subgroup("Font", "font")
@export var font_header: Font
@export var font_main: Font

var press_functions: Dictionary
var just_press_functions: Dictionary
var release_functions: Dictionary

# RealTime Variables


var pressed_keys: Array
var key_just_pressed: bool
var l_button_down: bool
var r_button_down: bool

# RealTime Nodes
var container: SplitContainer
var header: MarginContainer
var body: MarginContainer






func _ready() -> void:
	_start()

func _start() -> void:
	
	container = InterfaceServer.create_split_container(1, true)
	header = InterfaceServer.create_margin_container(4,4,4,4)
	body = InterfaceServer.create_margin_container()
	var header_panel = InterfaceServer.create_panel_container(Vector2(0, header_size), InterfaceServer.STYLE_HEADER)
	var body_panel = InterfaceServer.create_panel_container(Vector2.ZERO, InterfaceServer.STYLE_BODY, {"z_index": -1, "clip_contents": true})
	header_panel.add_child(header)
	body_panel.add_child(body)
	container.add_child(header_panel)
	container.add_child(body_panel)
	add_child(container)
	
	body_panel.mouse_entered.connect(set_is_focus.bind(true))
	body_panel.mouse_exited.connect(set_is_focus.bind(false))
	
	header_size += 10

func _input(event: InputEvent) -> void:
	
	if not is_focus: return
	
	if event is InputEventMouseButton:
		var mouse_pos = event.position
		var is_pressed = event.is_pressed()
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				l_button_down = is_pressed
				if is_pressed: l_button_downed.emit(mouse_pos)
				else: l_button_upped.emit(mouse_pos)
			MOUSE_BUTTON_RIGHT:
				r_button_down = is_pressed
				if is_pressed: r_button_downed.emit(mouse_pos)
				else: r_button_upped.emit(mouse_pos)
			MOUSE_BUTTON_MIDDLE:
				if is_pressed: m_button_downed.emit(mouse_pos)
				else: m_button_upped.emit(mouse_pos)
			MOUSE_BUTTON_WHEEL_DOWN: if is_pressed: wheel_downed.emit(mouse_pos)
			MOUSE_BUTTON_WHEEL_UP: if is_pressed: wheel_upped.emit(mouse_pos)
	
	elif event is InputEventKey:
		if event.is_pressed():
			match_key_code(event, press_functions)
			if not key_just_pressed:
				match_key_code(event, just_press_functions)
				pressed_keys.append(event.keycode)
			key_just_pressed = true
		elif event.is_released():
			match_key_code(event, release_functions)
			pressed_keys.erase(event.keycode)
			key_just_pressed = false


func match_key_code(event: InputEventKey, callables: Dictionary) -> void:
	for key in callables.keys():
		if event.keycode == key:
			callables[key].call()
			var is_key_declared = key in pressed_keys


func _draw() -> void:
	draw_rect(
		Rect2(body.global_position - global_position, size - Vector2.DOWN * header_size),
		Color(InterfaceServer.STYLE_ACCENT.bg_color, focus_alpha),
		false, 2.0
	)









