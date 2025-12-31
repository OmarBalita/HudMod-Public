class_name CurveController extends SelectContainer

signal keys_editing()

enum KeysType {
	KEY_TYPE_VEC_1,
	KEY_TYPE_VEC_2,
	KEY_TYPE_VEC_3,
	KEY_TYPE_VEC_4,
}

const KEYS_COLORS: Array[Color] = [
	Color.RED,
	Color.GREEN,
	Color.BLUE,
	Color.VIOLET,
]

var keys_info: Array[Dictionary] = [
	{v=true},
	{v=true},
	{v=true},
	{v=true}
]

@export var curves_profiles: Array[CurveSampler.Profile]:
	set(val):
		curves_profiles = val
		for index: int in curves_profiles.size():
			add_selectable_object(index, {})
			
			var profile: CurveSampler.Profile = curves_profiles[index]
			
			var keys: Dictionary[float, CurveKey] = profile.keys
			var values: Array[float]
			
			for key: float in keys:
				var curve_key:= keys[key]
				values.append(curve_key.value)
				_on_profile_key_added(index, key, curve_key)
			
			#var center: float
			#if values.size() > 1:
				#center = (values.min() + values.max()) / 2.0
			#elif values.size() == 1:
				#center = values[0]
			#min_val = center - min_val
			#max_val = center + max_val
			
			profile.key_added.connect(func(x: float, curve_key: CurveKey) -> void:
				_on_profile_key_added(index, x, curve_key)
			)
			profile.key_removed.connect(func(x: float) -> void:
				_on_profile_key_removed(index, x)
			)

@export_group("Range")
@export var min_val: float = -200.0
@export var max_val: float = 200.0
@export var val_step: float = .01
@export var min_domain: float = -100.0
@export var max_domain: float = 100.0
@export var domain_step: float = 1.0

@export_group("Draw", "draw")
@export var draw_cursor: bool = false
@export var draw_val_step: int = 50
@export var draw_domain_step: int = 50
@export var draw_select_color: Color = Color.ORANGE

@export_group("Theme")
@export_subgroup("Texture")
@export var keyframe_texture: Texture2D = preload("res://Asset/Icons/keyframe.png")
@export var lock_texture: Texture2D = preload("res://Asset/Icons/padlock.png")
@export var unlock_texture: Texture2D = preload("res://Asset/Icons/padlock-unlock.png")
@export_subgroup("Constant")
@export var navigate_dist: float = 30.0
@export var navigate_speed: float = 200.0
@export_group("Font")
@export var font: Font = preload("res://Asset/Fonts/Cascadia.ttf")


var cursor_pos: float

var focused_keys_index: int = -1:
	set(val):
		if val != focused_keys_index:
			focused_keys_index = val
			queue_redraw()

var is_cursor_focused: bool = false:
	set(val):
		if val != is_cursor_focused:
			is_cursor_focused = val
			queue_redraw()

var is_control_focused: bool


func get_cursor_pos() -> int:
	return cursor_pos

func set_cursor_pos(new_val: int) -> void:
	cursor_pos = new_val
	queue_redraw()

func format_x(x: float) -> float:
	return clamp(snapped(x, domain_step), min_domain, max_domain)

func keys_get(keys_index: int) -> Dictionary[float, CurveKey]:
	return curves_profiles[keys_index].keys

func keys_set(keys_index: int, keys: Dictionary[float, CurveKey]) -> void:
	curves_profiles[keys_index].keys = keys

func keys_has(keys_index: int, x: float) -> bool:
	return curves_profiles[keys_index].keys.has(x)

func keys_add(keys_index: int, x: float, curve_key: CurveKey, sort_keys: bool, redraw: bool = true) -> void:
	if keys_index < 0: return
	x = format_x(x)
	curve_key.value = curve_key.value
	var profile: CurveSampler.Profile = curves_profiles[keys_index]
	var keys:= profile.keys
	keys[x] = curve_key
	if sort_keys:
		curves_profiles[keys_index].update_profile()
		keys_editing.emit()
	add_selectable_point(keys_index, x, curve_key, get_display_pos_from_coord(Vector2(x, curve_key.value)))
	if redraw:
		queue_redraw()

