class_name EditorRect extends FocusControl


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
@export var header_size: int = 50
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
var shortcut_node: ShortcutNode
var container: SplitContainer
var header: MarginContainer
var body: MarginContainer



func _init() -> void:
	draw_focus = false


func _ready() -> void:
	# Start Connections
	shortcut_node = ShortcutNode.new()
	shortcut_node.focus_control = self
	add_child(shortcut_node)
	
	shortcut_node.shortcut_key_pressed.connect(on_shortcut_key_pressed)
	shortcut_node.shortcut_key_released.connect(on_shortcut_key_released)
	shortcut_node.shortcut_button_pressed.connect(on_shortcut_button_pressed)
	shortcut_node.shortcut_button_released.connect(on_shortcut_button_released)
	
	container = IS.create_split_container(1, true)
	header = IS.create_margin_container(4,4,4,4)
	body = IS.create_margin_container()
	var header_panel = IS.create_panel_container(Vector2(0, header_size), IS.STYLE_HEADER)
	var body_panel = IS.create_panel_container(Vector2.ZERO, IS.STYLE_BODY, {"z_index": -1, "clip_contents": true})
	header_panel.add_child(header)
	body_panel.add_child(body)
	container.add_child(header_panel)
	container.add_child(body_panel)
	add_child(container)
	
	body_panel.mouse_entered.connect(set_is_focus.bind(true))
	body_panel.mouse_exited.connect(set_is_focus.bind(false))


func _input(event: InputEvent) -> void:
	super(event)
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
			pass







func on_shortcut_key_pressed(key: Array) -> void:
	pass

func on_shortcut_key_released(key: Array) -> void:
	pass

func on_shortcut_button_pressed(key: Array) -> void:
	pass

func on_shortcut_button_released(key: Array) -> void:
	pass








