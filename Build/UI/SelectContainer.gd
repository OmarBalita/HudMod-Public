class_name SelectContainer extends PanelContainer

class LocalPointInfo extends Resource:
	var point_val: Variant
	var point_display_pos: Vector2
	
	func _init(_point_val: Variant, _point_display_pos: Vector2) -> void:
		point_val = _point_val
		point_display_pos = _point_display_pos

class GlobalPointInfo extends Resource:
	var owner_as_object: Variant
	var key: float
	var point_info: LocalPointInfo
	
	func _init(_owner_as_object: Variant, _key: float, _point_info: LocalPointInfo) -> void:
		owner_as_object = _owner_as_object
		key = _key
		point_info = _point_info

@export_group("Control", "control")
@export_range(.01, 200.0) var control_close_distance: float = 10.0
@export_range(.1, 100.0) var control_drag_distance: float = 10.0
@export var control_use_selection_box: bool = true

@export_group("Draw", "draw")
@export var draw_x_small_step: int = 1
@export var draw_y_small_step: int = 1
@export var draw_x_big_step: int = 5
@export var draw_y_big_step: int = 5

var single_selection_func: Callable
var selection_box_cond: Callable

var selectable_points_objects: Dictionary[Variant, Dictionary]
# Key as int-index, Val as PointInfo
var selected_points: Dictionary[Variant, Dictionary]
var copied_points: Dictionary[Variant, Dictionary]
var start_copied_point: float

var focused_point: GlobalPointInfo

var press_start_pos: Vector2
var selection_box_started: bool = false
var selection_box_rect: Rect2

var is_snapped: bool = false

var draw_step: Vector2:
	set(val):
		if draw_step != val:
			draw_step = val
			queue_redraw()

var shortcut_node: ShortcutNode = IS.create_shortcut_node(&"select_container_shortcut")



func add_selectable_object(object: Variant, selectable_points: Dictionary[float, LocalPointInfo] = {}) -> void:
	selectable_points_objects[object] = selectable_points

func delete_selectable_object(object: Variant) -> void:
	selectable_points_objects.erase(object)

func get_selectable_point(object: Variant, key: float) -> LocalPointInfo:
	return selectable_points_objects[object][key]

func add_selectable_point(object: Variant, key: float, point_val: Variant, point_display_pos: Vector2) -> void:
	selectable_points_objects[object][key] = LocalPointInfo.new(point_val, point_display_pos)

func delete_selectable_point(object: Variant, key: float) -> void:
	selectable_points_objects[object].erase(key)

func has_selectable_point(object: Variant, key: float) -> bool:
	return selectable_points_objects.has(object) and selectable_points_objects[object].has(key)

func is_point_selected(object: Variant, key: float) -> bool:
	return selected_points.has(object) and selected_points[object].has(key)

func select_point(object: Variant, key: float, clear_old_selected: bool) -> void:
	if clear_old_selected:
		clear_selected_points()
	
	if not selected_points.has(object):
		selected_points[object] = {} as Dictionary[float, Variant]
	
	if has_selectable_point(object, key):
		var point_info:= get_selectable_point(object, key)
		selected_points[object][key] = point_info

func deselect_point(object: Variant, key: float) -> void:
	if is_point_selected(object, key):
		selected_points[object].erase(key)

func manage_point(object: Variant, key: float, delete_it: bool, clear_old_selected: bool) -> void:
	if delete_it:
		if is_point_selected(object, key):
			deselect_point(object, key)
	else:
		select_point(object, key, clear_old_selected)

func select_points(forselect_points: Dictionary[Variant, Dictionary], clear_old_selected: bool) -> void:
	if clear_old_selected:
		clear_selected_points()
	for object: Variant in forselect_points:
		var forselect_object_points: Dictionary = forselect_points[object]
		if not selected_points.has(object):
			selected_points[object] = {}
		for point_key: float in forselect_object_points:
			var point_info:= get_selectable_point(object, point_key)
			selected_points[object][point_key] = point_info

func deselect_points(fordeselect_points: Dictionary[Variant, Dictionary]) -> void:
	for object: Variant in fordeselect_points:
		if not selected_points.has(object):
			continue
		var fordeselect_object_points: Dictionary = fordeselect_points[object]
		for point_key: float in fordeselect_object_points:
			selected_points[object].erase(point_key)

func manage_points(points: Dictionary[Variant, Dictionary], delete_it: bool, clear_old_selected: bool) -> void:
	if delete_it:
		deselect_points(points)
	else:
		select_points(points, clear_old_selected)

func clear_selected_points() -> void:
	selected_points.clear()

