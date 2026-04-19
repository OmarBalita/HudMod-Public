## تم كتابته بالكامل وتنفيذه من قبل Omar TOP
## ثم استلم Claude أمر الترتيب فقط.

class_name CurveController extends SelectContainer

# ==============================================================================
# SIGNALS
# ==============================================================================

signal keys_editing()


# ==============================================================================
# ENUMS & CONSTANTS
# ==============================================================================

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

const KEY_SIZE       := Vector2(24.0, 24.0)
const KEY_SIZE_HALF  := KEY_SIZE / 2.0
const CONTROL_KEY_SIZE      := Vector2(7.5, 7.5)
const CONTROL_KEY_SIZE_HALF := CONTROL_KEY_SIZE / 2.0


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var curves_profiles: Array[CurveProfile]:
	set(val):
		curves_profiles = val
		_init_curves_profiles()

@export_group("Range")
@export var min_val:      float = -200.0
@export var max_val:      float =  200.0
@export var val_step:     float = .01
@export var min_domain:   float = -100.0
@export var max_domain:   float =  100.0
@export var domain_step:  float = 1.0

@export_group("Draw", "draw")
@export var draw_cursor:       bool  = false
@export var draw_val_step:     int   = 1
@export var draw_domain_step:  int   = 1
@export var draw_select_color: Color = Color.ORANGE

@export_group("Theme")
@export_subgroup("Texture")
@export var keyframe_texture: Texture2D = preload("res://Asset/Icons/keyframe.png")
@export var lock_texture:     Texture2D = preload("res://Asset/Icons/padlock.png")
@export var unlock_texture:   Texture2D = preload("res://Asset/Icons/padlock-unlock.png")
@export_subgroup("Constant")
@export var navigate_dist:  float = -10.0
@export var navigate_speed: float = 100.0
@export var zoom_min:       float = .5
@export var zoom_max:       float = 5.

@export_group("Font")
@export var font: Font = preload("res://Asset/Fonts/Cascadia.ttf")


# ==============================================================================
# STATE
# ==============================================================================

var cursor_pos: float

var keys_info: Array[Dictionary] = [
	{v=true}, {v=true}, {v=true}, {v=true}
]

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

var latest_mouse_pos: Vector2


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _init() -> void:
	super()
	clip_contents = true
	add_theme_stylebox_override("panel", IS.STYLE_CORNERLESS)
	curves_profiles = [CurveSampler.create_profile({})]


func _ready() -> void:
	super()
	
	shortcut_node.key = &"Curve Editor"
	shortcut_node.load_shortcuts_from_settings()
	shortcut_node.methods_object = self
	
	set_process(false)
	zoom_value(20.)


func _process(delta: float) -> void:
	var nav_offset: float = get_meta(&"navigation_offset")
	nav_offset *= (max_val - min_val) / 100.0
	navigate_value(nav_offset * delta)

	var curr_mouse_pos := get_local_mouse_position()
	if nav_offset or curr_mouse_pos != latest_mouse_pos:
		queue_redraw()
	latest_mouse_pos = curr_mouse_pos


# ==============================================================================
# SETUP HELPERS
# ==============================================================================

func _init_curves_profiles() -> void:
	for index: int in curves_profiles.size():
		add_selectable_port(index, {})
		
		var profile: CurveProfile = curves_profiles[index]
		
		for key: int in profile.keys:
			_on_profile_key_added(index, key, profile.keys[key])
		
		profile.key_added.connect(func(x: int, curve_key: CurveKey) -> void:
			_on_profile_key_added(index, x, curve_key)
		)
		profile.key_removed.connect(func(x: int) -> void:
			_on_profile_key_removed(index, x)
		)


# ==============================================================================
# COORDINATE CONVERSION
# ==============================================================================

