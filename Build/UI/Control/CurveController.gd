#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Founded by Omar Mohammed Balita.                                       ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
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
## This script was rewritten by Malek (El3tek), with some parts written by Claude AI to save time.
class_name CurveController extends SelectContainer

# ==============================================================================
# SIGNALS
# ==============================================================================

signal keys_editing()
signal linked_changed(linked: bool)


# ==============================================================================
# ENUMS & CONSTANTS
# ==============================================================================

enum KeysType {
	KEY_TYPE_VEC_1,
	KEY_TYPE_VEC_2,
	KEY_TYPE_VEC_3,
	KEY_TYPE_VEC_4,
}

enum MotionMode {
	NONE,
	CURSOR,
	CONTROL,
	MOVE_KEYS,
	PAN,
}

const KEY_SIZE		 := Vector2(24.0, 24.0)
const KEY_SIZE_HALF  := KEY_SIZE / 2.0
const CONTROL_KEY_SIZE		:= Vector2(7.5, 7.5)
const CONTROL_KEY_SIZE_HALF := CONTROL_KEY_SIZE / 2.0

const KEY_HIT_RADIUS: float = 12.0
const CONTROL_HIT_RADIUS: float = 10.0
const CURVE_HIT_DIST: float = 6.0
const MOVE_THRESHOLD: float = 3.0
const CURSOR_FONT_SIZE: int = 16

const FIT_MARGIN_LEFT: float = 48.0
const FIT_MARGIN_RIGHT: float = 24.0
const FIT_MARGIN_TOP: float = 40.0
const FIT_MARGIN_BOTTOM: float = 24.0

const HATCH_SPACING: float = 10.0


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var curves_profiles: Array[CurveProfile]:
	set(val):
		curves_profiles = val
		_init_curves_profiles()

@export_group("Range")
@export var min_val: float = -200.
@export var max_val: float = 200.
@export var val_step: float = .01
@export var min_domain: float = -100.:
	set(val):
		min_domain = val
		queue_redraw()
@export var max_domain: float = 100.:
	set(val):
		max_domain = val
		queue_redraw()
@export var domain_step: float = 1.

@export_group("Draw", "draw")
@export var draw_cursor: bool = false
@export var draw_val_step: int = 1
@export var draw_select_color: Color = Color.ORANGE

@export_group("Theme")
@export_subgroup("Texture")
@export var keyframe_texture: Texture2D = preload("res://Asset/Icons/keyframe.png")
@export var lock_texture: Texture2D = preload("res://Asset/Icons/padlock.png")
@export var unlock_texture: Texture2D = preload("res://Asset/Icons/padlock-unlock.png")
@export var fit_view_texture: Texture2D = preload("res://Asset/Icons/world-origin.png")
@export_subgroup("Constant")
@export var navigate_dist: float = -10.0
@export var navigate_speed: float = 100.0
@export var zoom_min: float = .5
@export var zoom_max: float = 5.

@export_group("Font")
@export var font: Font = preload("res://Asset/Fonts/Cascadia.ttf")

var _keys_colors: Array[Color] = [
	Color.RED,
	Color.GREEN,
	Color.BLUE,
	Color.VIOLET,
]


# ==============================================================================
# STATE
# ==============================================================================

var cursor_pos: float

var view_min_domain: float = -100.
var view_max_domain: float = 100.

## Returns the domain (Vector2(from, to)) this controller's width spans, e.g. aligned with the clip panel.
## When invalid, the x-axis spans [member min_domain]..[member max_domain]. The x-axis is never user controlled.
var full_range_getter: Callable

var keys_info: Array[Dictionary] = [{v=true}, {v=true}, {v=true}, {v=true}]

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

var linked: bool = false

# --- interaction ---
var _motion_mode: int = MotionMode.NONE
var _press_pos: Vector2
var _press_domain: float
var _press_value: float
var _mouse_moved: bool = false
var _nav_offset: float = .0

# --- hover ---
var _hover_key: Dictionary = {&"keys_index": -1, &"coord": null, &"dist": INF}
var _hover_control: Dictionary = {}

# --- pending click ---
var _pending_click: Vector2i = Vector2i(-1, -1)
var _pending_click_was_selected: bool = false

# --- control (bezier handle) drag ---
var _ctrl_curve_key: CurveKey
var _ctrl_type: int = 0
var _ctrl_keys_index: int = -1
var _ctrl_key_coord: Vector2

# --- key move drag ---
var _move_items: Array[Dictionary] = []
var _move_fixed: Dictionary = {}
var _move_min_x: int = 0
var _move_max_x: int = 0
var _move_grab_port: int = -1
var _move_grab_x0: int = 0
var _move_grab_v0: float = .0
var _move_last_dx: int = 0
var _move_last_dy: float = .0

# --- profile signal connections ---
var _profile_connections: Dictionary = {}

# --- undo / redo ---
var _edit_before: Dictionary = {}
var _edit_name: String = "move_curve_keys"

# --- fit view button ---
var _fit_button: IS.CustomTextureButton
var _fit_button_press: bool = false


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
	
	set_process(false)
	zoom_value(20.)
	
	_create_overlay()


func _process(delta: float) -> void:
	if _motion_mode == MotionMode.NONE:
		set_process(false)
		return
	
	var nav_offset: float = _nav_offset * (max_val - min_val) / 100.0
	if nav_offset != .0:
		navigate_value(nav_offset * delta)
		if _motion_mode == MotionMode.MOVE_KEYS and _mouse_moved:
			_update_move(get_local_mouse_position())
	
	var curr_mouse_pos: Vector2 = get_local_mouse_position()
	if nav_offset != .0 or curr_mouse_pos != latest_mouse_pos:
		queue_redraw()
	latest_mouse_pos = curr_mouse_pos


func _unhandled_key_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if not is_visible_in_tree() or not get_global_rect().has_point(get_global_mouse_position()):
		return
	if key_event.ctrl_pressed or key_event.alt_pressed:
		return
	
	match key_event.keycode:
		KEY_F:
			frame_all()
			get_viewport().set_input_as_handled()
		KEY_L:
			if curves_profiles.size() > 1:
				toggle_linked()
				get_viewport().set_input_as_handled()


# ==============================================================================
# SETUP HELPERS
# ==============================================================================

