class_name SliderController extends Panel

signal grab_started()
signal grab_finished()
signal val_changed(new_val: Variant)

@export var min_val: float = 0.0
@export var max_val: float = 100.0
@export var step: float = 1.0
@export var curr_val: Variant = 50.0

@export var snap_step: float = 10.

@export var is_int: bool = false:
	set(v):
		is_int = v
		if v: curr_val = int(curr_val)

@export_group("Theme")
@export var text_color: Color = Color.WHITE

var _is_dragging: bool = false
var _ctrl_pressed: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_CLICK
	custom_minimum_size = Vector2(120, 24)

func _draw() -> void:
	var ratio:= inverse_lerp(min_val, max_val, float(curr_val))
	var fill_rect:= Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y))
	draw_rect(fill_rect, IS.color_accent)
	
	var font:= get_theme_default_font()
	var font_size:= get_theme_default_font_size()
	var label:= _format(curr_val)
	var text_size:= font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos:= Vector2((size.x - text_size.x) * 0.5, (size.y + text_size.y) * 0.5 - 2.0)
	
	draw_string(font, text_pos + Vector2(1, 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.4))
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

func _gui_input(event: InputEvent) -> void:
	_ctrl_pressed = event.ctrl_pressed
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				grab_started.emit()
				_update_value_at_pos(event.position.x)
			else:
				if _is_dragging:
					_is_dragging = false
					grab_finished.emit()
					val_changed.emit(curr_val)
	
	elif event is InputEventMouseMotion:
		if _is_dragging:
			_update_value_at_pos(event.position.x)
	
	#elif event is InputEventKey and event.pressed:
		#var s:= snap_step if event.ctrl_pressed else step
		#if event.keycode == KEY_LEFT: _apply_delta(-s)
		#if event.keycode == KEY_RIGHT: _apply_delta(s)

func _update_value_at_pos(mouse_x: float) -> void:
	var ratio:= clampf(mouse_x / size.x, 0.0, 1.0)
	var new_val: float = lerpf(min_val, max_val, ratio)
	set_curr_val(new_val, true, _ctrl_pressed)

func set_curr_val(new_val: float, emit: bool = true, force_snap: bool = false) -> void:
	var current_step:= snap_step if force_snap else step
	
	var clamped:= clampf(snappedf(new_val, current_step), min_val, max_val)
	if is_int: clamped = float(roundi(clamped))
	
	if clamped == float(curr_val): return
	
	curr_val = clamped
	if emit: val_changed.emit(curr_val)
	queue_redraw()

func set_curr_val_manually(new_val: float) -> void:
	set_curr_val(new_val, false)

func _apply_delta(delta: float) -> void:
	set_curr_val(float(curr_val) + delta)

func _format(v: Variant) -> String:
	return str(int(v) if is_int else snappedf(v, 0.0001))

func get_curr_val() -> Variant:
	return curr_val