func get_coord_from_display_pos(pos: Vector2) -> Vector2:
	var coord := Vector2(
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


func get_display_pos_from_val(v: float) -> float:
	return (v - min_val) * (size.y / (max_val - min_val))


func get_domain_from_display_pos(pos: float) -> float:
	return clamp(snappedf(min_domain + pos * (max_domain - min_domain) / size.x, domain_step), min_domain, max_domain)


func get_display_pos_from_domain(d: float) -> float:
	return (d - min_domain) * (size.x / (max_domain - min_domain))


func format_x(x: int) -> int:
	return clamp(x, min_domain, max_domain)


# ==============================================================================
# CURSOR & NAVIGATION
# ==============================================================================

func get_cursor_pos() -> int:
	return cursor_pos


func set_cursor_pos(new_val: int) -> void:
	cursor_pos = new_val
	queue_redraw()


func navigate_value(offset: float) -> void:
	min_val += offset
	max_val += offset


func zoom_value(scale: float) -> void:
	var val_size := max_val - min_val
	var zoom_sign := signf(scale)
	if val_size <= zoom_min and zoom_sign == -1: return
	if val_size >= zoom_max and zoom_sign == 1:  return
	scale *= val_size / 100.0
	min_val -= scale
	max_val += scale


func update_navigation_offset(mouse_pos: Vector2) -> void:
	var navigation_offset: float = .0
	if mouse_pos.y <= navigate_dist:
		navigation_offset = -navigate_speed
	elif mouse_pos.y > size.y - navigate_dist:
		navigation_offset = navigate_speed
	set_meta(&"navigation_offset", navigation_offset)


func change_channel_visibility(channel_index: int) -> void:
	if curves_profiles.size() - 1 < channel_index: return
	keys_info[channel_index].v = not keys_info[channel_index].v
	queue_redraw()


# ==============================================================================
# KEYS — READ / WRITE
# ==============================================================================

func keys_get(keys_index: int) -> Dictionary[int, CurveKey]:
	return curves_profiles[keys_index].keys


func keys_set(keys_index: int, keys: Dictionary[int, CurveKey]) -> void:
	curves_profiles[keys_index].keys = keys


func keys_has(keys_index: int, x: int) -> bool:
	return curves_profiles[keys_index].keys.has(x)


func keys_add(keys_index: int, x: int, curve_key: CurveKey, sort_keys: bool, redraw: bool = true) -> void:
	if keys_index < 0: return
	x = format_x(x)
	var profile: CurveProfile = curves_profiles[keys_index]
	profile.keys[x] = curve_key
	if sort_keys:
		profile.update_profile()
		keys_editing.emit()
	add_selectable_val(keys_index, x, curve_key)
	if redraw:
		queue_redraw()


func keys_delete(keys_index: int, x: int, deselect_key: bool, sort_keys: bool = false, redraw: bool = true) -> void:
	if keys_index < 0: return
	keys_get(keys_index).erase(x)
	if sort_keys:
		curves_profiles[keys_index].update_profile()
		keys_editing.emit()
	delete_selectable_val(keys_index, x)
	if deselect_key:
		deselect_val(keys_index, x)
	if redraw:
		queue_redraw()


func keys_move(keys_index: int, x_from: int, to: Vector2, sort_keys: bool = true, redraw: bool = true) -> bool:
	if keys_index < 0: return false
	x_from  = format_x(x_from)
	to.x    = format_x(to.x)

	var same_x:      bool = x_from == to.x
	var has_old_key: bool = keys_has(keys_index, x_from)
	var has_key:     bool = keys_has(keys_index, to.x)
	var can_move_to: bool = has_old_key and (
		(not same_x and not has_key) or
		(same_x and has_key) or
		(to.x <= min_domain or to.x > max_domain)
	)

	if can_move_to:
		var curve_key: CurveKey = keys_get(keys_index)[x_from]
		curve_key.value = to.y
		keys_delete(keys_index, x_from, false, false, false)
		keys_add(keys_index, to.x, curve_key, sort_keys, redraw)

	return can_move_to


func keys_merge(keys_index: int, new_keys: Dictionary[int, CurveKey]) -> void:
	var keys := keys_get(keys_index)
	keys.merge(new_keys)
	keys.sort()
	queue_redraw()


func update_curve_profiles_keys() -> void:
	for curve_profile: CurveProfile in curves_profiles:
		curve_profile.update_profile()


func curve_key_move_control_mode(keys_index: int, key: int) -> void:
	keys_get(keys_index)[key].move_control_mode()
	curves_profiles[keys_index].update_profile()


# ==============================================================================
# KEYS — SELECTION OVERRIDES
# ==============================================================================

func delete_selected_vals() -> void:
	super()
	update_curve_profiles_keys()
	queue_redraw()
	keys_editing.emit()


func past_selected_vals() -> void:
	super()
	update_curve_profiles_keys()
	queue_redraw()
	keys_editing.emit()


func _delete_val(port_idx: int, idx: int) -> void:
	keys_get(port_idx).erase(idx)


func _past_val(port_idx: int, idx: int) -> void:
	var new_idx:    int      = format_x(cursor_pos + idx - copied_start)
	var copied_k:   CurveKey = copied[port_idx][idx]
	var pasted_k:   CurveKey = CurveKey.new_curve_key(
		copied_k.value, copied_k.left_control, copied_k.right_control, copied_k.control_mode
	)
	keys_add(port_idx, new_idx, pasted_k, false, false)


func set_keys_control_mode(mode: CurveKey.ControlMode) -> void:
	loop_selected_vals({},
		func(port_idx: int, idx: int, _info: Dictionary[StringName, Variant]) -> void:
			curves_profiles[port_idx].keys[idx].set_control_mode(mode),
		func(port_idx: int) -> void:
			curves_profiles[port_idx].update_profile()
	)
	queue_redraw()


func set_keys_transition_mode(mode: CurveKey.InterpolationMode) -> void:
	loop_selected_vals({},
		func(port_idx: int, idx: int, _info: Dictionary[StringName, Variant]) -> void:
			curves_profiles[port_idx].keys[idx].set_interpolation_mode(mode),
		func(port_idx: int) -> void:
			curves_profiles[port_idx].update_profile()
	)
	queue_redraw()


# ==============================================================================
# SEARCH / HIT TESTING
# ==============================================================================

func keys_find_key(keys_index: int, mouse_pos: Vector2, ignored_keys: Dictionary) -> Variant:
	for key: int in keys_get(keys_index):
		if ignored_keys.has(key): continue
		var val:   float   = keys_get(keys_index)[key].value
		var coord: Vector2 = Vector2(key, val)
		if get_display_pos_from_coord(coord).distance_to(mouse_pos) <= control_close_dist:
			return coord
	return null


func find_key(mouse_pos: Vector2, ignored_keys: Dictionary) -> Dictionary[StringName, Variant]:
	for keys_index: int in curves_profiles.size():
		if not keys_info[keys_index].v: continue
		var result: Variant = keys_find_key(
			keys_index,
			mouse_pos,
			ignored_keys[keys_index] if ignored_keys.has(keys_index) else {}
		)
		if result is Vector2:
			return {&"keys_index": keys_index, &"coord": result}
	return {&"keys_index": -1, &"coord": null}


func find_control(mouse_pos: Vector2, disabled: bool) -> Dictionary[StringName, Variant]:
	var default_result: Dictionary[StringName, Variant] = {
		&"curve_key":     null,
		&"control_type":  0,
		&"keys_index":    -1,
		&"coord":         Vector2.ZERO,
		&"mouse_dist_to": .0
	}
	if disabled:
		return default_result

	return loop_selected_vals(default_result,
		func(object: Variant, key: int, info: Dictionary[StringName, Variant]) -> bool:
			if not keys_info[object].v:
				return false

			var curve_profile: CurveProfile = curves_profiles[object]
			var key_index:     int          = curve_profile.keys_keys.find(key)
			var curve_key:     CurveKey     = curve_profile.keys[key]
			var key_coord:     Vector2      = Vector2(key, curve_key.value)

			# --- left control ---
			var left_coord:    Vector2 = key_coord + curve_key.left_control
			var dist_to_left:  float   = get_display_pos_from_coord(left_coord).distance_to(mouse_pos)

			if key_index > 0:
				var before_key:       int      = curve_profile.keys_keys[key_index - 1]
				var before_curve_key: CurveKey = curve_profile.keys[before_key]
				if before_curve_key.interpolation_mode == 2 and dist_to_left <= control_close_dist:
					info.curve_key     = curve_key
					info.control_type  = 1
					info.keys_index    = object
					info.key_coord     = key_coord
					info.coord         = left_coord
					info.mouse_dist_to = dist_to_left
					return true

			# --- right control ---
			var right_coord:   Vector2 = key_coord + curve_key.right_control
			var dist_to_right: float   = get_display_pos_from_coord(right_coord).distance_to(mouse_pos)

			if key_index < curve_profile.keys.size() - 1:
				if curve_key.interpolation_mode == 2 and dist_to_right <= control_close_dist:
					info.curve_key     = curve_key
					info.control_type  = 2
					info.keys_index    = object
					info.key_coord     = key_coord
					info.coord         = right_coord
					info.mouse_dist_to = dist_to_right
					return true

			return false
	)


func find_focused_keys_index(coord: Vector2, mouse_pos: Vector2) -> int:
	var result: Dictionary[int, float] = {-1: INF}
	for keys_index: int in curves_profiles.size():
		if not keys_info[keys_index].v: continue
		var profile: CurveProfile = curves_profiles[keys_index]
		var y1: float = profile.sample_func.call(coord.x)
		var y2: float = profile.sample_func.call(coord.x + .01)
		var y_diff: float = abs(get_display_pos_from_val(y1) - mouse_pos.y)
		var slope: float  = abs(y2 - y1) / .01
		if y_diff <= 3.0 * (1.0 + slope) and y_diff < result.values()[0]:
			result = {keys_index: y_diff}
	return result.keys()[0]


# ==============================================================================
# INPUT
# ==============================================================================

func _gui_input(event: InputEvent) -> void:
	super(event)
	if event is InputEventMouse:
		_handle_mouse_input(event)


func _handle_mouse_input(event: InputEventMouse) -> void:
	var mouse_pos: Vector2 = get_local_mouse_position()
	var coord:     Vector2 = get_coord_from_display_pos(mouse_pos)

	var curr_motion_mode:        int  = get_meta(&"motion_mode", 0)
	var finded_key:              Dictionary[StringName, Variant] = find_key(mouse_pos, selected if curr_motion_mode == 3 else {})
	var is_key_finded:           bool = finded_key.keys_index != -1
	var finded_control:          Dictionary[StringName, Variant] = find_control(mouse_pos, curr_motion_mode == 2)
	var is_control_finded:       bool = finded_control.curve_key != null
	var curr_focused_keys_index: int  = focused_keys_index

	if is_control_finded:
		coord = finded_control.coord
		curr_focused_keys_index = finded_control.keys_index
	elif is_key_finded:
		coord = finded_key.coord
		curr_focused_keys_index = finded_key.keys_index

	is_cursor_focused  = abs(mouse_pos.x - get_display_pos_from_domain(cursor_pos)) <= control_drag_dist
	is_control_focused = is_control_finded

	if event is InputEventMouseButton:
		_handle_mouse_button(event, mouse_pos, coord, curr_focused_keys_index, finded_key, finded_control, is_key_finded, is_control_finded)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event, mouse_pos, coord, curr_motion_mode, finded_key, finded_control, is_key_finded, is_control_finded, curr_focused_keys_index)