func _init_curves_profiles() -> void:
	for profile: CurveProfile in _profile_connections:
		if not is_instance_valid(profile): continue
		var calls: Array = _profile_connections[profile]
		if profile.key_added.is_connected(calls[0]): profile.key_added.disconnect(calls[0])
		if profile.key_removed.is_connected(calls[1]): profile.key_removed.disconnect(calls[1])
	_profile_connections.clear()
	
	for index: int in curves_profiles.size():
		add_selectable_port(index, {})
		
		var profile: CurveProfile = curves_profiles[index]
		
		for key: int in profile.keys:
			_on_profile_key_added(key, profile.keys[key], index)
		
		var added_call: Callable = _on_profile_key_added.bind(index)
		var removed_call: Callable = _on_profile_key_removed.bind(index)
		profile.key_added.connect(added_call)
		profile.key_removed.connect(removed_call)
		_profile_connections[profile] = [added_call, removed_call]
	
	if curves_profiles.size() < 2 and linked:
		linked = false


func _is_channel_visible(index: int) -> bool:
	return index >= keys_info.size() or keys_info[index].v


func _get_channel_color(index: int) -> Color:
	if curves_profiles.size() <= 1: return Color.WHITE
	return _keys_colors[index % _keys_colors.size()]


func _selected_count() -> int:
	var count: int = 0
	for port: int in selected:
		count += selected[port].size()
	return count


func _create_overlay() -> void:
	var overlay:= Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var overlay_box:= HBoxContainer.new()
	overlay_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_box.alignment = BoxContainer.ALIGNMENT_END
	overlay_box.anchor_left = 1.
	overlay_box.anchor_right = 1.
	overlay_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	overlay_box.offset_top = 4.
	overlay_box.offset_bottom = 4.
	overlay_box.offset_right = -4.
	overlay_box.offset_left = -4.
	overlay.add_child(overlay_box)

	_fit_button = IS.create_texture_button(fit_view_texture, null, null, "Fit View to Curve (F)")
	_fit_button.modulate.a = .7
	_fit_button.pressed.connect(frame_all)
	overlay_box.add_child(_fit_button)


func _is_over_fit_button() -> bool:
	return _fit_button != null and _fit_button.is_visible_in_tree() \
			and _fit_button.get_global_rect().has_point(get_global_mouse_position())


# ==============================================================================
# LINK
# ==============================================================================

func is_linked() -> bool:
	return linked


func set_linked(value: bool) -> void:
	if value and curves_profiles.size() < 2: value = false
	if linked == value: return
	linked = value
	if linked:
		_ensure_linked_columns()
		_sync_linked_selection()
	queue_redraw()
	linked_changed.emit(linked)


func toggle_linked() -> void:
	if curves_profiles.size() < 2: return
	_begin_edit()
	set_linked(not linked)
	_commit_edit("link_curves" if linked else "unlink_curves")


func _ensure_linked_columns() -> void:
	var xs: Dictionary = {}
	for profile: CurveProfile in curves_profiles:
		for x: int in profile.keys:
			xs[x] = true
	
	var changed: bool = false
	for index: int in curves_profiles.size():
		var profile: CurveProfile = curves_profiles[index]
		var added: bool = false
		for x: int in xs:
			if profile.keys.has(x): continue
			var new_key: CurveKey = CurveKey.new_curve_key(profile.sample(x))
			profile.keys[x] = new_key
			add_selectable_val(index, x, new_key)
			added = true
		if added:
			profile.update_profile()
			changed = true
	
	if changed:
		keys_editing.emit()


func _sync_linked_selection() -> void:
	if not linked: return
	
	var xs: Dictionary = {}
	for port: int in selected:
		for x: int in selected[port]:
			xs[x] = true
	
	for x: int in xs:
		for port: int in curves_profiles.size():
			if not _is_channel_visible(port): continue
			if keys_has(port, x) and not is_val_selected(port, x):
				select_val(port, x)


func _deselect_column(x: int) -> void:
	for port: int in curves_profiles.size():
		if is_val_selected(port, x):
			deselect_val(port, x)


# ==============================================================================
# VIEW DOMAIN
# ==============================================================================

## The x-axis is not user controlled: it follows [member full_range_getter] when valid,
## otherwise it fits [member min_domain]..[member max_domain].
func _update_view_domain() -> void:
	var domain: Vector2
	if full_range_getter.is_valid():
		domain = full_range_getter.call(self)
	elif size.x > 1.:
		domain = _fit_axis(min_domain, max_domain, size.x, FIT_MARGIN_LEFT, FIT_MARGIN_RIGHT)
	else:
		domain = Vector2(min_domain, max_domain)
	view_min_domain = domain.x
	view_max_domain = maxf(domain.y, domain.x + .0001)


# ==============================================================================
# UNDO / REDO
# ==============================================================================

static func _clone_keys(source: Dictionary[int, CurveKey]) -> Dictionary[int, CurveKey]:
	var out: Dictionary[int, CurveKey] = {}
	for x: int in source:
		var a: CurveKey = source[x]
		var b: CurveKey = CurveKey.new_curve_key(a.value, a.left_control, a.right_control, a.control_mode, a.interpolation_mode)
		b.variant = a.variant
		out[x] = b
	return out


func _make_snapshot() -> Dictionary:
	var keys_list: Array = []
	for profile: CurveProfile in curves_profiles:
		keys_list.append(_clone_keys(profile.keys))
	
	var selection: Dictionary = {}
	for port: int in selected:
		selection[port] = selected[port].keys()
	
	return {
		&"profiles": curves_profiles.duplicate(),
		&"keys_list": keys_list,
		&"selection": selection,
		&"linked": linked,
	}


static func _snapshots_equal(a: Dictionary, b: Dictionary) -> bool:
	if a.linked != b.linked: return false
	
	var list_a: Array = a.keys_list
	var list_b: Array = b.keys_list
	if list_a.size() != list_b.size(): return false
	
	for index: int in list_a.size():
		var keys_a: Dictionary = list_a[index]
		var keys_b: Dictionary = list_b[index]
		if keys_a.size() != keys_b.size(): return false
		for x: int in keys_a:
			if not keys_b.has(x): return false
			var ka: CurveKey = keys_a[x]
			var kb: CurveKey = keys_b[x]
			if not is_equal_approx(ka.value, kb.value): return false
			if ka.left_control != kb.left_control or ka.right_control != kb.right_control: return false
			if ka.control_mode != kb.control_mode or ka.interpolation_mode != kb.interpolation_mode: return false
			if ka.variant != kb.variant: return false
	return true


func _begin_edit() -> void:
	_edit_before = _make_snapshot()