func keys_delete(keys_index: int, x: float, deselect_key: bool, sort_keys: bool = false, redraw: bool = true) -> void:
	if keys_index < 0: return
	var keys:= keys_get(keys_index)
	keys.erase(x)
	if sort_keys:
		curves_profiles[keys_index].update_profile()
		keys_editing.emit()
	delete_selectable_point(keys_index, x)
	if deselect_key:
		deselect_point(keys_index, x)
	if redraw:
		queue_redraw()

func keys_move(keys_index: int, x_from: float, to: Vector2, sort_keys: bool = true, redraw: bool = true) -> bool:
	if keys_index < 0: return false
	var same_x:= x_from == to.x
	var has_key:= keys_has(keys_index, to.x)
	var can_move_to: bool = (not same_x and not has_key) or (same_x and has_key) or (to.x in [min_domain, max_domain])
	if can_move_to:
		var curve_key: CurveKey = keys_get(keys_index)[x_from]
		curve_key.value = to.y
		keys_delete(keys_index, x_from, false, false, false)
		keys_add(keys_index, to.x, curve_key, sort_keys, redraw)
	return can_move_to

func keys_merge(keys_index: int, new_keys: Dictionary[float, CurveKey]) -> void:
	var keys:= keys_get(keys_index)
	keys_get(keys_index)
	keys.merge(new_keys)
	keys.sort()
	queue_redraw()

#func keys_change_control_mode(keys_index: int, x: float, target_control_mode: CurveKey.ControlMode = -1) -> void:
	#var curve_profile: CurveSampler.Profile = curves_profiles.get(keys_index)
	#var keys_keys: Array = curve_profile.keys_keys
	#
	#var curve_key: CurveKey = curve_profile.keys[x]
	#var key_coord: Vector2 = Vector2(x, curve_key.value)
	#
	#var left_reset_dir: Vector2 = get_control_vector_left_dir(key_coord, curve_profile)
	#var right_reset_dir: Vector2 = get_control_vector_right_dir(key_coord, curve_profile)
	#
	#if target_control_mode == -1:
		#curve_key.move_control_mode(left_reset_dir, right_reset_dir)
	#else:
		#curve_key.set_control_mode(target_control_mode, left_reset_dir, right_reset_dir)
	#curve_profile.update_profile()

#func get_control_vector_left_dir(key_coord: Vector2, profile: CurveSampler.Profile) -> Vector2:
	#var result: Vector2
	#var key_index: int = profile.keys_keys.find(key_coord.x)
	#if key_index > 0:
		#var before_key: float = profile.keys_keys[key_index - 1]
		#result = Vector2(before_key, profile.keys[before_key].value) - key_coord
	#else:
		#result = Vector2.LEFT
	#return result
#
#func get_control_vector_right_dir(key_coord: Vector2, profile: CurveSampler.Profile) -> Vector2:
	#var result: Vector2
	#var key_index = profile.keys_keys.find(key_coord.x)
	#if key_index < profile.keys.size() - 1:
		#var after_key: float = profile.keys_keys[key_index + 1]
		#result = Vector2(after_key, profile.keys[after_key].value) - key_coord
	#else:
		#result = Vector2.RIGHT
	#return result

func curve_key_move_control_mode(keys_index: int, key: float) -> void:
	keys_get(keys_index)[key].move_control_mode()
	curves_profiles[keys_index].update_profile()

func update_curve_profiles_keys() -> void:
	for curve_profile: CurveSampler.Profile in curves_profiles:
		curve_profile.update_profile()

func keys_find_key(keys_index: int, mouse_pos: Vector2, ignored_keys: Dictionary) -> Variant:
	var keys:= keys_get(keys_index)
	var result: Variant = null
	for key: float in keys:
		if ignored_keys.has(key):
			continue
		var val: float = keys[key].value
		var coord:= Vector2(key, val)
		if get_display_pos_from_coord(coord).distance_to(mouse_pos) <= control_close_distance:
			result = coord
			break
	return result

func find_key(mouse_pos: Vector2, ignored_keys: Dictionary) -> Dictionary[StringName, Variant]:
	for keys_index: int in curves_profiles.size():
		if not keys_info[keys_index].v:
			continue
		var index_result: Variant = keys_find_key(keys_index, mouse_pos, ignored_keys[keys_index] if ignored_keys.has(keys_index) else {})
		if index_result is Vector2:
			return {&"keys_index": keys_index, &"coord": index_result}
	return {&"keys_index": -1, &"coord": null}

