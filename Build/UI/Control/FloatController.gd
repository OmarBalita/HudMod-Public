class_name FloatController extends Button

signal grab_started()
signal grab_finished()
signal val_changed(new_val: Variant)


enum States {
	GRAB,
	TYPING
}

@export var state: States:
	set(val):
		state = val
		is_magnet = false
		update_ui()

@export var min_val: float = .0
@export var max_val: float = 100.0
@export var step: float = .5
@export var curr_val: Variant = 100.0
@export var is_int: bool = false

@export_group("Theme")
@export_subgroup("Constant")
@export_range(.001, 100.0) var spin_scale: float = 1.0
@export_range(1.0, 100.0) var spin_magnet_step: float = 10.0
@export_subgroup("Color")
@export var fill_color: Color
@export var grabber_main_color: Color
@export_subgroup("Texture")
@export var texture_right: Texture2D


# RealTime Variables
var start_pos = null

var is_grab: bool:
	set(val):
		is_grab = val
		control_val = curr_val
		if is_grab:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			grab_started.emit()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_viewport().warp_mouse(global_position + size / 2.0)
			start_pos = null
			grab_finished.emit()

var control_val: float:
	set(val):
		control_val = val
		set_curr_val(control_val)

var is_magnet: bool


# RealTime Nodes
var typing_line: LineEdit
var progress_bar: ProgressBar
var curr_val_label: Label
var right_button: TextureButton
var left_button: TextureButton


func _ready() -> void:
	var box = IS.create_box_container(4)
	
	var margin_container = IS.create_margin_container(6,6,6,6)
	typing_line = IS.create_line_edit(); typing_line.z_index = 1
	progress_bar = IS.create_progress_bar(curr_val, min_val, max_val, step, {show_percentage = false})
	curr_val_label = IS.create_label(str(curr_val))
	curr_val_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	
	var button_args = [texture_right, null, null, false, {mouse_filter = Control.MOUSE_FILTER_STOP}]
	left_button = IS.create_texture_button.callv(button_args)
	right_button = IS.create_texture_button.callv(button_args)
	left_button.flip_h = true
	
	margin_container.add_child(typing_line)
	margin_container.add_child(progress_bar)
	margin_container.add_child(curr_val_label)
	
	box.add_child(left_button)
	box.add_child(margin_container)
	box.add_child(right_button)
	add_child(box)
	
	button_down.connect(on_button_down)
	button_up.connect(on_button_up)
	
	typing_line.text_submitted.connect(on_typing_line_text_submitted)
	left_button.pressed.connect(on_left_button_pressed)
	right_button.pressed.connect(on_right_button_pressed)
	
	IS.expand(margin_container, true, true)
	IS.expand(progress_bar, true, true)
	
	update_ui()


func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		if is_grab:
			control_val += float(event.relative.x) * spin_scale
			is_magnet = event.ctrl_pressed
		elif start_pos != null:
			if request_grab():
				set_is_grab(true)
	elif event is InputEventMouseButton:
		if not get_global_rect().has_point(get_global_mouse_position()) and state: state = 0


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



func on_button_down() -> void:
	start_pos = get_global_mouse_position()

func on_button_up() -> void:
	if not request_grab():
		state = 1
	set_is_grab(false)

func on_typing_line_text_submitted(new_text: String) -> void:
	state = 0
	
	var regex = RegEx.new()
	regex.compile("^[0-9+\\-*/. ()]+$")
	if regex.search(new_text) == null:
		return
	
	var expression = Expression.new()
	var parse_error = expression.parse(new_text)
	if parse_error != OK:
		return
	
	var result = expression.execute()
	if expression.has_execute_failed():
		return
	
	set_curr_val(result)

func on_left_button_pressed() -> void:
	set_curr_val(curr_val - step)

func on_right_button_pressed() -> void:
	set_curr_val(curr_val + step)



func get_curr_val() -> float:
	return curr_val

func set_curr_val(new_val: float, emit_change: bool = true) -> void:
	curr_val = clamp(new_val, min_val, max_val)
	curr_val = snapped(curr_val, spin_magnet_step if is_magnet else step)
	if is_int:
		curr_val = int(curr_val)
	if progress_bar != null and progress_bar.is_node_ready():
		progress_bar.value = curr_val
	if curr_val_label != null and curr_val_label.is_node_ready():
		curr_val_label.text = str(curr_val)
	if emit_change:
		val_changed.emit(curr_val)
	queue_redraw()

func set_curr_val_manually(new_val: float) -> void:
	set_curr_val(new_val, false)


func set_is_grab(new_val: bool) -> void:
	is_grab = new_val

func request_grab() -> bool:
	return start_pos.distance_to(get_global_mouse_position()) >= 10.0

func update_ui() -> void:
	var not_state = not state
	if not typing_line: return
	typing_line.visible = state
	progress_bar.visible = not_state
	curr_val_label.visible = not_state
	left_button.visible = not_state
	right_button.visible = not_state
	if state:
		typing_line.set_text(str(curr_val))
		typing_line.grab_focus()
		typing_line.select()
	else: typing_line.release_focus()