func _commit_edit(action_name: String) -> void:
	if _edit_before.is_empty(): return
	
	var before: Dictionary = _edit_before
	_edit_before = {}
	var after: Dictionary = _make_snapshot()
	if _snapshots_equal(before, after): return
	
	var ref: WeakRef = weakref(self)
	ProjectServer2.commit_action(
		action_name,
		func() -> void: CurveController._run_snapshot(ref, after),
		func() -> void: CurveController._run_snapshot(ref, before),
		false
	)


static func _run_snapshot(ref: WeakRef, snap: Dictionary) -> void:
	var controller: CurveController = ref.get_ref() as CurveController
	if controller != null and is_instance_valid(controller) and controller._is_bound_to(snap.profiles):
		controller._restore_snapshot(snap)
		return
	
	var profiles: Array = snap.profiles
	for index: int in profiles.size():
		profiles[index].keys = _clone_keys(snap.keys_list[index])


func _is_bound_to(profiles: Array) -> bool:
	if profiles.size() != curves_profiles.size(): return false
	for index: int in profiles.size():
		if profiles[index] != curves_profiles[index]: return false
	return true


func _restore_snapshot(snap: Dictionary) -> void:
	_motion_mode = MotionMode.NONE
	_nav_offset = .0
	_move_items.clear()
	_move_fixed.clear()
	_pending_click = Vector2i(-1, -1)
	
	for port: int in selected.keys():
		for x: int in selected[port].keys():
			deselect_val(port, x)
	for port: int in curves_profiles.size():
		for x: int in curves_profiles[port].keys:
			delete_selectable_val(port, x)
	
	var keys_list: Array = snap.keys_list
	for port: int in curves_profiles.size():
		curves_profiles[port].keys = _clone_keys(keys_list[port])
		for x: int in curves_profiles[port].keys:
			add_selectable_val(port, x, curves_profiles[port].keys[x])
	
	var selection: Dictionary = snap.selection
	for port: int in selection:
		if port >= curves_profiles.size(): continue
		for x: int in selection[port]:
			if keys_has(port, x):
				select_val(port, x)
	
	if linked != snap.linked:
		linked = snap.linked
		linked_changed.emit(linked)
	
	_reset_hover()
	queue_redraw()
	keys_editing.emit()


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
	return snappedf(_raw_val_at(pos), val_step)


func get_display_pos_from_val(v: float) -> float:
	return (v - min_val) * (size.y / (max_val - min_val))


func get_domain_from_display_pos(pos: float) -> float:
	return clampf(snappedf(_raw_domain_at(pos), domain_step), min_domain, max_domain)


func get_display_pos_from_domain(d: float) -> float:
	return (d - view_min_domain) * (size.x / (view_max_domain - view_min_domain))


func format_x(x: int) -> int:
	return clampi(x, int(min_domain), int(max_domain))


func _raw_val_at(y: float) -> float:
	return min_val + y * (max_val - min_val) / maxf(size.y, 1.)


func _raw_domain_at(x: float) -> float:
	return view_min_domain + x * (view_max_domain - view_min_domain) / maxf(size.x, 1.)


# ==============================================================================
# CURSOR & NAVIGATION
# ==============================================================================

func get_cursor_pos() -> int:
	return roundi(cursor_pos)


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


func zoom_value_at(scale: float, y: float) -> void:
	var val_size := max_val - min_val
	var zoom_sign := signf(scale)
	if val_size <= zoom_min and zoom_sign == -1: return
	if val_size >= zoom_max and zoom_sign == 1:  return
	var anchor: float = _raw_val_at(y)
	var t: float = y / maxf(size.y, 1.)
	var new_size: float = maxf(val_size + 2.0 * scale * val_size / 100.0, .0001)
	min_val = anchor - t * new_size
	max_val = min_val + new_size


func frame_all() -> void:
	_fit_values_to_curves(int(min_domain), int(max_domain))
	queue_redraw()


func _fit_values_to_curves(sample_from: int, sample_to: int) -> void:
	const MAX_SAMPLES: int = 256
	
	var lo: float = INF
	var hi: float = -INF
	for index: int in curves_profiles.size():
		if not _is_channel_visible(index): continue
		var profile: CurveProfile = curves_profiles[index]
		var profile_keys: Dictionary[int, CurveKey] = profile.keys
		if profile_keys.is_empty(): continue
		
		for x: int in profile_keys:
			if x < sample_from or x > sample_to: continue
			var v: float = profile_keys[x].value
			lo = minf(lo, v)
			hi = maxf(hi, v)
		
		var step: int = maxi(1, ceili(float(sample_to - sample_from) / MAX_SAMPLES))
		for x: int in range(sample_from, sample_to + 1, step):
			var v: float = profile.sample(x)
			lo = minf(lo, v)
			hi = maxf(hi, v)
		var v_end: float = profile.sample(sample_to)
		lo = minf(lo, v_end)
		hi = maxf(hi, v_end)
	
	if lo == INF:
		lo = -1.
		hi = 1.
	
	if hi - lo < .001:
		lo -= 1.
		hi += 1.
	
	var y_range: Vector2 = _fit_axis(lo, hi, size.y, FIT_MARGIN_TOP, FIT_MARGIN_BOTTOM)
	min_val = y_range.x
	max_val = y_range.y


static func _fit_axis(lo: float, hi: float, length: float, margin_start: float, margin_end: float) -> Vector2:
	length = maxf(length, 1.)
	var usable: float = maxf(length - margin_start - margin_end, length * .5)
	var margins_scale: float = (length - usable) / (margin_start + margin_end)
	var units_per_px: float = (hi - lo) / usable
	return Vector2(
		lo - margin_start * margins_scale * units_per_px,
		hi + margin_end * margins_scale * units_per_px
	)


func update_navigation_offset(mouse_pos: Vector2) -> void:
	var navigation_offset: float = .0
	if mouse_pos.y <= navigate_dist:
		navigation_offset = -navigate_speed
	elif mouse_pos.y > size.y - navigate_dist:
		navigation_offset = navigate_speed
	_nav_offset = navigation_offset


func change_channel_visibility(channel_index: int) -> void:
	if curves_profiles.size() - 1 < channel_index: return
	if channel_index >= keys_info.size(): return
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
	x_from	= format_x(x_from)
	to.x	= format_x(int(to.x))

	var same_x:		 bool = x_from == to.x
	var has_old_key: bool = keys_has(keys_index, x_from)
	var has_key:	 bool = keys_has(keys_index, int(to.x))
	var can_move_to: bool = has_old_key and (
		(not same_x and not has_key) or
		(same_x and has_key) or
		(to.x <= min_domain or to.x > max_domain)
	)

	if can_move_to:
		var curve_key: CurveKey = keys_get(keys_index)[x_from]
		curve_key.value = to.y
		keys_delete(keys_index, x_from, false, false, false)
		keys_add(keys_index, int(to.x), curve_key, sort_keys, redraw)

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
	_begin_edit()
	super()
	update_curve_profiles_keys()
	queue_redraw()
	keys_editing.emit()
	_commit_edit("delete_curve_keys")