func _handle_mouse_button(
	event:                  InputEventMouseButton,
	mouse_pos:              Vector2,
	coord:                  Vector2,
	curr_focused_keys_index: int,
	finded_key:             Dictionary[StringName, Variant],
	finded_control:         Dictionary[StringName, Variant],
	is_key_finded:          bool,
	is_control_finded:      bool
) -> void:
	var is_pressed:  bool = event.is_pressed()
	var motion_mode: int  = 0

	match event.button_index:

		MOUSE_BUTTON_LEFT:
			if is_pressed:
				if draw_cursor and is_cursor_focused:
					motion_mode = 1
				elif is_control_finded and finded_control.curve_key.control_mode != 3:
					set_meta(&"keys_index",   curr_focused_keys_index)
					set_meta(&"curve_key",    finded_control.curve_key)
					set_meta(&"control_type", finded_control.control_type)
					set_meta(&"point_coord",  finded_control.key_coord)
					motion_mode = 2

		MOUSE_BUTTON_RIGHT:
			if is_pressed:
				if is_control_finded and finded_control.curve_key.control_mode != 3:
					curve_key_move_control_mode(finded_control.keys_index, finded_control.key_coord.x)
				else:
					motion_mode = 4
			else:
				if is_key_finded and not get_meta(&"mouse_moved"):
					popup_options_menu()

		MOUSE_BUTTON_WHEEL_DOWN:
			if event.ctrl_pressed: zoom_value(5.0)
		MOUSE_BUTTON_WHEEL_UP:
			if event.ctrl_pressed: zoom_value(-5.0)

	if is_pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		set_meta(&"press_pos",   mouse_pos)
		set_meta(&"mouse_moved", false)
		if (not is_control_finded or finded_control.curve_key.control_mode == 3) \
				and motion_mode not in [1, 2] \
				and curr_focused_keys_index > -1:
			var value:           Variant = curves_profiles[curr_focused_keys_index].sample(coord.x)
			var has_key_already: bool    = keys_has(curr_focused_keys_index, coord.x)
			if not has_key_already and event.button_index == MOUSE_BUTTON_LEFT:
				keys_add(curr_focused_keys_index, coord.x, CurveKey.new_curve_key(value), true)
			select_val(curr_focused_keys_index, coord.x)
			set_meta(&"keys_index",  curr_focused_keys_index)
			set_meta(&"point_coord", Vector2(coord.x, value))
			motion_mode = 4 if motion_mode == 4 else 3
	else:
		if get_meta(&"motion_mode", 0) == 3:
			manage_val(
				find_key(mouse_pos, {}).keys_index,
				get_meta(&"point_coord").x,
				event.alt_pressed,
				not get_meta(&"mouse_moved", false) and not event.ctrl_pressed
			)
		queue_redraw()

	set_meta(&"motion_mode",        motion_mode)
	set_meta(&"coord",              coord)
	set_meta(&"navigation_offset",  .0)
	set_process(event.is_pressed())


