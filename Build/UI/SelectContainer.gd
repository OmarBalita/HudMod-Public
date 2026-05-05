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
class_name SelectContainer extends PanelContainer

signal focused_changed(old_focused: Vector2i, new_focused: Vector2i)
signal selected_changed()

signal selectbox_started()
signal selectbox_finished()

@onready var shortcut_node:= ShortcutNode.new()

@export_group("Control", "control")
@export_range(.01, 200.0) var control_close_dist: float = 10.
@export_range(.1, 100.0) var control_drag_dist: float = 10.
@export var control_use_selection_box: bool = true
@export var control_enable_delete: bool = true
@export var control_enable_past: bool = true

@export_group("Draw", "draw")
@export var draw_x_small_step: float = 10.
@export var draw_y_small_step: float = 10.
@export var draw_x_big_step: float = 20.
@export var draw_y_big_step: float = 20.

var selectables: Dictionary[int, Dictionary]

var selected: Dictionary[int, Dictionary]
var focused: Vector2i: set = _set_focused

var ignored_ports_to_select: PackedInt32Array

var copied: Dictionary[int, Dictionary]
var copied_start_port: int
var copied_start: int

var is_snapped: bool

var draw_step: Vector2:
	set(val):
		if draw_step != val:
			draw_step = val
			queue_redraw()

var mouseevent_startpos: Vector2
var selectbox_is_started: bool:
	set(val):
		selectbox_is_started = val
		if val: selectbox_started.emit()
		else: selectbox_finished.emit()
var selectbox_rect: Rect2:
	set(val):
		selectbox_rect = val
		selectbox_globalrect = Rect2(get_global_position() + selectbox_rect.position, selectbox_rect.size)
var selectbox_globalrect: Rect2


func _set_focused(new_val: Vector2i) -> void:
	var tmp_focused: Vector2i = focused
	focused = new_val
	emit_focused_changed(tmp_focused, new_val)


func emit_focused_changed(old_focused: Vector2i, new_focused: Vector2i) -> void:
	focused_changed.emit(old_focused, new_focused)

func emit_selected_changed() -> void:
	selected_changed.emit()



func has_selectable_port(idx: int) -> bool:
	return selectables.has(idx)

func get_selectable_port(idx: int) -> Dictionary:
	return selectables[idx]

func add_selectable_port(idx: int, port: Dictionary) -> void:
	selectables[idx] = port

func delete_selectable_port(idx: int) -> void:
	selectables.erase(idx)

func clear_selectable_ports() -> void:
	clear_selected_vals()
	selectables.clear()

func has_selectable_val(port_idx: int, idx: int) -> bool:
	return has_selectable_port(port_idx) and get_selectable_port(port_idx).has(idx)

func get_selectable_val(port_idx: int, idx: int) -> Variant:
	return get_selectable_port(port_idx)[idx]

func add_selectable_val(port_idx: int, idx: int, value: Variant) -> void:
	get_selectable_port(port_idx)[idx] = value

func delete_selectable_val(port_idx: int, idx: int) -> void:
	get_selectable_port(port_idx).erase(idx)

func is_val_selected(port_idx: int, idx: int) -> bool:
	return selected.has(port_idx) and selected[port_idx].has(idx)

func get_selected_val(port_idx: int, idx: int) -> Variant:
	return selected[port_idx][idx]

func select_val(port_idx: int, idx: int) -> void:
	
	if ignored_ports_to_select.has(port_idx):
		return
	
	if has_selectable_val(port_idx, idx):
		var val: Variant = get_selectable_val(port_idx, idx)
		if not selected.has(port_idx):
			selected[port_idx] = {}
		selected[port_idx][idx] = val
	
	focused = Vector2i(port_idx, idx)

func deselect_val(port_idx: int, idx: int, update_focus: bool = false) -> void:
	if is_val_selected(port_idx, idx):
		selected[port_idx].erase(idx)
	if update_focus: update_focused()

func manage_val(port_idx: int, idx: int, delete: bool, preclear: bool) -> void:
	if delete:
		if is_val_selected(port_idx, idx):
			deselect_val(port_idx, idx, true)
	else:
		if preclear: clear_selected_vals()
		select_val(port_idx, idx)

func select_vals(coords: Dictionary[int, PackedInt32Array], preclear: bool) -> void:
	if preclear: clear_selected_vals()
	for port_idx: int in coords:
		
		if ignored_ports_to_select.has(port_idx):
			continue
		
		var port_indeces: PackedInt32Array = coords[port_idx]
		var port: Dictionary = selected.get_or_add(port_idx, {})
		
		for idx: int in port_indeces:
			port[idx] = get_selectable_val(port_idx, idx)
	
	update_focused()

func deselect_vals(coords: Dictionary[int, PackedInt32Array]) -> void:
	for port_idx: int in coords:
		if not selected.has(port_idx): continue
		var port: Dictionary = selected[port_idx]
		var port_indeces: PackedInt32Array = coords[port_idx]
		for idx: int in port_indeces:
			port.erase(idx)