func past_selected_vals() -> void:
	_begin_edit()
	super()
	update_curve_profiles_keys()
	queue_redraw()
	keys_editing.emit()
	_commit_edit("paste_curve_keys")


func _delete_val(port_idx: int, idx: int) -> void:
	keys_get(port_idx).erase(idx)


func _past_val(port_idx: int, idx: int) -> void:
	var new_idx:	int		 = format_x(roundi(cursor_pos) + idx - copied_start)
	var copied_k:	CurveKey = copied[port_idx][idx]
	var pasted_k:	CurveKey = CurveKey.new_curve_key(
		copied_k.value, copied_k.left_control, copied_k.right_control,
		copied_k.control_mode, copied_k.interpolation_mode
	)
	keys_add(port_idx, new_idx, pasted_k, false, false)


func set_keys_control_mode(mode: CurveKey.ControlMode) -> void:
	_begin_edit()
	loop_selected_vals({},
		func(port_idx: int, idx: int, _info: Dictionary[StringName, Variant]) -> void:
			curves_profiles[port_idx].keys[idx].set_control_mode(mode),
		func(port_idx: int) -> void:
			curves_profiles[port_idx].update_profile()
	)
	queue_redraw()
	keys_editing.emit()
	_commit_edit("change_control_mode")


func set_keys_transition_mode(mode: CurveKey.InterpolationMode) -> void:
	_begin_edit()
	loop_selected_vals({},
		func(port_idx: int, idx: int, _info: Dictionary[StringName, Variant]) -> void:
			curves_profiles[port_idx].keys[idx].set_interpolation_mode(mode),
		func(port_idx: int) -> void:
			curves_profiles[port_idx].update_profile()
	)
	queue_redraw()
	keys_editing.emit()
	_commit_edit("change_interpolation_mode")


# ==============================================================================
# SEARCH / HIT TESTING
# ==============================================================================

func find_key(mouse_pos: Vector2) -> Dictionary:
	var result: Dictionary = {&"keys_index": -1, &"coord": null, &"dist": INF}
	var best_dist: float = maxf(control_close_dist, KEY_HIT_RADIUS)
	
	for keys_index: int in curves_profiles.size():
		if not _is_channel_visible(keys_index): continue
		var profile_keys: Dictionary[int, CurveKey] = keys_get(keys_index)
		for x: int in profile_keys:
			var coord := Vector2(x, profile_keys[x].value)
			var dist: float = get_display_pos_from_coord(coord).distance_to(mouse_pos)
			if dist <= best_dist:
				best_dist = dist
				result = {&"keys_index": keys_index, &"coord": coord, &"dist": dist}
	return result


func _test_control(port: int, key: int, mouse_pos: Vector2, info: Dictionary) -> bool:
	if not _is_channel_visible(port): return false
	
	var curve_profile: CurveProfile = curves_profiles[port]
	var curve_key: CurveKey = curve_profile.keys.get(key)
	if curve_key == null: return false
	if curve_key.control_mode == CurveKey.ControlMode.CONTROL_MODE_NONE: return false
	
	var key_index: int = curve_profile.keys_keys.find(key)
	var key_coord: Vector2 = Vector2(key, curve_key.value)
	var hit_radius: float = maxf(control_close_dist, CONTROL_HIT_RADIUS)
	var bezier: int = CurveKey.InterpolationMode.INTERPOLATION_MODE_BEZIER_CURVE
	
	# --- left control ---
	if key_index > 0:
		var before_key: int = curve_profile.keys_keys[key_index - 1]
		if curve_profile.keys[before_key].interpolation_mode == bezier:
			var left_coord: Vector2 = key_coord + curve_key.left_control
			var dist_to_left: float = get_display_pos_from_coord(left_coord).distance_to(mouse_pos)
			if dist_to_left <= hit_radius:
				info.curve_key	   = curve_key
				info.control_type  = 1
				info.keys_index    = port
				info.key_coord	   = key_coord
				info.coord		   = left_coord
				info.mouse_dist_to = dist_to_left
				return true
	
	# --- right control ---
	if key_index < curve_profile.keys.size() - 1 and curve_key.interpolation_mode == bezier:
		var right_coord: Vector2 = key_coord + curve_key.right_control
		var dist_to_right: float = get_display_pos_from_coord(right_coord).distance_to(mouse_pos)
		if dist_to_right <= hit_radius:
			info.curve_key	   = curve_key
			info.control_type  = 2
			info.keys_index    = port
			info.key_coord	   = key_coord
			info.coord		   = right_coord
			info.mouse_dist_to = dist_to_right
			return true
	
	return false


func find_control(mouse_pos: Vector2, disabled: bool) -> Dictionary[StringName, Variant]:
	var default_result: Dictionary[StringName, Variant] = {
		&"curve_key":	  null,
		&"control_type":  0,
		&"keys_index":	  -1,
		&"key_coord":	  Vector2.ZERO,
		&"coord":		  Vector2.ZERO,
		&"mouse_dist_to": INF
	}
	if disabled:
		return default_result
	
	var result: Dictionary[StringName, Variant] = loop_selected_vals(default_result,
		func(object: Variant, key: int, info: Dictionary[StringName, Variant]) -> bool:
			return _test_control(object, key, mouse_pos, info)
	)
	
	if result.curve_key == null and _hover_key.keys_index != -1:
		var hover_coord: Vector2 = _hover_key.coord
		_test_control(_hover_key.keys_index, int(hover_coord.x), mouse_pos, result)
	
	return result


func find_focused_keys_index(coord: Vector2, mouse_pos: Vector2) -> int:
	var best_index: int = -1
	var best_diff: float = INF
	for keys_index: int in curves_profiles.size():
		if not _is_channel_visible(keys_index): continue
		var profile: CurveProfile = curves_profiles[keys_index]
		var y1: float = profile.sample_func.call(coord.x)
		var y2: float = profile.sample_func.call(coord.x + .01)
		var y_diff: float = absf(get_display_pos_from_val(y1) - mouse_pos.y)
		var slope: float  = absf(y2 - y1) / .01
		if y_diff <= CURVE_HIT_DIST * (1.0 + slope) and y_diff < best_diff:
			best_diff = y_diff
			best_index = keys_index
	return best_index