func _handle_mouse_motion(
	event:                  InputEventMouseMotion,
	mouse_pos:              Vector2,
	coord:                  Vector2,
	curr_motion_mode:       int,
	finded_key:             Dictionary[StringName, Variant],
	finded_control:         Dictionary[StringName, Variant],
	is_key_finded:          bool,
	is_control_finded:      bool,
	curr_focused_keys_index: int
) -> void:
	focused_keys_index = curr_focused_keys_index if is_key_finded else find_focused_keys_index(coord, mouse_pos)

	var value_delta: float = -event.relative.y / (size.y / (max_val - min_val))

	match curr_motion_mode:
		1: _motion_cursor(coord)
		2: _motion_control(coord, mouse_pos, finded_control)
		3: _input_move_selected_points(coord, mouse_pos)
		4: navigate_value(value_delta)
		5: navigate_value(value_delta)

	if curr_motion_mode != 0:
		if mouse_pos.distance_to(get_meta(&"press_pos")):
			set_meta(&"mouse_moved", true)
		queue_redraw()

	set_meta(&"coord", coord)
	_update_drawable_cursor(coord, mouse_pos, is_key_finded, is_control_finded)


func _motion_cursor(coord: Vector2) -> void:
	cursor_pos = coord.x


func _motion_control(coord: Vector2, mouse_pos: Vector2, finded_control: Dictionary[StringName, Variant]) -> void:
	var curve_key:          CurveKey = get_meta(&"curve_key")
	var control_type:       int      = get_meta(&"control_type")
	var key_coord:          Vector2  = get_meta(&"point_coord")
	var control_target_coord: Vector2 = coord - key_coord

	if curve_key.control_mode == CurveKey.ControlMode.CONTROL_MODE_VECTOR:
		update_navigation_offset(mouse_pos)
		curves_profiles[get_meta(&"keys_index")].update_profile()
		return

	var set_control_func: Callable
	if control_type == 1:
		set_control_func = func(ck: CurveKey, new_val: Vector2) -> void: ck.set_left_control(new_val)
	elif control_type == 2:
		set_control_func = func(ck: CurveKey, new_val: Vector2) -> void: ck.set_right_control(new_val)

	set_control_func.call(curve_key, control_target_coord)

	if EditorServer.time_line2.edit_multiple_btn.selected_id == 1:
		loop_selected_vals({},
			func(port_idx: int, idx: int, _info: Dictionary[StringName, Variant]) -> void:
				var curr_curve_key: CurveKey = keys_get(port_idx)[idx]
				if curr_curve_key.interpolation_mode == 2:
					set_control_func.call(curr_curve_key, control_target_coord)
		)

	update_navigation_offset(mouse_pos)
	curves_profiles[get_meta(&"keys_index")].update_profile()