func manage_vals(coords: Dictionary[int, PackedInt32Array], delete: bool, preclear: bool) -> void:
	if delete: deselect_vals(coords)
	else: select_vals(coords, preclear)
	emit_selected_changed()


func clear_selected_vals() -> void:
	selected.clear()

func loop_selected_vals(info: Dictionary[StringName, Variant], method: Callable, post_method:= Callable()) -> Dictionary[StringName, Variant]:
	for port_idx: int in selected:
		var port: Dictionary = selected[port_idx]
		for idx: int in port:
			if method.call(port_idx, idx, info):
				return info
		if post_method:
			post_method.call(port_idx)
	return info

func delete_selected_vals() -> void:
	
	if not control_enable_delete:
		return
	
	loop_selected_vals({}, func(port_idx: int, idx: int, info: Dictionary[StringName, Variant]) -> bool:
		_delete_val(port_idx, idx)
		delete_selectable_val(port_idx, idx)
		return false
	)
	clear_selected_vals()

func copy_selected_vals(cut: bool) -> void:
	copied = selected.duplicate(true)
	
	var ports_indices: Array[int] = copied.keys()
	var indices: Array[int]
	
	for port_idx: int in copied:
		indices.append_array(copied[port_idx].keys())
	
	if ports_indices:
		copied_start_port = ports_indices.min()
	if indices:
		copied_start = indices.min()
	if cut:
		delete_selected_vals()

func past_selected_vals() -> void:
	
	if not control_enable_past:
		return
	
	if copied.is_empty():
		return
	
	for port_idx: int in copied:
		var port: Dictionary = copied[port_idx]
		for idx: int in port:
			_past_val(port_idx, idx)

func duplicate_selected_vals() -> void:
	copy_selected_vals(false)
	past_selected_vals()


func get_focused() -> Vector2i: return focused
func set_focused(new_val: Vector2i) -> void: focused = new_val
func get_focused_val() -> Variant: return get_selected_val(focused.x, focused.y)
func is_focused_exists() -> bool: return is_val_selected(focused.x, focused.y)

func update_focused() -> void:
	for port_idx: int in selected:
		var port: Dictionary = selected[port_idx]
		if port.is_empty():
			continue
		var port_keys: Array = port.keys()
		focused = Vector2i(port_idx, port_keys.back())
		break


func select_all() -> void: select_vals_by_method(get_all_vals_method)
func deselect_all() -> void: select_vals_by_method(get_none_vals_method)
func select_inverse() -> void: select_vals_by_method(get_invert_vals_method)
func select_linked() -> void: select_vals_by_method(get_linked_vals_method)
func select_random() -> void: select_vals_by_method(get_random_vals_method)


func get_all_vals_method(port_idx: int, port_obj: Object, idx: int, metadata: Dictionary = {}) -> bool: return true
func get_none_vals_method(port_idx: int, port_obj: Object, idx: int, metadata: Dictionary = {}) -> bool: return false
func get_invert_vals_method(port_idx: int, port_obj: Object, idx: int, metadata: Dictionary = {}) -> bool: return not is_val_selected(port_idx, idx)
func get_linked_vals_method(port_idx: int, port_obj: Object, idx: int, metadata: Dictionary = {}) -> bool: return selected.has(port_idx) and not selected[port_idx].is_empty()
func get_random_vals_method(port_idx: int, port_obj: Object, idx: int, metadata: Dictionary = {}) -> bool: return bool(randi_range(0, 1))

func select_vals_by_method(method: Callable, preclear: bool = true, metadata: Dictionary = {}) -> void:
	var coords: Dictionary[int, PackedInt32Array] = get_vals_coords_by_method(method, metadata)
	select_vals(coords, preclear)
	emit_selected_changed()

func deselect_vals_by_method(method: Callable, metadata: Dictionary = {}) -> void:
	var coords: Dictionary[int, PackedInt32Array] = get_vals_coords_by_method(method, metadata)
	deselect_vals(coords)
	emit_selected_changed()

func get_vals_coords_by_method(cond_method: Callable, metadata: Dictionary) -> Dictionary[int, PackedInt32Array]:
	var coords: Dictionary[int, PackedInt32Array]
	
	for port_idx: int in selectables:
		
		var port: Dictionary = get_selectable_port(port_idx)
		var coords_port: PackedInt32Array = []
		var port_obj: Object = _get_port_obj(port_idx)
		
		for idx: int in port:
			if cond_method.call(port_idx, port_obj, idx, metadata):
				coords_port.append(idx)
		
		if coords_port:
			coords[port_idx] = coords_port
	
	return coords

func selected_to_coords() -> Array[Vector2i]:
	var coords: Array[Vector2i]
	for port_idx: int in selected:
		var port: Dictionary = selected[port_idx]
		for idx: int in port:
			coords.append(Vector2i(port_idx, idx))
	return coords

func selected_to_vals() -> Array[Variant]:
	var vals: Array[Variant]
	for port_idx: int in selected:
		var port: Dictionary = selected[port_idx]
		for idx: int in port:
			vals.append(port[idx])
	return vals


