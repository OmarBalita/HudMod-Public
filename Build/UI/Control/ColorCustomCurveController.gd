class_name ColorCustomCurveController extends VBoxContainer

@export_group("Textures")
@export var locked_icon: Texture2D = preload("res://Asset/Icons/link.png")
@export var unlocked_icon: Texture2D = preload("res://Asset/Icons/unlink.png")
@export var reset_icon: Texture2D = preload("res://Asset/Icons/reset.png")

enum HistogramState { OFF, OUTPUT, INPUT }

var top_bar: HBoxContainer
var curve_ctrlr: ColorCurveController

var channel_buttons: Array[Button]
var lock_button: IS.CustomTextureButton
var histogram_opts: MenuButton = null

var is_locked: bool = false

var bound_clip_res: MediaClipRes = null

var histogram_state: HistogramState = HistogramState.OUTPUT

var color_scope_editor: ColorScopeEditor

func _init() -> void:
	top_bar = HBoxContainer.new()
	IS.set_base_container_settings(top_bar)
	top_bar.add_theme_constant_override(&"separation", 6)

	curve_ctrlr = ColorCurveController.new_look_curve()
	IS.expand(curve_ctrlr, true, true)
	curve_ctrlr.resized.connect(curve_ctrlr.queue_redraw)

	lock_button = IS.create_texture_button(
		unlocked_icon,
		unlocked_icon,
		unlocked_icon,
		"Lock channels together",
		true,
		{custom_minimum_size = Vector2(20.0, 20.0)}
	)
	lock_button.toggled.connect(_on_lock_toggled)

	var channels_hbox: HBoxContainer = HBoxContainer.new()
	channels_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	channels_hbox.add_theme_constant_override(&"separation", 2)

	var r_btn: Button = IS.create_button("R", null, "", false, true, false, {toggle_mode = true, custom_minimum_size = Vector2(20., .0)})
	var g_btn: Button = IS.create_button("G", null, "", false, true, false, {toggle_mode = true, custom_minimum_size = Vector2(20., .0)})
	var b_btn: Button = IS.create_button("B", null, "", false, true, false, {toggle_mode = true, custom_minimum_size = Vector2(20., .0)})
	var lum_btn: Button = IS.create_button("Lum", null, "", false, true, false, {toggle_mode = true, custom_minimum_size = Vector2(20., .0)})
	r_btn.toggled.connect(func(_pressed: bool) -> void: curve_ctrlr.change_channel_visibility(1))
	g_btn.toggled.connect(func(_pressed: bool) -> void: curve_ctrlr.change_channel_visibility(2))
	b_btn.toggled.connect(func(_pressed: bool) -> void: curve_ctrlr.change_channel_visibility(3))
	lum_btn.toggled.connect(func(_pressed: bool) -> void: curve_ctrlr.change_channel_visibility(0))
	IS.add_children(channels_hbox, [r_btn, g_btn, b_btn, lum_btn])

	histogram_opts = IS.create_menu_button("histogram", [
		{text = "Off"},
		{text = "Output"},
		{text = "Input"}
	])
	histogram_opts.text = "Histogram: " + HistogramState.find_key(histogram_state).capitalize()
	histogram_opts.get_popup().id_pressed.connect(_on_histogram_mode_selected)

	var reset_button = IS.create_texture_button(reset_icon)
	reset_button.pressed.connect(_on_reset_pressed)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var top_bar_margin: MarginContainer = IS.create_margin_container(4, 4, 4, 4)
	top_bar_margin.add_child(top_bar)

	IS.add_children(top_bar, [lock_button, IS.create_v_line_panel(2), channels_hbox, spacer, histogram_opts, reset_button])
	IS.add_children(self, [top_bar_margin, curve_ctrlr])

func _ready():
	color_scope_editor = EditorServer.color_scope_editor


func set_histogram_data(data: PackedVector4Array) -> void:
	curve_ctrlr.histogram_data = data
	curve_ctrlr.queue_redraw()

func get_curves_profiles() -> Array[CurveProfile]:
	return curve_ctrlr.curves_profiles

func bind_to_clip(clip_res: MediaClipRes) -> void:
	unbind_clip()

	bound_clip_res = clip_res
	if bound_clip_res:
		# PlaybackServer.position_changed.connect(_on_playback_position_changed)
		call_deferred(&"_request_histogram")

	if not tree_exited.is_connected(_on_tree_exited):
		tree_exited.connect(_on_tree_exited)

func unbind_clip() -> void:
	# PlaybackServer.position_changed.disconnect(_on_playback_position_changed)
	bound_clip_res = null