func _input_move_selected_points(coord: Vector2, mouse_pos: Vector2) -> void:
	var init_keys_index: int     = get_meta(&"keys_index")
	var init_coord:      Vector2 = get_meta(&"point_coord")
	var coord_delta:     Vector2 = coord - init_coord

	coord.x = format_x(coord.x)

	# نحفظ snapshot من {port_idx -> {idx -> value}} قبل أي تحريك
	# لأن keys_move تحذف وتضيف في نفس الوقت، فيصبح idx القديم null أثناء الحلقة
	var snapshot: Dictionary = {}
	for port_idx: int in selected:
		snapshot[port_idx] = {}
		for idx: int in selected[port_idx]:
			var curve_key: CurveKey = keys_get(port_idx).get(idx)
			if curve_key != null:
				snapshot[port_idx][idx] = curve_key.value

	if keys_move(init_keys_index, init_coord.x, coord, false, false):
		for port_idx: int in snapshot:
			var port_snapshot: Dictionary = snapshot[port_idx]
			var replaced_keys: Dictionary[float, float]

			for idx: int in port_snapshot:
				# تخطى الـ init_point لأنه تحرك بالفعل أعلاه
				if port_idx == init_keys_index and idx == init_coord.x:
					continue
				var point_new_coord: Vector2 = Vector2(idx, port_snapshot[idx]) + coord_delta
				point_new_coord.x = format_x(point_new_coord.x)
				if keys_move(port_idx, idx, point_new_coord, false, false):
					replaced_keys[idx] = point_new_coord.x
			
			curves_profiles[port_idx].update_profile()
			
			for from_idx: int in replaced_keys:
				deselect_val(port_idx, from_idx)
				select_val(port_idx, replaced_keys[from_idx])
		
		deselect_val(init_keys_index, init_coord.x)
		select_val(init_keys_index, coord.x)
		set_meta(&"point_coord", coord)
	
	update_navigation_offset(mouse_pos)
	
	for profile: CurveProfile in curves_profiles:
		profile.update_profile()
	keys_editing.emit()