func loop_selected_points(info: Dictionary[StringName, Variant] = {}, method: Callable = Callable(), object_method: Callable = Callable()) -> Dictionary[StringName, Variant]:
	for object: Variant in selected_points:
		var object_selected_points: Dictionary = selected_points[object]
		for key: float in object_selected_points:
			if method.call(object, key, info):
				return info
		if object_method:
			object_method.call(object)
	return info


func delete_selected_points(redraw: bool = true) -> void:
	loop_selected_points({}, func(object: Variant, key: float, info: Dictionary[StringName, Variant]) -> bool:
		delete_selectable_point(object, key)
		on_point_delete(object, key)
		return false
	)
	clear_selected_points()
	on_delete_ended()
	if redraw: queue_redraw()

func copy_selected_points(cut: bool) -> void:
	copied_points = selected_points.duplicate(true)
	var all_keys: Array
	for object: Variant in copied_points:
		all_keys.append_array(copied_points[object].keys())
	if all_keys.is_empty():
		return
	start_copied_point = all_keys.min()
	if cut: delete_selected_points()

func past_selected_points() -> void:
	if copied_points.is_empty():
		return
	for object: Variant in copied_points:
		var object_selected_points: Dictionary = copied_points[object]
		for key: float in object_selected_points:
			on_point_past(object, key)
	on_past_ended()
	queue_redraw()

func duplicate_selected_points() -> void:
	copy_selected_points(false)
	past_selected_points()


func get_point_pos(object: Variant, key: float, point_info: LocalPointInfo) -> Vector2:
	return Vector2(key, point_info.point_val)

func on_point_delete(object: Variant, key: float) -> void:
	pass

func on_delete_ended() -> void:
	pass

func on_point_past(object: Variant, key: float) -> void:
	pass

func on_past_ended() -> void:
	pass

func get_menu_options() -> Array:
	return [
		MenuOption.new("Cut", null, copy_selected_points.bind(true)),
		MenuOption.new("Copy", null, copy_selected_points.bind(false)),
		MenuOption.new("Past", null, past_selected_points),
		MenuOption.new("Duplicate", null, duplicate_selected_points),
		MenuOption.new("Delete", null, delete_selected_points),
		MenuOption.new_line(),
		MenuOption.new("Select All", null, select_all),
		MenuOption.new("Deselect All", null, deselect_all),
		MenuOption.new("Select Inverse", null, select_inverse),
		MenuOption.new("Select Linked", null, select_linked),
	]