func find_control(mouse_pos: Vector2, disabled: bool) -> Dictionary[StringName, Variant]:
	var default_result: Dictionary[StringName, Variant] = {
		&"curve_key": null,
		&"control_type": 0,
		&"keys_index": -1,
		&"coord": Vector2.ZERO,
		&"mouse_dist_to": .0
	}
	if disabled:
		return default_result
	else:
		return loop_selected_points(default_result,
			func(object: Variant, key: float, info: Dictionary[StringName, Variant]) -> bool:
				if not keys_info[object].v:
					return false
				
				var curve_profile: CurveSampler.Profile = curves_profiles[object]
				var key_index: int = curve_profile.keys_keys.find(key)
				
				var curve_key: CurveKey = curve_profile.keys[key]
				var key_coord: Vector2 = Vector2(key, curve_key.value)
				
				var left_coord: Vector2 = key_coord + curve_key.left_control
				var dist_to_left: float = get_display_pos_from_coord(left_coord).distance_to(mouse_pos)
				
				if key_index > 0:
					var before_key: float = curve_profile.keys_keys[key_index - 1]
					var before_curve_key: CurveKey = curve_profile.keys[before_key]
					if before_curve_key.interpolation_mode == 2:
						if dist_to_left <= control_close_distance:
							info.curve_key = curve_key
							info.control_type = 1
							info.keys_index = object
							info.key_coord = key_coord
							info.coord = left_coord
							info.mouse_dist_to = dist_to_left
							return true
				
				var right_coord: Vector2 = key_coord + curve_key.right_control
				var dist_to_right: float = get_display_pos_from_coord(right_coord).distance_to(mouse_pos)
				
				if key_index < curve_profile.keys.size() - 1:
					if curve_key.interpolation_mode == 2:
						if dist_to_right <= control_close_distance:
							info.curve_key = curve_key
							info.control_type = 2
							info.keys_index = object
							info.key_coord = key_coord
							info.coord = right_coord
							info.mouse_dist_to = dist_to_right
							return true
				
				return false
		)

func find_focused_keys_index(coord: Vector2, mouse_pos: Vector2) -> int:
	var result: Dictionary[int, float] = {-1: INF}
	for keys_index: int in curves_profiles.size():
		if not keys_info[keys_index].v:
			continue
		var profile: CurveSampler.Profile = curves_profiles[keys_index]
		var x1: float = coord.x
		var x2: float = coord.x + .01
		var y1: float = profile.sample_func.call(x1)
		var y2: float = profile.sample_func.call(x2)
		var y_diff: float = abs(get_display_pos_from_val(y1) - mouse_pos.y)
		
		var slope: float = abs(y2 - y1) / abs(x2 - x1)
		var dynamic_focus_close_dist: float = 3.0 * (1.0 + slope)
		
		if y_diff <= dynamic_focus_close_dist:
			if y_diff < result.values()[0]:
				result = {keys_index: y_diff}
	
	return result.keys()[0]

func get_coord_from_display_pos(pos: Vector2) -> Vector2:
	var coord:= Vector2(
		get_domain_from_display_pos(pos.x),
		get_val_from_display_pos(pos.y)
	)
	if is_snapped:
		coord = snapped(coord, draw_step)
	return coord

func get_display_pos_from_coord(coord: Vector2) -> Vector2:
	return Vector2(
		get_display_pos_from_domain(coord.x),
		get_display_pos_from_val(coord.y)
	)

func get_val_from_display_pos(pos: float) -> float:
	return snappedf(min_val + pos * (max_val - min_val) / size.y, val_step)

func get_display_pos_from_val(val_step: float) -> float:
	return (val_step - min_val) * (size.y / (max_val - min_val))

func get_domain_from_display_pos(pos: float) -> float:
	return clamp(snappedf(min_domain + pos * (max_domain - min_domain) / size.x, domain_step), min_domain, max_domain)

func get_display_pos_from_domain(domain_step: float) -> float:
	return (domain_step - min_domain) * (size.x / (max_domain - min_domain))


func navigate_value(offset: float) -> void:
	min_val += offset
	max_val += offset
	update_selectable_points_display_poss()

func zoom_value(scale: float) -> void:
	var val_size:= max_val - min_val
	var zoom_sign:= signf(scale)
	if val_size <= 25.0 and zoom_sign == -1: return
	elif val_size >= 1000.0 and zoom_sign == 1: return
	scale *= (val_size) / 100.
	min_val -= scale
	max_val += scale
	update_selectable_points_display_poss()