func _update_drawable_cursor(coord: Vector2, mouse_pos: Vector2, is_key_finded: bool, is_control_finded: bool) -> void:
	var drawable_rect:          DrawableRect = EditorServer.drawable_rect
	var target_global_mouse_pos: Vector2 = get_display_pos_from_coord(coord) + (self.global_position - drawable_rect.global_position)
	var target_color:            Color    = Color.WHITE if is_key_finded or is_control_finded else Color(Color.WHITE, .5)
	drawable_rect.draw_new_cursor(target_global_mouse_pos, target_color, false)
	drawable_rect.draw_new_string(font, Vector2(20., -10.) + target_global_mouse_pos, str(coord), 0, 16, target_color)


# ==============================================================================
# CONTEXT MENU
# ==============================================================================

func _get_menu_options() -> Array:
	var control_option     := MenuOption.new("Control Mode",      null)
	var interpolation_option := MenuOption.new("Interpolation Mode", null)

	control_option.forward = [
		MenuOption.new("Free",     null, set_keys_control_mode.bind(0)),
		MenuOption.new("Aligned",  null, set_keys_control_mode.bind(1)),
		MenuOption.new("Vector",   null, set_keys_control_mode.bind(2)),
		MenuOption.new("Zero",     null, set_keys_control_mode.bind(3)),
	]
	interpolation_option.forward = [
		MenuOption.new("Constant",    null, set_keys_transition_mode.bind(0)),
		MenuOption.new("Linear",      null, set_keys_transition_mode.bind(1)),
		MenuOption.new("Bezier Curve",null, set_keys_transition_mode.bind(2)),
		MenuOption.new("Ease In",     null, set_keys_transition_mode.bind(3)),
		MenuOption.new("Ease Out",    null, set_keys_transition_mode.bind(4)),
		MenuOption.new("Ease In Out", null, set_keys_transition_mode.bind(5)),
		MenuOption.new("Expo In Out", null, set_keys_transition_mode.bind(6)),
		MenuOption.new("Circ In Out", null, set_keys_transition_mode.bind(7)),
		MenuOption.new("Cubic",       null, set_keys_transition_mode.bind(8)),
		MenuOption.new("Quart",       null, set_keys_transition_mode.bind(9)),
		MenuOption.new("Quint",       null, set_keys_transition_mode.bind(10)),
		MenuOption.new("Elastic",     null, set_keys_transition_mode.bind(11)),
		MenuOption.new("Bounce",      null, set_keys_transition_mode.bind(12)),
	]

	return [
		control_option,
		interpolation_option,
		MenuOption.new_line()
	] + super()


func _request_selection_box_select(port_idx: int, _port_object: Object, idx: int) -> bool:
	return selectbox_rect.has_point(get_display_pos_from_coord(Vector2(idx, keys_get(port_idx)[idx].value)))


