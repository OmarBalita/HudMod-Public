#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
##  This program is free software: you can redistribute it and/or modify   ##
##  it under the terms of the GNU General Public License as published by   ##
##  the Free Software Foundation, either version 3 of the License, or      ##
##  (at your option) any later version.                                    ##
##                                                                         ##
##  This program is distributed in the hope that it will be useful,        ##
##  but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           ##
##  GNU General Public License for more details.                           ##
##                                                                         ##
##  You should have received a copy of the GNU General Public License      ##
##  along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
class_name FloatController extends Panel

signal grab_started()
signal grab_finished()
signal val_changed(new_val: Variant)

@export var min_val: float = 0.0
@export var max_val: float = 100.0
@export var step: float = 0.5
@export var curr_val: Variant = 100.0

@export var is_int: bool = false:
	set(v):
		is_int = v
		if v: curr_val = int(curr_val)

@export_group("Theme")
@export var change_value_when_drag: bool = true
@export var spin_scale: float = 1.0
@export var spin_magnet_step: float = 10.

enum _State { GRAB, TYPING }

var _state: _State = _State.GRAB
var _is_grab: bool = false
var _is_magnet: bool = false
var _mouse_down: bool = false
var _drag_start: Vector2
var _drag_accum: float = 0.0
var _line_edit: LineEdit

var _repeat_timer: Timer
var _repeat_dir: float = 0.0
var _initial_delay: float = 0.4
var _repeat_interval: float = 0.05

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_CLICK
	custom_minimum_size = Vector2(120, 32)
	
	_repeat_timer = Timer.new()
	_repeat_timer.one_shot = false
	_repeat_timer.timeout.connect(_on_repeat_timeout)
	add_child(_repeat_timer)
	
	_line_edit = IS.create_line_edit()
	_line_edit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_line_edit.visible = false
	_line_edit.z_index = 1
	_line_edit.text_submitted.connect(_on_text_submitted)
	_line_edit.focus_exited.connect(_exit_typing)
	add_child(_line_edit)
	
	set_process_input(false)


func _draw() -> void:
	if _state == _State.TYPING:
		return
	
	var margin:= 25.0
	var available_width:= size.x - (margin * 2.0)
	var ratio:= inverse_lerp(min_val, max_val, float(curr_val))
	
	draw_rect(Rect2(Vector2(margin, 5.0), Vector2(available_width * ratio, size.y - 10.0)), IS.color_accent)
	
	var font:= get_theme_default_font()
	var font_size:= get_theme_default_font_size()
	var label:= _format(curr_val)
	var text_size:= font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos:= Vector2((size.x - text_size.x) * 0.5, (size.y + text_size.y) * 0.5 - 2.0)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, IS.color_label)
	
	_draw_arrow(Vector2(10.0, size.y * 0.5), false)
	_draw_arrow(Vector2(size.x - 10.0, size.y * 0.5), true)

func _draw_arrow(center: Vector2, right: bool) -> void:
	var s:= 5.0
	var pts: PackedVector2Array
	if right: pts = PackedVector2Array([center + Vector2(-s, s), center + Vector2(s, 0), center + Vector2(-s, -s)])
	else: pts = PackedVector2Array([center + Vector2(s, s), center + Vector2(-s, 0), center + Vector2(s, -s)])
	draw_colored_polygon(pts, IS.color_label)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _is_grab:
			_is_magnet = event.ctrl_pressed
			_drag_accum += event.relative.x * spin_scale
			var snp:= spin_magnet_step if _is_magnet else step
			if absf(_drag_accum) >= snp:
				var steps:= int(_drag_accum / snp)
				_drag_accum -= steps * snp
				_apply_delta(steps * snp, change_value_when_drag)
		elif _mouse_down:
			if _drag_start.distance_to(get_global_mouse_position()) >= 5.0:
				_stop_repeat()
				_begin_grab()
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_down = true
				_drag_start = get_global_mouse_position()
				_check_arrow_press(get_local_mouse_position())
			else:
				_mouse_down = false
				_stop_repeat()
				if _is_grab:
					_end_grab()
				elif _state != _State.TYPING:
					var pos = get_local_mouse_position()
					if pos.x > 24.0 and pos.x < size.x - 24.0:
						_enter_typing()

func _check_arrow_press(pos: Vector2) -> void:
	if pos.x < 24.0:
		_repeat_dir = -1.0
	elif pos.x > size.x - 24.0:
		_repeat_dir = 1.0
	else:
		_repeat_dir = 0.0
		return
	
	_apply_delta(_repeat_dir * step, true)
	_repeat_timer.start(_initial_delay)

func _on_repeat_timeout() -> void:
	if _mouse_down and _repeat_dir != 0.0:
		_apply_delta(_repeat_dir * step, true)
		if _repeat_timer.wait_time != _repeat_interval:
			_repeat_timer.start(_repeat_interval)

func _stop_repeat() -> void:
	_repeat_dir = 0.0
	_repeat_timer.stop()

func _begin_grab() -> void:
	_is_grab = true
	_drag_accum = 0.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	grab_started.emit()

func _end_grab() -> void:
	_is_grab = false
	_drag_accum = 0.0
	_is_magnet = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_viewport().warp_mouse(global_position + size * 0.5)
	val_changed.emit(curr_val)
	grab_finished.emit()

func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _enter_typing() -> void:
	_state = _State.TYPING
	_line_edit.visible = true
	_line_edit.text = _format(curr_val)
	_line_edit.grab_focus()
	_line_edit.select_all()
	set_process_input(true)
	queue_redraw()

func _exit_typing() -> void:
	if _state != _State.TYPING:
		return
	_state = _State.GRAB
	_line_edit.visible = false
	_line_edit.release_focus()
	set_process_input(false)
	queue_redraw()

static var regex:= RegEx.new()
static var expr:= Expression.new()

func _on_text_submitted(text: String) -> void:
	_exit_typing()
	regex.compile(r"^[0-9+\-*/. ()]+$")
	if regex.search(text) == null: return
	if expr.parse(text) != OK: return
	var result: Variant = expr.execute()
	if expr.has_execute_failed(): return
	set_curr_val(float(result), true)

func get_curr_val() -> Variant:
	return curr_val

func set_curr_val(new_val: float, emit: bool = true) -> void:
	var snp:= step
	if _is_grab and _is_magnet:
		snp = spin_magnet_step
		
	var clamped:= clampf(snappedf(new_val, snp), min_val, max_val)
	if is_int: clamped = float(round(clamped))
	
	if clamped == float(curr_val):
		return
	curr_val = clamped
	if emit:
		val_changed.emit(curr_val)
	queue_redraw()

func set_curr_val_manually(new_val: float) -> void:
	set_curr_val(new_val, false)

func _apply_delta(delta: float, emit: bool) -> void:
	set_curr_val(float(curr_val) + delta, emit)

func _format(v: Variant) -> String:
	return str(int(v) if is_int else snappedf(v, step))