func update_selectable_points_display_poss_func(point_key: float, point_info: LocalPointInfo) -> Vector2:
	return get_display_pos_from_coord(Vector2(point_key, point_info.point_val.value))


func update_navigation_offset(mouse_pos: Vector2) -> void:
	var navigation_offset: float = .0
	if mouse_pos.y <= navigate_dist:
		navigation_offset = -navigate_speed
	elif mouse_pos.y > size.y - navigate_dist:
		navigation_offset = navigate_speed
	set_meta(&"navigation_offset", navigation_offset)


func on_point_delete(object: Variant, key: float) -> void:
	keys_get(object).erase(key)

func on_delete_ended() -> void:
	update_curve_profiles_keys()

func on_point_past(object: Variant, key: float) -> void:
	var new_key: float = format_x(cursor_pos + key - start_copied_point)
	var copied_k: CurveKey = copied_points[object][key].point_val
	var pasted_k: CurveKey = CurveKey.new(copied_k.value, copied_k.left_control, copied_k.right_control, copied_k.control_mode)
	keys_add(object, new_key, pasted_k, false, false)

func on_past_ended() -> void:
	update_curve_profiles_keys()

func get_menu_options() -> Array:
	var super_options: Array = super()
	var control_option:= MenuOption.new("Control Mode", null)
	var interpolation_option:= MenuOption.new("Interpolation Mode", null)
	
	control_option.forward = [
		MenuOption.new("Free", null, set_keys_control_mode.bind(0)),
		MenuOption.new("Aligned", null, set_keys_control_mode.bind(1)),
		MenuOption.new("Vector", null, set_keys_control_mode.bind(2)),
		MenuOption.new("Zero", null, set_keys_control_mode.bind(3)),
	]
	interpolation_option.forward = [
		MenuOption.new("Constant", null, set_keys_transition_mode.bind(0)),
		MenuOption.new("Linear", null, set_keys_transition_mode.bind(1)),
		MenuOption.new("Bezier Curve", null, set_keys_transition_mode.bind(2)),
		MenuOption.new("Ease In", null, set_keys_transition_mode.bind(3)),
		MenuOption.new("Ease Out", null, set_keys_transition_mode.bind(4)),
		MenuOption.new("Ease In Out", null, set_keys_transition_mode.bind(5)),
		MenuOption.new("Expo In Out", null, set_keys_transition_mode.bind(6)),
		MenuOption.new("Circ In Out", null, set_keys_transition_mode.bind(7)),
		MenuOption.new("Cubic", null, set_keys_transition_mode.bind(8)),
		MenuOption.new("Quart", null, set_keys_transition_mode.bind(9)),
		MenuOption.new("Quint", null, set_keys_transition_mode.bind(10)),
		MenuOption.new("Elastic", null, set_keys_transition_mode.bind(11)),
		MenuOption.new("Bounce", null, set_keys_transition_mode.bind(12)),
	]
	
	return [
		control_option,
		interpolation_option,
		MenuOption.new_line()
	] + super_options

func set_keys_control_mode(mode: CurveKey.ControlMode) -> void:
	loop_selected_points({},
		func(object: Variant, key: float, info: Dictionary[StringName, Variant]) -> void:
			curves_profiles[object].keys[key].set_control_mode(mode),
		func(object: Variant) -> void: curves_profiles[object].update_profile()
	)
	queue_redraw()

func set_keys_transition_mode(mode: CurveKey.InterpolationMode) -> void:
	loop_selected_points({},
		func(object: Variant, key: float, info: Dictionary[StringName, Variant]) -> void:
			curves_profiles[object].keys[key].set_interpolation_mode(mode),
		func(object: Variant) -> void: curves_profiles[object].update_profile()
	)
	queue_redraw()

func change_channel_visibility(channel_index: int) -> void:
	if curves_profiles.size() - 1 < channel_index: return
	keys_info[channel_index].v = not keys_info[channel_index].v
	queue_redraw()


func _init() -> void:
	super()
	
	selection_box_cond = func() -> bool:
		return focused_keys_index == -1 and not is_cursor_focused and not is_control_focused
	
	clip_contents = true
	add_theme_stylebox_override("panel", IS.STYLE_CORNERLESS)
	
	# Test
	curves_profiles = [CurveSampler.create_profile({})]