func popup_options_menu() -> void:
	IS.popup_menu(get_menu_options())

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	visibility_changed.connect(_on_visibility_changed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _ready() -> void:
	shortcut_node.register_shortcut_quickly(&"delete", delete_selected_points, [ShortcutNode.new_event_key(Key.KEY_DELETE)])
	shortcut_node.register_shortcut_quickly(&"cut", copy_selected_points.bind(true), [ShortcutNode.new_event_key(Key.KEY_X, true)])
	shortcut_node.register_shortcut_quickly(&"copy", copy_selected_points.bind(false), [ShortcutNode.new_event_key(Key.KEY_C, true)])
	shortcut_node.register_shortcut_quickly(&"past", past_selected_points, [ShortcutNode.new_event_key(Key.KEY_V, true)])
	shortcut_node.register_shortcut_quickly(&"duplicate", duplicate_selected_points, [ShortcutNode.new_event_key(Key.KEY_D, true)])
	shortcut_node.register_shortcut_quickly(&"select_all", select_all, [ShortcutNode.new_event_key(Key.KEY_A, true)])
	shortcut_node.register_shortcut_quickly(&"deselect_all", deselect_all, [ShortcutNode.new_event_key(Key.KEY_A, false, false, true)])
	shortcut_node.register_shortcut_quickly(&"select_invert", select_inverse, [ShortcutNode.new_event_key(Key.KEY_I, true)])
	shortcut_node.register_shortcut_quickly(&"select_linked", select_linked, [ShortcutNode.new_event_key(Key.KEY_L, true)])
	add_child(shortcut_node)

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
					var selection_box_use_cond: bool = selection_box_cond.is_null() or selection_box_cond.call() == true
					press_start_pos = mouse_pos
					if selection_box_use_cond:
						selection_box_rect = Rect2(mouse_pos, Vector2.ZERO)
					selection_box_started = selection_box_use_cond
				
				else:
					if selection_box_started:
						var points:= get_points_info_closed_to(get_points_inside_rect_cond_func, selection_box_rect)
						manage_points(points.result, event.alt_pressed, not event.ctrl_pressed)
						focused_point = points.new_focused_point
						selection_box_started = false
					
					#elif press_pos.distance_to(mouse_pos) <= control_drag_distance:
						#var single_selection_result: Dictionary[Variant, Dictionary] = single_selection_func.call(press_pos)
						#selected_points = single_selection_result
						#focused_point = null
					
					EditorServer.drawable_rect.clear_drawn_entities()
					queue_redraw()
			
			MOUSE_BUTTON_RIGHT:
				pass
	
	elif event is InputEventMouseMotion:
		
		var drawable_rect: DrawableRect = EditorServer.drawable_rect
		drawable_rect.clear_drawn_entities()
		
		if selection_box_started:
			mouse_pos = Vector2(max(.0, mouse_pos.x), max(.0, mouse_pos.y))
			selection_box_rect = Rect2(press_start_pos, mouse_pos - press_start_pos).abs()
			
			var rect_pos:= selection_box_rect.position
			var rect_size:= selection_box_rect.size
			
			drawable_rect.draw_new_selection_box_rect(
				Rect2(
					global_position + rect_pos,
					Vector2(
						clamp(rect_size.x, .0, size.x - rect_pos.x),
						clamp(rect_size.y, .0, size.y - rect_pos.y),
					)
				), IS.COLOR_ACCENT_BLUE, false
			)


func select_all() -> void: method_select_points(get_all_points_func)
func deselect_all() -> void: method_select_points(get_none_points_func)
func select_inverse() -> void: method_select_points(get_invert_points_func)
func select_linked() -> void: method_select_points(get_linked_points_func)

func method_select_points(method: Callable, metadata: Dictionary = {}) -> void:
	select_points(get_points(method, metadata), true)
	queue_redraw()

func get_points(cond_method: Callable, metadata: Dictionary) -> Dictionary[Variant, Dictionary]:
	var new_points: Dictionary[Variant, Dictionary]
	for object: Variant in selectable_points_objects:
		var selectable_points: Dictionary[float, LocalPointInfo] = selectable_points_objects[object]
		new_points[object] = {}
		for point_key: float in selectable_points:
			var point_info: LocalPointInfo = selectable_points[point_key]
			if cond_method.call(object, point_key, point_info, metadata):
				new_points[object][point_key] = point_info
	
	return new_points

func get_all_points_func(object: Variant, key: float, point_info: LocalPointInfo, metadata: Dictionary = {}) -> bool: return true
func get_none_points_func(object: Variant, key: float, point_info: LocalPointInfo, metadata: Dictionary = {}) -> bool: return false
func get_invert_points_func(object: Variant, key: float, point_info: LocalPointInfo, metadata: Dictionary = {}) -> bool: return not is_point_selected(object, key)
func get_linked_points_func(object: Variant, key: float, point_info: LocalPointInfo, metadata: Dictionary = {}) -> bool: return selected_points.has(object) and not selected_points[object].is_empty()

func get_points_info_closed_to(cond_method: Callable, rect: Rect2) -> Dictionary[StringName, Variant]:
	var closed_points: Dictionary[Variant, Dictionary]
	var focused_point: GlobalPointInfo
	
	for object: Variant in selectable_points_objects:
		var selectable_points: Dictionary[float, LocalPointInfo] = selectable_points_objects[object]
		closed_points[object] = {}
		
		for point_key: float in selectable_points:
			var point_info: LocalPointInfo = selectable_points[point_key]
			
			if cond_method.call(object, point_key, point_info, rect):
				closed_points[object][point_key] = point_info
				#if selected_points.has(object) and selected_points[object].has(point_key):
					#continue
				#focused_point = GlobalPointInfo.new(object, point_key, point_info)
	
	return {&"result": closed_points, &"new_focused_point": focused_point}

func get_points_close_distance_cond_func(object: Variant, point_key: float, point_info: LocalPointInfo, rect: Rect2) -> bool:
	return point_info.point_display_pos.distance_to(rect.position) <= control_close_distance

func get_points_inside_rect_cond_func(object: Variant, point_key: float, point_info: LocalPointInfo, rect: Rect2) -> bool:
	return rect.has_point(point_info.point_display_pos)


func update_selectable_points_display_poss(method: Callable = update_selectable_points_display_poss_func) -> void:
	for object: Variant in selectable_points_objects:
		var selectable_points: Dictionary[float, LocalPointInfo] = selectable_points_objects[object]
		for point_key: float in selectable_points:
			var point_info: LocalPointInfo = selectable_points[point_key]
			point_info.point_display_pos = method.call(point_key, point_info)

func update_selectable_points_display_poss_func(point_key: float, point_info: LocalPointInfo) -> Vector2:
	return Vector2.ZERO


func _on_visibility_changed() -> void:
	set_process_input(is_visible_in_tree())

func _on_mouse_entered() -> void:
	pass

func _on_mouse_exited() -> void:
	pass