func _reset_hover() -> void:
	_hover_key = {&"keys_index": -1, &"coord": null, &"dist": INF}
	_hover_control = {}
	is_control_focused = false
	is_cursor_focused = false
	focused_keys_index = -1


func _update_hover(mouse_pos: Vector2) -> void:
	if _motion_mode != MotionMode.NONE:
		return
	
	_hover_key = find_key(mouse_pos)
	_hover_control = find_control(mouse_pos, false)
	
	var has_control: bool = _hover_control.curve_key != null
	var has_key: bool = _hover_key.keys_index != -1
	
	if has_control and has_key and _hover_key.dist <= _hover_control.mouse_dist_to:
		has_control = false
		_hover_control = {}
	
	is_control_focused = has_control
	is_cursor_focused = draw_cursor and not has_control and not has_key \
			and absf(mouse_pos.x - get_display_pos_from_domain(cursor_pos)) <= control_drag_dist
	
	if has_control:
		focused_keys_index = _hover_control.keys_index
	elif has_key:
		focused_keys_index = _hover_key.keys_index
	else:
		focused_keys_index = find_focused_keys_index(get_coord_from_display_pos(mouse_pos), mouse_pos)


# ==============================================================================
# INPUT
# ==============================================================================

func _gui_input(event: InputEvent) -> void:
	# Clicks that start on the fit button bubble up here (its filter is PASS):
	# swallow them so they never select, drag or open the menu.
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		if event.pressed: _fit_button_press = _motion_mode == MotionMode.NONE and _is_over_fit_button()
		if _fit_button_press:
			if not event.pressed: _fit_button_press = false
			accept_event()
			return
	
	_update_view_domain()
	
	if event is InputEventMouse:
		_update_hover(event.position)
	
	super(event)
	
	if event is InputEventMouseButton:
		_on_mouse_button(event)
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event)


func _begin_motion(mode: int, mouse_pos: Vector2) -> void:
	_motion_mode = mode
	_press_pos = mouse_pos
	_press_domain = _raw_domain_at(mouse_pos.x)
	_press_value = _raw_val_at(mouse_pos.y)
	_mouse_moved = false
	_nav_offset = .0
	latest_mouse_pos = mouse_pos
	set_process(true)


func _end_motion(mouse_pos: Vector2) -> void:
	_motion_mode = MotionMode.NONE
	_nav_offset = .0
	_move_items.clear()
	_move_fixed.clear()
	_pending_click = Vector2i(-1, -1)
	set_process(false)
	_update_hover(mouse_pos)
	queue_redraw()


func _on_mouse_button(event: InputEventMouseButton) -> void:
	var mouse_pos: Vector2 = event.position
	
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			if event.pressed: _left_press(event, mouse_pos)
			else: _left_release(event, mouse_pos)
		
		MOUSE_BUTTON_RIGHT:
			if event.pressed: _right_press(event, mouse_pos)
			else: _right_release(event, mouse_pos)
		
		
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed and event.ctrl_pressed:
				zoom_value_at(5.0, mouse_pos.y)
				queue_redraw()
				accept_event()
		
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed and event.ctrl_pressed:
				zoom_value_at(-5.0, mouse_pos.y)
				queue_redraw()
				accept_event()


# ---------------------------------------------------------------- LEFT BUTTON

func _left_press(event: InputEventMouseButton, mouse_pos: Vector2) -> void:
	_pending_click = Vector2i(-1, -1)
	
	_begin_edit()
	_edit_name = "move_curve_keys"
	
	if is_control_focused:
		_edit_name = "edit_curve_handles"
		_ctrl_curve_key = _hover_control.curve_key
		_ctrl_type = _hover_control.control_type
		_ctrl_keys_index = _hover_control.keys_index
		_ctrl_key_coord = _hover_control.key_coord
		_begin_motion(MotionMode.CONTROL, mouse_pos)
		return
	
	if _hover_key.keys_index != -1:
		var hover_coord: Vector2 = _hover_key.coord
		_press_on_key(_hover_key.keys_index, int(hover_coord.x), event, mouse_pos)
		return
	
	if is_cursor_focused:
		_begin_motion(MotionMode.CURSOR, mouse_pos)
		cursor_pos = get_coord_from_display_pos(mouse_pos).x
		queue_redraw()
		return
	
	if focused_keys_index > -1:
		var coord: Vector2 = get_coord_from_display_pos(mouse_pos)
		var x: int = format_x(roundi(coord.x))
		var port: int = focused_keys_index
		
		if not keys_has(port, x):
			_edit_name = "add_curve_key"
			if linked:
				for index: int in curves_profiles.size():
					if keys_has(index, x): continue
					keys_add(index, x, CurveKey.new_curve_key(curves_profiles[index].sample(x)), true, false)
			else:
				keys_add(port, x, CurveKey.new_curve_key(curves_profiles[port].sample(x)), true, false)
		
		_press_on_key(port, x, event, mouse_pos)
		return
	


func _press_on_key(port: int, x: int, event: InputEventMouseButton, mouse_pos: Vector2) -> void:
	var was_selected: bool = is_val_selected(port, x)
	_pending_click = Vector2i(port, x)
	_pending_click_was_selected = was_selected
	
	if event.alt_pressed:
		_press_pos = mouse_pos
		_mouse_moved = false
		return
	
	if not was_selected:
		manage_val(port, x, false, not event.ctrl_pressed)
		_sync_linked_selection()
	
	_begin_motion(MotionMode.MOVE_KEYS, mouse_pos)
	_begin_move(port, x)
	queue_redraw()


func _left_release(event: InputEventMouseButton, mouse_pos: Vector2) -> void:
	var moved: bool = _mouse_moved
	var click: Vector2i = _pending_click
	var click_was_selected: bool = _pending_click_was_selected
	var mode: int = _motion_mode
	
	if mode == MotionMode.MOVE_KEYS and moved:
		keys_editing.emit()
	
	if click.x >= 0 and not moved:
		_resolve_key_click(click, click_was_selected, event)
	elif mode == MotionMode.NONE:
		_sync_linked_selection()
	
	_commit_edit(_edit_name)
	
	_end_motion(mouse_pos)


func _resolve_key_click(click: Vector2i, was_selected: bool, event: InputEventMouseButton) -> void:
	var port: int = click.x
	var x: int = click.y
	
	if event.alt_pressed or (event.ctrl_pressed and was_selected):
		manage_val(port, x, true, false)
		if linked: _deselect_column(x)
	elif was_selected:
		manage_val(port, x, false, not event.ctrl_pressed)
	
	_sync_linked_selection()
	queue_redraw()