func _ready() -> void:
	super()
	shortcut_node.register_shortcut_quickly(&"visible_x", change_channel_visibility.bind(0), [ShortcutNode.new_event_key(Key.KEY_X)])
	shortcut_node.register_shortcut_quickly(&"visible_y", change_channel_visibility.bind(1), [ShortcutNode.new_event_key(Key.KEY_Y)])
	shortcut_node.register_shortcut_quickly(&"visible_z", change_channel_visibility.bind(2), [ShortcutNode.new_event_key(Key.KEY_Z)])
	shortcut_node.register_shortcut_quickly(&"visible_w", change_channel_visibility.bind(3), [ShortcutNode.new_event_key(Key.KEY_W)])
	set_process(false)

func _gui_input(event: InputEvent) -> void:
	super(event)
	
	if event is InputEventMouse:
		
		var mouse_pos: Vector2 = get_local_mouse_position()
		var coord: Vector2 = get_coord_from_display_pos(mouse_pos)
		var curr_focused_keys_index: int = focused_keys_index
		
		var curr_motion_mode: int = get_meta(&"motion_mode", 0)
		
		var finded_key: Dictionary[StringName, Variant] = find_key(mouse_pos, selected_points if curr_motion_mode == 3 else {})
		var is_key_finded: bool = finded_key.keys_index != -1
		
		var finded_control: Dictionary[StringName, Variant] = find_control(mouse_pos, curr_motion_mode == 2)
		var is_control_finded: bool = finded_control.curve_key != null
		
		if is_control_finded:
			coord = finded_control.coord
			curr_focused_keys_index = finded_control.keys_index
		elif is_key_finded:
			coord = finded_key.coord
			curr_focused_keys_index = finded_key.keys_index
		
		is_cursor_focused = abs(mouse_pos.x - get_display_pos_from_domain(cursor_pos)) <= control_drag_distance
		is_control_focused = is_control_finded
		
		if event is InputEventMouseButton:
			var is_pressed: bool = event.is_pressed()
			var motion_mode: int
			
			match event.button_index:
				
				MOUSE_BUTTON_LEFT:
					
					if is_pressed:
						if draw_cursor and is_cursor_focused:
							motion_mode = 1
						elif is_control_finded and finded_control.curve_key.control_mode != 3:
							set_meta(&"keys_index", curr_focused_keys_index)
							set_meta(&"curve_key", finded_control.curve_key)
							set_meta(&"control_type", finded_control.control_type)
							set_meta(&"point_coord", finded_control.key_coord)
							motion_mode = 2
				
				MOUSE_BUTTON_RIGHT:
					
					if is_pressed:
						if is_control_finded and finded_control.curve_key.control_mode != 3:
							var keys_index: int = finded_control.keys_index
							var key: float = finded_control.key_coord.x
							curve_key_move_control_mode(keys_index, key)
						else:
							motion_mode = 4
					else:
						if is_key_finded and not get_meta(&"mouse_moved"):
							popup_options_menu()
				
				_:
					if event.shift_pressed:
						if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
							zoom_value(5.0)
						elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
							zoom_value(-5.0)
			
			
			if is_pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
				set_meta(&"press_pos", mouse_pos)
				set_meta(&"mouse_moved", false)
				if (not is_control_finded or finded_control.curve_key.control_mode == 3) and motion_mode not in [1, 2] and curr_focused_keys_index > -1:
					var value: Variant = curves_profiles[curr_focused_keys_index].sample(coord.x)
					var has_key_already: bool = keys_has(curr_focused_keys_index, coord.x)
					if not has_key_already:
						if event.button_index == MOUSE_BUTTON_RIGHT:
							pass
						else:
							keys_add(curr_focused_keys_index, coord.x, CurveKey.new(value), true)
					select_point(curr_focused_keys_index, coord.x, not has_key_already)
					set_meta(&"keys_index", curr_focused_keys_index)
					set_meta(&"point_coord", Vector2(coord.x, value))
					motion_mode = 4 if motion_mode == 4 else 3
			else:
				if curr_motion_mode == 3:
					manage_point(
						find_key(mouse_pos, {}).keys_index,
						get_meta(&"point_coord").x,
						event.alt_pressed,
						not get_meta(&"mouse_moved", false) and not event.ctrl_pressed
					)
				queue_redraw()
			
			set_meta(&"motion_mode", motion_mode)
			set_meta(&"coord", coord)
			set_meta(&"navigation_offset", .0)
			set_process(event.is_pressed())
		
		elif event is InputEventMouseMotion:
			
			if not is_key_finded: focused_keys_index = find_focused_keys_index(coord, mouse_pos)
			else: focused_keys_index = curr_focused_keys_index
			
			var value_delta: float = -event.relative.y / (size.y / (max_val - min_val))
			
			match curr_motion_mode:
				1:
					cursor_pos = coord.x
				2:
					var curve_key: CurveKey = get_meta(&"curve_key")
					var control_type: int = get_meta(&"control_type")
					var key_coord: Vector2 = get_meta(&"point_coord")
					var control_target_coord: Vector2 = coord - key_coord
					var profile: CurveSampler.Profile = curves_profiles[focused_keys_index]
					if curve_key.control_mode != CurveKey.ControlMode.CONTROL_MODE_VECTOR:
						var set_control_func: Callable
						if control_type == 1:
							set_control_func = func(curve_key: CurveKey, new_val: Vector2) -> void:
								curve_key.set_left_control(new_val)
						elif control_type == 2:
							set_control_func = func(curve_key: CurveKey, new_val: Vector2) -> void:
								curve_key.set_right_control(new_val)
						set_control_func.call(curve_key, control_target_coord)
						if EditorServer.time_line.timeline_edit_mode:
							loop_selected_points({},
								func(object: Variant, key: float, info: Dictionary[StringName, Variant]) -> void:
									var curr_curve_key: CurveKey = keys_get(object)[key]
									if curr_curve_key.interpolation_mode == 2:
										set_control_func.call(curr_curve_key, control_target_coord)
							)
						update_navigation_offset(mouse_pos)
						curves_profiles[get_meta(&"keys_index")].update_profile()
				
				3:
					_input_move_selected_points(coord, mouse_pos)
				4:
					navigate_value(value_delta)
				5:
					navigate_value(value_delta)
			
			if curr_motion_mode != 0:
				if mouse_pos.distance_to(get_meta(&"press_pos")):
					set_meta(&"mouse_moved", true)
				queue_redraw()
			
			set_meta(&"coord", coord)
			
			var drawable_rect: DrawableRect = EditorServer.drawable_rect
			var target_global_mouse_pos: Vector2 = get_display_pos_from_coord(coord) + (self.global_position - drawable_rect.global_position)
			var target_color: Color = Color.WHITE if is_key_finded or is_control_finded else Color(Color.WHITE, .5)
			drawable_rect.draw_new_cursor(target_global_mouse_pos, target_color, false)
			drawable_rect.draw_new_string(font, Vector2(20., -10.) + target_global_mouse_pos, str(coord), 0, 16, target_color)