func _request_histogram() -> void:
	if not color_scope_editor or histogram_state == HistogramState.OFF:
		return
	
	if not color_scope_editor.calculation_finished.is_connected(_on_color_scope_editor_calculation_finished):
		color_scope_editor.calculation_finished.connect(_on_color_scope_editor_calculation_finished, CONNECT_ONE_SHOT)

	color_scope_editor.request_calculate(histogram_state == HistogramState.OUTPUT)

func _use_histogram_data() -> void:
	var histogram_sub_editor: ColorScopeEditor.ColorScopeSubEditor = \
		color_scope_editor.color_scope_sub_editors.get(&"histogram")
	if not histogram_sub_editor or not histogram_sub_editor.color_scope_viewer:
		return

	var histogram_viewer: ColorScopeEditor.HistogramViewer = histogram_sub_editor.color_scope_viewer
	set_histogram_data(histogram_viewer.histogram_data)

func _update_lock_icon() -> void:
	var target_icon: Texture2D = locked_icon if is_locked else unlocked_icon

	lock_button.texture_normal = target_icon
	lock_button.texture_hover = target_icon
	lock_button.texture_pressed = target_icon

func _merge_curves_profiles(profiles: Array[CurveProfile]) -> void:
	if profiles.size() < 2:
		return

	var master_keys: Dictionary[int, CurveKey] = profiles[0].keys

	for port_idx: int in range(1, profiles.size()):
		var old_keys: Dictionary[int, CurveKey] = profiles[port_idx].keys
		for x: int in old_keys:
			curve_ctrlr.delete_selectable_val(port_idx, x)

		profiles[port_idx].keys = master_keys

		for x: int in master_keys:
			curve_ctrlr.add_selectable_val(port_idx, x, master_keys[x])

	curve_ctrlr.update_curve_profiles_keys()

func _unmerge_curves_profiles(profiles: Array[CurveProfile]) -> void:
	if profiles.size() < 2:
		return

	var master_profile: CurveProfile = profiles[0]

	for port_idx: int in range(1, profiles.size()):
		var old_keys: Dictionary[int, CurveKey] = profiles[port_idx].keys
		for x: int in old_keys:
			curve_ctrlr.delete_selectable_val(port_idx, x)

		var independent_keys: Dictionary[int, CurveKey] = master_profile.duplicate_keys()
		profiles[port_idx].keys = independent_keys

		for x: int in independent_keys:
			curve_ctrlr.add_selectable_val(port_idx, x, independent_keys[x])

	curve_ctrlr.update_curve_profiles_keys()


func _on_lock_toggled(toggled_on: bool) -> void:
	is_locked = toggled_on
	_update_lock_icon()

	curve_ctrlr.selected.clear()
	curve_ctrlr.focused_keys_index = -1
	curve_ctrlr.is_locked = is_locked

	if is_locked:
		_merge_curves_profiles(curve_ctrlr.curves_profiles)
	else:
		_unmerge_curves_profiles(curve_ctrlr.curves_profiles)

	curve_ctrlr.queue_redraw()

func _on_reset_pressed() -> void:
	var linear: CurveProfile = CurveProfile.preset_linear(.0, 1.0, .001, .0, 255.0, 1.0)

	if is_locked:
		var shared_keys: Dictionary[int, CurveKey] = linear.duplicate_keys()
		for profile: CurveProfile in curve_ctrlr.curves_profiles:
			profile.keys = shared_keys
	else:
		for profile: CurveProfile in curve_ctrlr.curves_profiles:
			profile.keys = linear.duplicate_keys()

	curve_ctrlr.queue_redraw()

func _on_playback_position_changed(_position: int) -> void:
	_request_histogram()

func _on_color_scope_editor_calculation_finished() -> void:
	_use_histogram_data()
	if histogram_state == HistogramState.OUTPUT:
		_request_histogram()

func _on_histogram_mode_selected(id: int) -> void:
	histogram_state = id as HistogramState
	histogram_opts.text = "Histogram: " + HistogramState.keys()[id].capitalize()

	match histogram_state:
		HistogramState.OFF:
			curve_ctrlr.draw_histogram = false
			set_histogram_data(PackedVector4Array())
		HistogramState.OUTPUT:
			curve_ctrlr.draw_histogram = true
			_request_histogram()
		HistogramState.INPUT:
			curve_ctrlr.draw_histogram = true
			_request_histogram()

func _on_tree_exited() -> void:
	unbind_clip()