func _request_box_selection() -> bool:
	return focused_keys_index == -1 and not is_cursor_focused and not is_control_focused


# ==============================================================================
# DRAW
# ==============================================================================

func _draw() -> void:
	_draw_grid()
	_draw_curves()
	if draw_cursor:
		_draw_cursor_line()


func _draw_grid() -> void:
	var val_size:    float = max_val - min_val
	var domain_size: float = max_domain - min_domain

	var y_offset:      float = min_val - float(int(min_val) % draw_val_step)
	var y_displacement: float = y_offset - int(y_offset)

	if is_snapped:
		var snap_grid_color := Color(Color.WHITE, .1)
		var x_snap_steps_count: int = domain_size / draw_step.x + 1
		for snap_step: int in x_snap_steps_count:
			var x_pos := get_display_pos_from_domain(min_domain + snap_step * draw_step.x)
			draw_line(Vector2(x_pos, .0), Vector2(x_pos, size.y), snap_grid_color)
		for snap_step: int in range(-50, val_size / draw_step.y + 50):
			var y_pos := get_display_pos_from_val(y_offset + snap_step * draw_step.y - y_displacement)
			draw_line(Vector2(.0, y_pos), Vector2(size.x, y_pos), snap_grid_color)

	var grid_color      := Color(Color.WHITE, .2)
	var val_steps_count: int = val_size / draw_val_step + 2
	for step: int in val_steps_count:
		var val:   float = y_offset + step * draw_val_step - y_displacement
		var y_pos: float = get_display_pos_from_val(val)
		draw_line(Vector2(.0, y_pos), Vector2(size.x, y_pos), grid_color, 2.0)
		draw_string(font, Vector2(.0, y_pos) + Vector2(10., .0), str(val))


func _draw_curves() -> void:
	var curves_profiles_size: int = curves_profiles.size()
	for keys_index: int in curves_profiles_size:
		if not keys_info[keys_index].v: continue

		var profile:   CurveProfile          = curves_profiles[keys_index]
		var keys:      Dictionary[int, CurveKey] = profile.keys
		var keys_keys: Array                 = profile.keys_keys

		var color_alpha: float = 1.0 if (not is_cursor_focused and keys_index == focused_keys_index) else .5
		var keys_color:  Color = KEYS_COLORS[keys_index] if curves_profiles_size > 1 else Color.WHITE
		keys_color = Color(keys_color, color_alpha)

		_draw_curve_segments(profile, keys, keys_keys, keys_index, keys_color, color_alpha)
		_draw_curve_endpoints(keys, keys_keys, keys_index, keys_color, color_alpha)


func _draw_curve_segments(
	profile:    CurveProfile,
	keys:       Dictionary[int, CurveKey],
	keys_keys:  Array,
	keys_index: int,
	keys_color: Color,
	color_alpha: float
) -> void:
	var latest_draw_control: bool = false
	for index: int in range(0, keys.size() - 1):
		var key_a: int      = keys_keys[index]
		var key_b: int      = keys_keys[index + 1]
		var curve_key: CurveKey = keys[key_a]
		var val_a: float    = curve_key.value
		var val_b: float    = keys[key_b].value

		var latest_coord:       Vector2 = Vector2(key_a, val_a)
		var latest_display_pos: Vector2 = get_display_pos_from_coord(latest_coord)
		var draw_control:       bool    = curve_key.interpolation_mode == 2

		_draw_key(latest_coord, keys[key_a], latest_draw_control, draw_control, latest_display_pos, is_val_selected(keys_index, key_a), color_alpha)
		latest_draw_control = draw_control

		var display_pos_a: Vector2 = get_display_pos_from_coord(Vector2(key_a, val_a))
		var display_pos_b: Vector2 = get_display_pos_from_coord(Vector2(key_b, val_b))

		match curve_key.interpolation_mode:
			0:
				var mid_pos := Vector2(display_pos_b.x, display_pos_a.y)
				draw_line(display_pos_a, mid_pos,        keys_color, 2.0)
				draw_line(mid_pos,       display_pos_b,  keys_color, 2.0)
			1:
				draw_line(display_pos_a, display_pos_b, keys_color, 2.0)
			_:
				for offset: int in range(1, key_b - key_a):
					var new_x:           float   = key_a + offset
					var new_coord:       Vector2 = Vector2(new_x, profile.sample_func.call(new_x))
					var new_display_pos: Vector2 = get_display_pos_from_coord(new_coord)
					draw_line(latest_display_pos, new_display_pos, keys_color, 2.0)
					latest_coord = new_coord
					latest_display_pos = new_display_pos
				draw_line(latest_display_pos, display_pos_b, keys_color, 2.0)