# --------------------------------------------------------------- RIGHT BUTTON

func _right_press(_event: InputEventMouseButton, mouse_pos: Vector2) -> void:
	if is_control_focused:
		_begin_edit()
		curve_key_move_control_mode(_hover_control.keys_index, int(_hover_control.key_coord.x))
		_commit_edit("change_control_mode")
		queue_redraw()
		return
	
	if _hover_key.keys_index != -1:
		var hover_coord: Vector2 = _hover_key.coord
		var port: int = _hover_key.keys_index
		var x: int = int(hover_coord.x)
		if not is_val_selected(port, x):
			manage_val(port, x, false, true)
			_sync_linked_selection()
	
	_begin_motion(MotionMode.PAN, mouse_pos)


func _right_release(_event: InputEventMouseButton, mouse_pos: Vector2) -> void:
	var was_click: bool = _motion_mode == MotionMode.PAN and not _mouse_moved
	_end_motion(mouse_pos)
	if was_click:
		popup_options_menu()


# --------------------------------------------------------------------- MOTION

func _on_mouse_motion(event: InputEventMouseMotion) -> void:
	var mouse_pos: Vector2 = event.position
	var coord: Vector2 = get_coord_from_display_pos(mouse_pos)
	
	if _motion_mode != MotionMode.NONE and mouse_pos.distance_to(_press_pos) > MOVE_THRESHOLD:
		_mouse_moved = true
	
	match _motion_mode:
		MotionMode.CURSOR:
			cursor_pos = coord.x
		MotionMode.CONTROL:
			_motion_control(coord, mouse_pos)
		MotionMode.MOVE_KEYS:
			if _mouse_moved:
				_update_move(mouse_pos)
		MotionMode.PAN:
			navigate_value(-event.relative.y / (size.y / (max_val - min_val)))
	
	queue_redraw()
	_update_drawable_cursor(mouse_pos, coord)


func _motion_control(coord: Vector2, mouse_pos: Vector2) -> void:
	if _ctrl_curve_key == null: return
	
	var control_target_coord: Vector2 = coord - _ctrl_key_coord
	
	if _ctrl_curve_key.control_mode == CurveKey.ControlMode.CONTROL_MODE_VECTOR:
		update_navigation_offset(mouse_pos)
		curves_profiles[_ctrl_keys_index].update_profile()
		return
	
	var set_control_func: Callable
	if _ctrl_type == 1:
		set_control_func = func(ck: CurveKey, new_val: Vector2) -> void: ck.set_left_control(new_val)
	else:
		set_control_func = func(ck: CurveKey, new_val: Vector2) -> void: ck.set_right_control(new_val)
	
	set_control_func.call(_ctrl_curve_key, control_target_coord)
	
	if EditorServer.time_line2.is_edit_multiple():
		loop_selected_vals({},
			func(port_idx: int, idx: int, _info: Dictionary[StringName, Variant]) -> void:
				var curr_curve_key: CurveKey = keys_get(port_idx)[idx]
				if curr_curve_key.interpolation_mode == CurveKey.InterpolationMode.INTERPOLATION_MODE_BEZIER_CURVE:
					set_control_func.call(curr_curve_key, control_target_coord)
		)
	
	update_navigation_offset(mouse_pos)
	curves_profiles[_ctrl_keys_index].update_profile()
	keys_editing.emit()


# ------------------------------------------------------------------ KEY MOVE

func _begin_move(grab_port: int, grab_x: int) -> void:
	_move_items.clear()
	_move_fixed.clear()
	_move_min_x = 1 << 30
	_move_max_x = -(1 << 30)
	
	for port: int in selected:
		var port_keys: Dictionary[int, CurveKey] = keys_get(port)
		for x: int in selected[port]:
			var curve_key: CurveKey = port_keys.get(x)
			if curve_key == null: continue
			_move_items.append({&"port": port, &"x0": x, &"x": x, &"ck": curve_key, &"v0": curve_key.value})
			_move_min_x = mini(_move_min_x, x)
			_move_max_x = maxi(_move_max_x, x)
	
	for port: int in curves_profiles.size():
		var fixed: Dictionary = {}
		for x: int in keys_get(port):
			if not (selected.has(port) and selected[port].has(x)):
				fixed[x] = true
		_move_fixed[port] = fixed
	
	var grab_key: CurveKey = keys_get(grab_port).get(grab_x)
	_move_grab_port = grab_port
	_move_grab_x0 = grab_x
	_move_grab_v0 = grab_key.value if grab_key else .0
	_move_last_dx = 0
	_move_last_dy = .0


func _update_move(mouse_pos: Vector2) -> void:
	if _move_items.is_empty(): return
	
	var raw_dx: float = _raw_domain_at(mouse_pos.x) - _press_domain
	var raw_dy: float = _raw_val_at(mouse_pos.y) - _press_value
	
	if Input.is_key_pressed(KEY_SHIFT):
		var dd: Vector2 = mouse_pos - _press_pos
		if absf(dd.x) >= absf(dd.y): raw_dy = .0
		else: raw_dx = .0
	
	var target_x: float = _move_grab_x0 + raw_dx
	var target_y: float = _move_grab_v0 + raw_dy
	if is_snapped:
		target_x = snappedf(target_x, draw_step.x)
		target_y = snappedf(target_y, draw_step.y)
	else:
		target_y = snappedf(target_y, val_step)
	
	var dx: int = roundi(target_x) - _move_grab_x0
	dx = clampi(dx, ceili(min_domain) - _move_min_x, floori(max_domain) - _move_max_x)
	var dy: float = target_y - _move_grab_v0
	
	update_navigation_offset(mouse_pos)
	
	if dx == _move_last_dx and is_equal_approx(dy, _move_last_dy):
		return
	
	for item: Dictionary in _move_items:
		if _move_fixed[item.port].has(item.x0 + dx):
			return
	
	_move_last_dx = dx
	_move_last_dy = dy
	
	for item: Dictionary in _move_items:
		var port: int = item.port
		var cur: int = item.x
		deselect_val(port, cur)
		delete_selectable_val(port, cur)
		keys_get(port).erase(cur)
	
	var affected: Dictionary = {}
	for item: Dictionary in _move_items:
		var port: int = item.port
		var new_x: int = item.x0 + dx
		var curve_key: CurveKey = item.ck
		
		if not linked or port == _move_grab_port:
			curve_key.value = item.v0 + dy
		
		keys_get(port)[new_x] = curve_key
		add_selectable_val(port, new_x, curve_key)
		select_val(port, new_x)
		item.x = new_x
		affected[port] = true
	
	for port: int in affected:
		curves_profiles[port].update_profile()
	
	keys_editing.emit()
	queue_redraw()