func _input_move_selected_points(coord: Vector2, mouse_pos: Vector2) -> void:
	var init_point_keys_index: int = get_meta(&"keys_index")
	var init_point_coord: Vector2 = get_meta(&"point_coord")
	var init_point_coord_delta: Vector2 = coord - init_point_coord
	
	coord.x = format_x(coord.x)
	
	if keys_move(init_point_keys_index, init_point_coord.x, coord, false, false):
		
		for object: Variant in selected_points:
			var object_selected_points: Dictionary = selected_points[object]
			
			var profile: CurveSampler.Profile = curves_profiles[object]
			var point_new_coord: Vector2
			
			var replaced_keys: Dictionary[float, float]
			
			for key: float in object_selected_points:
				if key == init_point_coord.x:
					continue
				elif not object_selected_points.has(key):
					continue
				point_new_coord = Vector2(key, object_selected_points[key].point_val.value) + init_point_coord_delta
				point_new_coord.x = format_x(point_new_coord.x)
				if keys_move(object, key, point_new_coord, false, false):
					replaced_keys[key] = point_new_coord.x
			
			curves_profiles[object].update_profile()
			
			for from_key: float in replaced_keys:
				var new_key: float = replaced_keys[from_key]
				deselect_point(object, from_key)
				select_point(object, new_key, false)
		
		deselect_point(init_point_keys_index, init_point_coord.x)
		select_point(init_point_keys_index, coord.x, false)
		
		set_meta(&"point_coord", coord)
	
	update_navigation_offset(mouse_pos)
	
	keys_editing.emit()


var latest_mouse_pos: Vector2
func _process(delta: float) -> void:
	var nav_offset: float = get_meta(&"navigation_offset")
	var val_size:= max_val - min_val
	nav_offset *= (val_size) / 100.
	navigate_value(nav_offset * delta)
	var curr_mouse_pos:= get_local_mouse_position()
	if nav_offset or curr_mouse_pos != latest_mouse_pos:
		queue_redraw()
	latest_mouse_pos = curr_mouse_pos