func _draw_curve_endpoints(
	keys:       Dictionary[int, CurveKey],
	keys_keys:  Array,
	keys_index: int,
	keys_color: Color,
	color_alpha: float
) -> void:
	if keys.size() == 0:
		draw_line(Vector2(.0, get_display_pos_from_val(0)), Vector2(size.x, get_display_pos_from_val(0)), keys_color, 2.0)
		return

	var back_curve_key: CurveKey = keys[keys_keys.back()]
	var back_coord:     Vector2  = Vector2(keys_keys.back(), back_curve_key.value)
	var front_pos:      Vector2  = get_display_pos_from_coord(Vector2(keys_keys.front(), keys[keys_keys.front()].value))
	var back_pos:       Vector2  = get_display_pos_from_coord(back_coord)

	draw_line(Vector2(.0,     front_pos.y), front_pos,               keys_color, 2.0)
	draw_line(back_pos,       Vector2(size.x, back_pos.y),           keys_color, 2.0)

	# The last key also needs its diamond drawn
	var last_draw_control: bool = keys[keys_keys[keys_keys.size() - 2]].interpolation_mode == 2 if keys.size() > 1 else false
	_draw_key(back_coord, back_curve_key, last_draw_control, false, back_pos, is_val_selected(keys_index, keys_keys.back()), color_alpha)


func _draw_cursor_line() -> void:
	var cursor_display_pos: float = get_display_pos_from_domain(cursor_pos)
	var cursor_color: Color       = Color(Color.WHITE, 1.0 if is_cursor_focused else .6)
	draw_line(Vector2(cursor_display_pos, .0), Vector2(cursor_display_pos, size.y), cursor_color, 3)


func _draw_key(
	coord:         Vector2,
	curve_key:     CurveKey,
	left_control:  bool,
	right_control: bool,
	display_pos:   Vector2,
	is_selected:   bool  = false,
	color_alpha:   float = 1.
) -> void:
	var rect:  Rect2 = Rect2(display_pos - KEY_SIZE_HALF, KEY_SIZE)
	var color: Color

	if is_selected:
		color = draw_select_color
		var control_color := Color(Color.WHITE, color_alpha)

		if left_control:
			var left_pos := get_display_pos_from_coord(coord + curve_key.left_control)
			draw_line(display_pos, left_pos, control_color, 2.0)
			draw_circle(left_pos, 5., control_color)

		if right_control:
			var right_pos := get_display_pos_from_coord(coord + curve_key.right_control)
			draw_line(display_pos, right_pos, control_color, 2.0)
			draw_circle(right_pos, 5., control_color)

		if left_control or right_control:
			var padlock_texture: Texture2D
			var padlock_color:   Color
			if curve_key.control_mode in [2, 3]:
				padlock_texture = lock_texture
				padlock_color   = Color.PURPLE
			else:
				padlock_texture = unlock_texture
				padlock_color   = Color.SPRING_GREEN
			padlock_color = Color(padlock_color, color_alpha)
			draw_texture_rect(
				padlock_texture,
				Rect2(display_pos + Vector2(.0, -padlock_texture.get_height()), Vector2(16., 16.)),
				false, padlock_color
			)
	else:
		color = Color.WHITE

	draw_texture_rect(keyframe_texture, rect, false, Color(color, color_alpha))


# ==============================================================================
# SIGNAL HANDLERS
# ==============================================================================

func _on_mouse_entered() -> void:
	super()
	EditorServer.graph_editors_focused.append(self)


func _on_mouse_exited() -> void:
	super()
	focused_keys_index = -1
	EditorServer.drawable_rect.clear_drawn_entities()
	EditorServer.graph_editors_focused.erase(self)


func _on_profile_key_added(profile_index: int, x: float, curve_key: CurveKey) -> void:
	add_selectable_val(profile_index, x, curve_key)
	queue_redraw()


func _on_profile_key_removed(profile_index: int, x: float) -> void:
	delete_selectable_val(profile_index, x)
	queue_redraw()