# ------------------------------------------------------------ DRAWABLE CURSOR

func _update_drawable_cursor(mouse_pos: Vector2, mouse_coord: Vector2) -> void:
	var drawable_rect: DrawableRect = EditorServer.drawable_rect
	if not is_instance_valid(drawable_rect): return
	
	var coord: Vector2 = mouse_coord
	var highlighted: bool = false
	if _motion_mode == MotionMode.NONE:
		if is_control_focused:
			coord = _hover_control.coord
			highlighted = true
		elif _hover_key.keys_index != -1:
			coord = _hover_key.coord
			highlighted = true
	
	var target_global_mouse_pos: Vector2 = get_display_pos_from_coord(coord) + (self.global_position - drawable_rect.global_position)
	var target_color: Color = Color.WHITE if highlighted else Color(Color.WHITE, .5)
	drawable_rect.draw_new_cursor(target_global_mouse_pos, target_color)
	drawable_rect.draw_new_string(font, Vector2(20., -10.) + target_global_mouse_pos, str(coord), 0, CURSOR_FONT_SIZE, target_color)


# ==============================================================================
# CONTEXT MENU
# ==============================================================================

func _get_menu_options() -> Array[Dictionary]:
	
	var control_mode_menu: PopupMenu = IS.create_popup_menu([
		{text = "Free"},
		{text = "Aligned"},
		{text = "Vector"},
		{text = "Zero"},
	])
	var interpolation_option_menu: PopupMenu = IS.create_popup_menu([
		{text = "Constant"},
		{text = "Linear"},
		{text = "Bezier"},
		{text = "Ease in"},
		{text = "Ease out"},
		{text = "Ease in out"},
		{text = "Expo in out"},
		{text = "Circ in out"},
		{text = "Cubic"},
		{text = "Quart"},
		{text = "Quint"},
		{text = "Elastic"},
		{text = "Bounce"}
	])
	control_mode_menu.id_pressed.connect(set_keys_control_mode)
	interpolation_option_menu.id_pressed.connect(set_keys_transition_mode)
	
	var show_link_item: bool = curves_profiles.size() > 1 and (linked or _selected_count() > 1)
	
	var options: Array[Dictionary] = [
		{text = "Control Mode", submenu = control_mode_menu},
		{text = "Interpolation Option", submenu = interpolation_option_menu},
	]
	
	if show_link_item:
		var curves_menu: PopupMenu = IS.create_popup_menu([
			{text = "Unlink Curves" if linked else "Link Curves"},
		])
		curves_menu.id_pressed.connect(func(_id: int) -> void: toggle_linked())
		options.append({text = "Curves", submenu = curves_menu})
	
	options.append({text = "Fit View to Curve", icon = fit_view_texture, metadata = frame_all})
	options.append({as_separator = true})
	
	return options + super()


func _request_selection_box_select(port_idx: int, _port_object: Object, idx: int) -> bool:
	var curve_key: CurveKey = keys_get(port_idx).get(idx)
	if curve_key == null:
		return false
	if not _is_channel_visible(port_idx):
		return false
	return selectbox_rect.has_point(get_display_pos_from_coord(Vector2(idx, curve_key.value)))


func _request_box_selection() -> bool:
	return _motion_mode == MotionMode.NONE \
			and focused_keys_index == -1 and not is_cursor_focused and not is_control_focused


# ==============================================================================
# DRAW
# ==============================================================================

func _draw() -> void:
	_update_view_domain()
	_draw_grid()
	_draw_out_of_domain()
	_draw_linked_columns()
	_draw_curves()
	if draw_cursor:
		_draw_cursor_line()


func _draw_out_of_domain() -> void:
	var left: float = get_display_pos_from_domain(min_domain)
	var right: float = get_display_pos_from_domain(max_domain)
	if left > .0:
		_draw_hatch(Rect2(.0, .0, minf(left, size.x), size.y))
	if right < size.x:
		var from: float = maxf(right, .0)
		_draw_hatch(Rect2(from, .0, size.x - from, size.y))


func _draw_hatch(rect: Rect2) -> void:
	if rect.size.x <= .0: return
	draw_rect(rect, Color(.0, .0, .0, .35))
	
	var color := Color(Color.WHITE, .05)
	var h: float = rect.size.y
	var x0: float = rect.position.x
	var x1: float = rect.end.x
	var s: float = floorf((x0 - h) / HATCH_SPACING) * HATCH_SPACING
	while s < x1:
		# Diagonal from (s, bottom) to (s + h, top), clipped to [x0, x1].
		var t0: float = maxf(.0, x0 - s)
		var t1: float = minf(h, x1 - s)
		if t1 > t0:
			draw_line(Vector2(s + t0, rect.end.y - t0), Vector2(s + t1, rect.end.y - t1), color)
		s += HATCH_SPACING


func _draw_grid() -> void:
	var val_size: float = max_val - min_val
	var domain_size: float = view_max_domain - view_min_domain
	
	var y_offset: float = min_val - float(int(min_val) % draw_val_step)
	var y_displacement: float = y_offset - int(y_offset)
	
	if is_snapped:
		var snap_grid_color := Color(Color.WHITE, .1)
		var x_snap_start: float = floorf(view_min_domain / draw_step.x) * draw_step.x
		var x_snap_steps_count: int = domain_size / draw_step.x + 2
		for snap_step: int in x_snap_steps_count:
			var x_pos := get_display_pos_from_domain(x_snap_start + snap_step * draw_step.x)
			draw_line(Vector2(x_pos, .0), Vector2(x_pos, size.y), snap_grid_color)
		for snap_step: int in range(-50, val_size / draw_step.y + 50):
			var y_pos := get_display_pos_from_val(y_offset + snap_step * draw_step.y - y_displacement)
			draw_line(Vector2(.0, y_pos), Vector2(size.x, y_pos), snap_grid_color)
	
	var grid_color		:= Color(Color.WHITE, .2)
	var val_steps_count: int = val_size / draw_val_step + 2
	for step: int in val_steps_count:
		var val:   float = y_offset + step * draw_val_step - y_displacement
		var y_pos: float = get_display_pos_from_val(val)
		draw_line(Vector2(.0, y_pos), Vector2(size.x, y_pos), grid_color, 2.0)
		draw_string(font, Vector2(.0, y_pos) + Vector2(10., .0), str(val))


