class_name SelectContainer extends PanelContainer

signal selected_changed()

signal selectbox_started()
signal selectbox_finished()

@onready var shortcut_node: ShortcutNode = IS.create_shortcut_node(&"select_container_shortcut")

@export_group("Control", "control")
@export_range(.01, 200.0) var control_close_dist: float = 10.
@export_range(.1, 100.0) var control_drag_dist: float = 10.
@export var control_use_selection_box: bool = true

@export_group("Draw", "draw")
@export var draw_x_small_step: float = 10.
@export var draw_y_small_step: float = 10.
@export var draw_x_big_step: float = 20.
@export var draw_y_big_step: float = 20.

var selectables: Dictionary[int, Dictionary]

var selected: Dictionary[int, Dictionary]
var focused: Vector2i: set = _set_focused

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
	focused = new_val

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


func popup_options_menu(options: Array = []) -> void:
	if options.is_empty():
		options = _get_menu_options()
	IS.popup_menu(options, null, get_window())

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	visibility_changed.connect(_on_visibility_changed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _ready() -> void:
	add_child(shortcut_node)
	shortcut_node.register_shortcut_quickly(&"delete", delete_selected_vals, [ShortcutNode.new_event_key(Key.KEY_DELETE)])
	shortcut_node.register_shortcut_quickly(&"cut", copy_selected_vals.bind(true), [ShortcutNode.new_event_key(Key.KEY_X, true)])
	shortcut_node.register_shortcut_quickly(&"copy", copy_selected_vals.bind(false), [ShortcutNode.new_event_key(Key.KEY_C, true)])
	shortcut_node.register_shortcut_quickly(&"past", past_selected_vals, [ShortcutNode.new_event_key(Key.KEY_V, true)])
	shortcut_node.register_shortcut_quickly(&"duplicate", duplicate_selected_vals, [ShortcutNode.new_event_key(Key.KEY_D, true)])
	shortcut_node.register_shortcut_quickly(&"select_all", select_all, [ShortcutNode.new_event_key(Key.KEY_A, true)])
	shortcut_node.register_shortcut_quickly(&"deselect_all", deselect_all, [ShortcutNode.new_event_key(Key.KEY_A, false, false, true)])
	shortcut_node.register_shortcut_quickly(&"select_invert", select_inverse, [ShortcutNode.new_event_key(Key.KEY_I, true)])
	shortcut_node.register_shortcut_quickly(&"select_linked", select_linked, [ShortcutNode.new_event_key(Key.KEY_L, true)])
	shortcut_node.register_shortcut_quickly(&"select_random", select_random, [ShortcutNode.new_event_key(Key.KEY_R, true)])

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var action_small_step:= event.is_action("small_snap")
		var action_big_step:= event.is_action("big_snap")
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
				), IS.COLOR_ACCENT_BLUE, false
			)

func _delete_val(port_idx: int, idx: int) -> void:
	pass

func _past_val(port_idx: int, idx: int) -> void:
	pass

func _get_menu_options() -> Array:
	return [
		MenuOption.new("Cut", null, copy_selected_vals.bind(true)),
		MenuOption.new("Copy", null, copy_selected_vals.bind(false)),
		MenuOption.new("Past", null, past_selected_vals),
		MenuOption.new("Duplicate", null, duplicate_selected_vals),
		MenuOption.new("Delete", null, delete_selected_vals),
		MenuOption.new_line(),
		MenuOption.new("Select All", null, select_all),
		MenuOption.new("Deselect All", null, deselect_all),
		MenuOption.new("Select Inverse", null, select_inverse),
		MenuOption.new("Select Linked", null, select_linked),
		MenuOption.new("Select Random", null, select_random)
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