class ColorCurveController extends CurveController:
	var histogram_data: PackedVector4Array
	var is_locked: bool = false
	var draw_histogram: bool = true
	var target_cell_size: float = 20.0

	func _init() -> void:
		super()
		min_val = .0
		max_val = 1.0
		val_step = .001
		min_domain = .0
		max_domain = 255.0
		domain_step = 1.0

		set_keys_colors([Color.WHITE, Color.RED, Color.GREEN, Color.CORNFLOWER_BLUE])

	static func new_look_curve() -> ColorCurveController:
		var ctrlr:= ColorCurveController.new()
		ctrlr.curves_profiles = [
			CurveProfile.preset_linear(.0, 1.0, .001, .0, 255.0, 1.0), # Luminance
			CurveProfile.preset_linear(.0, 1.0, .001, .0, 255.0, 1.0), # Red
			CurveProfile.preset_linear(.0, 1.0, .001, .0, 255.0, 1.0), # Green
			CurveProfile.preset_linear(.0, 1.0, .001, .0, 255.0, 1.0), # Blue
		]
		return ctrlr

	func navigate_value(_offset: float) -> void:
		pass

	func zoom_value(_scale: float) -> void:
		pass

	func update_navigation_offset(_mouse_pos: Vector2) -> void:
		set_meta(&"navigation_offset", .0)

	func get_val_from_display_pos(pos: float) -> float:
		return clamp(snappedf(min_val + pos * (max_val - min_val) / size.y, val_step), min_val, max_val)

	func _draw() -> void:
		if draw_histogram: _draw_histogram_background()
		super()

	func _draw_grid() -> void:
		var grid_color := Color(Color.WHITE, .15)
		var text_color := Color(Color.WHITE, .5)

		var val_divisions: int = max(1, roundi(size.y / target_cell_size))
		var domain_divisions: int = max(1, roundi(size.x / target_cell_size))

		for i: int in val_divisions + 1:
			var t: float = float(i) / float(val_divisions)
			var val: float = min_val + t * (max_val - min_val)
			var y_pos: float = get_display_pos_from_val(val)

			draw_line(Vector2(.0, y_pos), Vector2(size.x, y_pos), grid_color, 1.0)

		for i: int in domain_divisions + 1:
			var t: float = float(i) / float(domain_divisions)
			var dom: float = min_domain + t * (max_domain - min_domain)
			var x_pos: float = get_display_pos_from_domain(dom)

			draw_line(Vector2(x_pos, .0), Vector2(x_pos, size.y), grid_color, 1.0)

	func _draw_histogram_background() -> void:
		if histogram_data.is_empty():
			return

		var bins: int = histogram_data.size()

		var max_count: float = .0
		for bin_idx: int in bins:
			var v: Vector4 = histogram_data[bin_idx]
			max_count = max(max_count, v.x, v.y, v.z, v.w)

		if max_count <= .0:
			return

		var channels: Array[Dictionary] = [
			{color = Color(1., 1., 1., .35), comp = func(v: Vector4) -> float: return v.x},
			{color = Color(1., .2, .2, .35), comp = func(v: Vector4) -> float: return v.y},
			{color = Color(.2, 1., .2, .35), comp = func(v: Vector4) -> float: return v.z},
			{color = Color(.3, .5, 1., .35), comp = func(v: Vector4) -> float: return v.w},
		]

		for channel_index: int in channels.size():
			if not keys_info[channel_index].v:
				continue

			var channel: Dictionary = channels[channel_index]
			var comp_func: Callable = channel.comp

			var points: PackedVector2Array
			points.append(Vector2(.0, size.y))

			for bin_idx: int in bins:
				var value: float = comp_func.call(histogram_data[bin_idx]) / max_count
				var x_pos: float = get_display_pos_from_domain(float(bin_idx) / float(bins - 1) * max_domain)
				var y_pos: float = size.y - clamp(value, .0, 1.0) * size.y
				points.append(Vector2(x_pos, y_pos))

			points.append(Vector2(size.x, size.y))

			draw_colored_polygon(points, channel.color)
			draw_polyline(points, Color(channel.color, .8), 1.5)

	func keys_add(keys_index: int, x: int, curve_key: CurveKey, sort_keys: bool, redraw: bool = true) -> void:
		super(keys_index, x, curve_key, sort_keys, redraw)

		if is_locked and sort_keys:
			for port_idx: int in curves_profiles.size():
				if port_idx == keys_index:
					continue
				add_selectable_val(port_idx, x, curve_key)
			update_curve_profiles_keys()
			if redraw:
				queue_redraw()

	func keys_delete(keys_index: int, x: int, deselect_key: bool, sort_keys: bool = false, redraw: bool = true) -> void:
		super(keys_index, x, deselect_key, sort_keys, redraw)

		if is_locked and sort_keys:
			for port_idx: int in curves_profiles.size():
				if port_idx == keys_index:
					continue
				delete_selectable_val(port_idx, x)
				if deselect_key:
					deselect_val(port_idx, x)
			update_curve_profiles_keys()
			if redraw:
				queue_redraw()