func _draw() -> void:
	
	var val_size: float = max_val - min_val
	var domain_size: float = max_domain - min_domain
	
	var val_display_size: Vector2 = size / val_size
	
	var y_offset: float = min_val - float(int(min_val) % draw_val_step)
	var y_displacement: float = y_offset - int(y_offset)
	
	if is_snapped:
		var x_snap_steps_count: int = domain_size / draw_step.x + 1
		var y_snap_steps_range: Array = range(-50, val_size / draw_step.y + 50)
		
		var snap_grid_color: Color = Color(Color.WHITE, .1)
		
		for snap_step: int in x_snap_steps_count:
			var x_pos:= get_display_pos_from_domain(min_domain + snap_step * draw_step.x)
			draw_line(Vector2(x_pos, .0), Vector2(x_pos, size.y), snap_grid_color)
		
		for snap_step: int in y_snap_steps_range:
			var y_pos:= get_display_pos_from_val(y_offset + snap_step * draw_step.y - y_displacement)
			draw_line(Vector2(.0, y_pos), Vector2(size.x, y_pos), snap_grid_color)
	
	var val_steps_count: int = val_size / draw_val_step + 2
	var domain_steps_count: int = domain_size / draw_domain_step
	var grid_color: Color = Color(Color.WHITE, .2)
	
	for step: int in val_steps_count:
		var val_step: float = y_offset + step * draw_val_step - y_displacement
		var y_pos: float = get_display_pos_from_val(val_step)
		var start_pos:= Vector2(.0, y_pos)
		var end_pos:= Vector2(size.x, y_pos)
		draw_line(start_pos, end_pos, grid_color, 2.0)
		draw_string(font, start_pos + Vector2(10., .0), str(val_step))
	
	#for step: float in range(1, domain_steps_count):
		#var domain_step: float = min_domain + step * draw_domain_step
		#var x_pos: float = get_display_pos_from_domain(domain_step)
		#draw_line(Vector2(x_pos, .0), Vector2(x_pos, size.y), grid_color, 2.0)
	
	var curves_profiles_size: int = curves_profiles.size()
	for keys_index: int in curves_profiles_size:
		if not keys_info[keys_index].v:
			continue
		
		var profile: CurveSampler.Profile = curves_profiles[keys_index]
		var keys: Dictionary[float, CurveKey] = profile.keys
		var keys_keys: Array[float] = profile.keys_keys
		var color_alpha: float
		
		if not is_cursor_focused and keys_index == focused_keys_index:
			color_alpha = 1.
		else:
			color_alpha = .5
		
		var keys_color: Color
		if curves_profiles_size == 1: keys_color = Color.WHITE
		else: keys_color = KEYS_COLORS[keys_index]
		keys_color = Color(keys_color, color_alpha)
		
		var latest_draw_control: bool
		for index: int in range(0, keys.size() - 1):
			
			var key_a: float = keys_keys[index]
			var key_b: float = keys_keys[index + 1]
			
			var curve_key: CurveKey = keys.get(key_a)
			
			var val_a: float = curve_key.value
			var val_b: float = keys.get(key_b).value
			
			var latest_coord:= Vector2(key_a, val_a)
			var latest_display_pos:= get_display_pos_from_coord(latest_coord)
			
			var draw_control: bool = curve_key.interpolation_mode == 2
			_draw_key(latest_coord, keys[key_a], latest_draw_control, draw_control, latest_display_pos, is_point_selected(keys_index, key_a), color_alpha)
			latest_draw_control = draw_control
			
			var display_pos_a:= get_display_pos_from_coord(Vector2(key_a, val_a))
			var display_pos_b:= get_display_pos_from_coord(Vector2(key_b, val_b))
			
			match curve_key.interpolation_mode:
				0:
					var display_target_pos: Vector2 = Vector2(display_pos_b.x, display_pos_a.y)
					draw_line(display_pos_a, display_target_pos, keys_color, 2.0)
					draw_line(display_target_pos, display_pos_b, keys_color, 2.0)
				1:
					draw_line(display_pos_a, display_pos_b, keys_color, 2.0)
				_:
					var drawed_samples_count: int = (key_b - key_a)
					for offset: int in range(1, drawed_samples_count):
						var new_key_a: float = key_a + offset
						var new_coord:= Vector2(new_key_a, profile.sample_func.call(new_key_a))
						var new_display_pos:= get_display_pos_from_coord(new_coord)
						draw_line(latest_display_pos, new_display_pos, keys_color, 2.0)
						latest_coord = new_coord; latest_display_pos = new_display_pos
					
					draw_line(latest_display_pos, display_pos_b, keys_color, 2.0)
		
		if keys.size():
			var back_curve_key: CurveKey = keys[keys_keys.back()]
			var back_coord:= Vector2(keys_keys.back(), back_curve_key.value)
			var front_pos:= get_display_pos_from_coord(Vector2(keys_keys.front(), keys[keys_keys.front()].value))
			var back_pos:= get_display_pos_from_coord(back_coord)
			draw_line(Vector2(.0, front_pos.y), front_pos, keys_color, 2.0)
			draw_line(back_pos, Vector2(size.x, back_pos.y), keys_color, 2.0)
			_draw_key(back_coord, back_curve_key, latest_draw_control, false, back_pos, is_point_selected(keys_index, keys_keys.back()), color_alpha)
		else:
			var val_pos:= get_display_pos_from_val(0)
			draw_line(Vector2(.0, val_pos), Vector2(size.x, val_pos), keys_color, 2.0)
	
	if draw_cursor:
		var cursor_display_pos: float = get_display_pos_from_domain(cursor_pos)
		var cursor_color: Color = Color(Color.WHITE, 1.0 if is_cursor_focused else .6)
		draw_line(Vector2(cursor_display_pos, .0), Vector2(cursor_display_pos, size.y), cursor_color, 3)