func set_keys_colors(colors: Array[Color]) -> void:
	_keys_colors = colors


func _draw_linked_columns() -> void:
	if not linked: return
	var xs: Dictionary = {}
	for port: int in selected:
		for x: int in selected[port]:
			xs[x] = true
	var color := Color(draw_select_color, .25)
	for x: int in xs:
		var x_pos: float = get_display_pos_from_domain(x)
		draw_line(Vector2(x_pos, .0), Vector2(x_pos, size.y), color, 2.0)


func _draw_curves() -> void:
	var count: int = curves_profiles.size()
	
	var order: Array[int] = []
	for index: int in count:
		if index != focused_keys_index: order.append(index)
	if focused_keys_index > -1 and focused_keys_index < count:
		order.append(focused_keys_index)
	
	for keys_index: int in order:
		if not _is_channel_visible(keys_index): continue
		
		var profile: CurveProfile = curves_profiles[keys_index]
		var color_alpha: float = 1.0 if (not is_cursor_focused and (keys_index == focused_keys_index or count == 1)) else .5
		var keys_color: Color = Color(_get_channel_color(keys_index), color_alpha)
		
		_draw_curve_line(profile, keys_color)
		_draw_curve_keys(profile, keys_index, color_alpha)


func _draw_curve_line(profile: CurveProfile, keys_color: Color) -> void:
	var keys: Dictionary[int, CurveKey] = profile.keys
	var keys_keys: Array = profile.keys_keys
	var count: int = keys.size()
	
	if count == 0:
		var y0: float = get_display_pos_from_val(0)
		draw_line(Vector2(.0, y0), Vector2(size.x, y0), keys_color, 2.0)
		return
	
	var pixels_per_frame: float = size.x / maxf(view_max_domain - view_min_domain, 1.)
	var step: int = maxi(1, ceili(2.0 / maxf(pixels_per_frame, .001)))
	
	var points := PackedVector2Array()
	var first_pos: Vector2 = get_display_pos_from_coord(Vector2(keys_keys[0], keys[keys_keys[0]].value))
	points.append(Vector2(.0, first_pos.y))
	
	for index: int in range(0, count - 1):
		var key_a: int = keys_keys[index]
		var key_b: int = keys_keys[index + 1]
		var curve_key: CurveKey = keys[key_a]
		var pos_a: Vector2 = get_display_pos_from_coord(Vector2(key_a, curve_key.value))
		var pos_b: Vector2 = get_display_pos_from_coord(Vector2(key_b, keys[key_b].value))
		
		points.append(pos_a)
		match curve_key.interpolation_mode:
			CurveKey.InterpolationMode.INTERPOLATION_MODE_CONSTANT:
				points.append(Vector2(pos_b.x, pos_a.y))
			CurveKey.InterpolationMode.INTERPOLATION_MODE_LINEAR:
				pass
			_:
				for offset: int in range(step, key_b - key_a, step):
					var new_x: float = key_a + offset
					points.append(get_display_pos_from_coord(Vector2(new_x, profile.sample_func.call(new_x))))
	
	var last_pos: Vector2 = get_display_pos_from_coord(Vector2(keys_keys[count - 1], keys[keys_keys[count - 1]].value))
	points.append(last_pos)
	points.append(Vector2(size.x, last_pos.y))
	
	draw_polyline(points, keys_color, 2.0, true)


func _draw_curve_keys(profile: CurveProfile, keys_index: int, color_alpha: float) -> void:
	var keys: Dictionary[int, CurveKey] = profile.keys
	var keys_keys: Array = profile.keys_keys
	var count: int = keys.size()
	var bezier: int = CurveKey.InterpolationMode.INTERPOLATION_MODE_BEZIER_CURVE
	
	var hover_x: int = -1
	if _hover_key.keys_index == keys_index and _hover_key.coord != null:
		var hover_coord: Vector2 = _hover_key.coord
		hover_x = int(hover_coord.x)
	
	for index: int in count:
		var x: int = keys_keys[index]
		var curve_key: CurveKey = keys[x]
		var coord := Vector2(x, curve_key.value)
		
		var left_control: bool = index > 0 and keys[keys_keys[index - 1]].interpolation_mode == bezier
		var right_control: bool = index < count - 1 and curve_key.interpolation_mode == bezier
		
		_draw_key(
			coord, curve_key, left_control, right_control,
			get_display_pos_from_coord(coord),
			is_val_selected(keys_index, x),
			x == hover_x and _motion_mode == MotionMode.NONE,
			color_alpha
		)


func _draw_cursor_line() -> void:
	var cursor_display_pos: float = get_display_pos_from_domain(cursor_pos)
	var cursor_color: Color = Color(Color.WHITE, 1.0 if is_cursor_focused else .6)
	draw_line(Vector2(cursor_display_pos, .0), Vector2(cursor_display_pos, size.y), cursor_color, 3)


func _draw_key(
	coord: Vector2,
	curve_key: CurveKey,
	left_control: bool,
	right_control: bool,
	display_pos: Vector2,
	is_selected: bool  = false,
	is_hovered: bool = false,
	color_alpha: float = 1.
) -> void:
	var grow: Vector2 = Vector2(5., 5.) if is_hovered else Vector2.ZERO
	var rect: Rect2 = Rect2(display_pos - KEY_SIZE_HALF - grow * .5, KEY_SIZE + grow)
	var color: Color
	
	if is_selected or is_hovered:
		color = draw_select_color if is_selected else Color(Color.WHITE, 1.)
		var handle_alpha: float = color_alpha if is_selected else color_alpha * .7
		var control_color := Color(Color.WHITE, handle_alpha)
		
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
			var padlock_color:	 Color
			if curve_key.control_mode in [2, 3]:
				padlock_texture = lock_texture
				padlock_color	= Color.PURPLE
			else:
				padlock_texture = unlock_texture
				padlock_color	= Color.SPRING_GREEN
			padlock_color = Color(padlock_color, handle_alpha)
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
	if _motion_mode == MotionMode.NONE:
		_reset_hover()
	EditorServer.drawable_rect.clear_drawn_entities()
	EditorServer.graph_editors_focused.erase(self)
	queue_redraw()


func _on_profile_key_added(x: int, curve_key: CurveKey, profile_index: int) -> void:
	add_selectable_val(profile_index, x, curve_key)
	queue_redraw()


func _on_profile_key_removed(x: int, profile_index: int) -> void:
	delete_selectable_val(profile_index, x)
	queue_redraw()