func popup_options_menu(options: Array[Dictionary] = []) -> void:
	if options.is_empty():
		options = _get_menu_options()
	var popup_menu: PopupMenu = IS.create_popup_menu(options)
	
	get_tree().get_current_scene().add_child(popup_menu)
	var popup_pos: Vector2i = Vector2i(get_global_mouse_position() * get_window().content_scale_factor) + get_window().position
	popup_menu.popup(Rect2i(popup_pos, Vector2i.ZERO))
	popup_menu.id_pressed.connect(
		func(id: int) -> void:
			var metadata: Variant = popup_menu.get_item_metadata(id)
			if metadata != null and metadata is Callable: metadata.call()
	)
	popup_menu.popup_hide.connect(popup_menu.queue_free)

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	visibility_changed.connect(_on_visibility_changed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _ready() -> void:
	shortcut_node.methods_object = self
	shortcut_node.cond_func = EditorServer.shortcuts_cond_func
	add_child(shortcut_node)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var action_small_step: bool = event.keycode == KEY_SHIFT
		var action_big_step: bool = event.keycode == KEY_CTRL
		is_snapped = event.is_pressed()
		
		if event.is_pressed():
			if get_global_rect().has_point(get_global_mouse_position()):
				if action_small_step:
					draw_step = Vector2(draw_x_small_step, draw_y_small_step)
				elif action_big_step:
					draw_step = Vector2(draw_x_big_step, draw_y_big_step)
		
		elif action_small_step or action_big_step:
			draw_step = Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	var mouse_pos: Vector2 = get_local_mouse_position()
	
	if event is InputEventMouseButton:
		
		match event.button_index:
			
			MOUSE_BUTTON_LEFT:
				
				if event.is_pressed():
					var _request: bool = _request_box_selection()
					
					mouseevent_startpos = mouse_pos
					if _request:
						selectbox_rect = Rect2(mouse_pos, Vector2.ZERO)
					selectbox_is_started = _request
				
				else:
					if selectbox_is_started:
						var vals_coords: Dictionary[int, PackedInt32Array] = get_vals_coords_by_method(
							func(port_idx: int, port_obj: Object, idx: int, metadata: Dictionary) -> bool:
								return _request_selection_box_select(port_idx, port_obj, idx),
							{}
						)
						manage_vals(vals_coords, event.alt_pressed, not event.ctrl_pressed)
						selectbox_is_started = false
					
					EditorServer.drawable_rect.clear_drawn_entities()
					queue_redraw()
			
			MOUSE_BUTTON_RIGHT:
				pass
	
	elif event is InputEventMouseMotion:
		
		var drawable_rect: DrawableRect = EditorServer.drawable_rect
		drawable_rect.clear_drawn_entities()
		
		if selectbox_is_started:
			mouse_pos = Vector2(max(.0, mouse_pos.x), max(.0, mouse_pos.y))
			selectbox_rect = Rect2(mouseevent_startpos, mouse_pos - mouseevent_startpos).abs()
			
			var rect_pos:= selectbox_rect.position
			var rect_size:= selectbox_rect.size
			
			drawable_rect.draw_new_selection_box_rect(
				Rect2(
					global_position + rect_pos,
					Vector2(
						clamp(rect_size.x, .0, size.x - rect_pos.x),
						clamp(rect_size.y, .0, size.y - rect_pos.y),
					)
				), IS.color_accent, false
			)

func _delete_val(port_idx: int, idx: int) -> void:
	pass

func _past_val(port_idx: int, idx: int) -> void:
	pass

func _get_menu_options() -> Array[Dictionary]:
	return [
		{text = "Delete", shortcut = shortcut_node.get_shortcut(&"delete"), metadata = delete_selected_vals},
		{text = "Cut", shortcut = shortcut_node.get_shortcut(&"cut"), metadata = copy_selected_vals.bind(true)},
		{text = "Copy", shortcut = shortcut_node.get_shortcut(&"copy"), metadata = copy_selected_vals.bind(false)},
		{text = "Past", shortcut = shortcut_node.get_shortcut(&"past"), metadata = past_selected_vals},
		{text = "Duplicate", shortcut = shortcut_node.get_shortcut(&"duplicate"), metadata = duplicate_selected_vals},
		{as_separator = true},
		{text = "Select All", shortcut = shortcut_node.get_shortcut(&"select_all"), metadata = select_all},
		{text = "Deselect All", shortcut = shortcut_node.get_shortcut(&"deselect_all"), metadata = deselect_all},
		{text = "Select Invert", shortcut = shortcut_node.get_shortcut(&"select_invert"), metadata = select_inverse},
		{text = "Select Linked", shortcut = shortcut_node.get_shortcut(&"select_linked"), metadata = select_linked},
		{text = "Select Random", shortcut = shortcut_node.get_shortcut(&"select_random"), metadata = select_random}
	]

func _request_box_selection() -> bool:
	return true

func _get_port_obj(port_idx: int) -> Object:
	return null

func _request_selection_box_select(port_idx: int, port_obj: Object, idx: int) -> bool:
	return false

func _on_visibility_changed() -> void:
	set_process_input(is_visible_in_tree())

func _on_mouse_entered() -> void:
	pass

func _on_mouse_exited() -> void:
	pass