const KEY_SIZE:= Vector2(24.0, 24.0)
const KEY_SIZE_HALF:= KEY_SIZE / 2.0
const CONTROL_KEY_SIZE:= Vector2(7.5, 7.5)
const CONTROL_KEY_SIZE_HALF:= CONTROL_KEY_SIZE / 2.0

func _draw_key(coord: Vector2, curve_key: CurveKey, left_control: bool, right_control: bool, display_pos: Vector2, is_selected: bool = false, color_alpha: float = 1.) -> void:
	var rect: Rect2 = Rect2(display_pos - KEY_SIZE_HALF, KEY_SIZE)
	var color: Color
	
	if is_selected:
		color = draw_select_color
		var control_color: Color = Color(Color.WHITE, color_alpha)
		
		if left_control:
			var left_control_pos: Vector2 = get_display_pos_from_coord(coord + curve_key.left_control)
			draw_line(display_pos, left_control_pos, control_color, 2.0)
			draw_circle(left_control_pos, 5., control_color)
		if right_control:
			var right_control_pos: Vector2 = get_display_pos_from_coord(coord + curve_key.right_control)
			draw_line(display_pos, right_control_pos, control_color, 2.0)
			draw_circle(right_control_pos, 5., control_color)
		
		if left_control or right_control:
			var padlock_texture: Texture2D
			var padlock_color: Color
			if curve_key.control_mode in [2, 3]:
				padlock_texture = lock_texture
				padlock_color = Color.PURPLE
			else:
				padlock_texture = unlock_texture
				padlock_color = Color.SPRING_GREEN
			padlock_color = Color(padlock_color, color_alpha)
			
			draw_texture_rect(
				padlock_texture,
				Rect2(
					display_pos + Vector2(
						.0,
						-padlock_texture.get_height()
					),
					Vector2(16., 16.)
				),
				false,
				padlock_color
			)
	else:
		color = Color.WHITE
	
	draw_texture_rect(keyframe_texture, rect, false, Color(color, color_alpha))

func _on_mouse_entered() -> void:
	super()
	EditorServer.graph_editors_focused.append(self)

func _on_mouse_exited() -> void:
	super()
	focused_keys_index = -1
	EditorServer.drawable_rect.clear_drawn_entities()
	EditorServer.graph_editors_focused.erase(self)

func _on_profile_key_added(profile_index: int, x: float, curve_key: CurveKey) -> void:
	add_selectable_point(profile_index, x, curve_key, get_display_pos_from_coord(Vector2(x, curve_key.value)))
	queue_redraw()

func _on_profile_key_removed(profile_index: int, x: float) -> void:
	delete_selectable_point(profile_index, x)
	queue_redraw()






