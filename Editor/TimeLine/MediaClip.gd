class_name MediaClip extends FocusControl

const STYLE_SELECT: StyleBoxFlat = preload("uid://bdikx7yabbrki")
const STYLE_FOCUS: StyleBoxFlat = preload("uid://kkroptu2c0c1")
const STYLE_BUTTONS_SELECT: StyleBoxFlat = preload("uid://bb4m7kvycelsj")
const STYLE_BUTTONS_FOCUS: StyleBoxFlat = preload("uid://yvx6gwfm0v3b")
const STYLE_ROLL_BUTTON: StyleBoxFlat = preload("res://UI&UX/MediaStyle/RollButtonStyle.tres")

# Main Variables
@export var layer_index: int
@export var clip_pos: int
@export var clip_res: MediaClipRes

# RealTime Variables
var is_editing: bool
var edit_clip_pos: int
var edit_from: int
var edit_length: int

var buttons_mouse_entered: bool

var input_mouse_motion_func: Callable


# RealTime Nodes
var layer: Layer
var clip_panel: MediaServer.ClipPanel:
	set(val):
		if clip_panel:
			clip_panel.queue_free()
		if val:
			val.set_name("clip_panel")
			add_child(val)
		clip_panel = val

var focus_panel: FocusPanelContainer

var r_expand_button: Button
var l_expand_button: Button
var r_roll_button: RollButton:
	set(val):
		if val:
			val.button_down.connect(on_r_roll_button_drag_changed.bind(true))
			val.button_up.connect(on_r_roll_button_drag_changed.bind(false))
		r_roll_button = val
var l_roll_button: RollButton:
	set(val):
		if val:
			val.button_down.connect(on_l_roll_button_drag_changed.bind(true))
			val.button_up.connect(on_l_roll_button_drag_changed.bind(false))
		l_roll_button = val

class FocusPanelContainer extends PanelContainer:
	
	static var key_size: Vector2 = Vector2(24., 24.):
		set(val):
			key_size = val
			key_size_half = key_size / 2.
	static var key_size_half: Vector2 = key_size / 2.
	static var texture_keyframe: Texture2D = preload("res://Asset/Icons/keyframe.png")
	
	@export var owner_as_media_clip: MediaClip
	
	var displayed_keys: Array[int]
	
	func _init(_owner_as_media_clip: MediaClip) -> void:
		owner_as_media_clip = _owner_as_media_clip
		owner_as_media_clip.clip_res.comp_keyframe_added.connect(_on_clip_res_comp_keyframe_added)
		owner_as_media_clip.clip_res.comp_keyframe_removed.connect(_on_clip_res_comp_keyframe_removed)
	
	func _ready() -> void:
		IS.set_base_panel_settings(self, STYLE_SELECT)
		update_displayed_keys(false)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	func _draw() -> void:
		
		var size_half: Vector2 = owner_as_media_clip.clip_panel.box_container.get_child(0).size / 2.0
		
		var media_res: MediaClipRes = owner_as_media_clip.clip_res
		
		var from: int
		var length: int
		if owner_as_media_clip.is_editing:
			from = owner_as_media_clip.edit_from
			length = owner_as_media_clip.edit_length
		else:
			from = media_res.from
			length = media_res.length
		
		for key_pos: int in displayed_keys:
			var key_display_pos: float = (key_pos - from) / float(length) * size.x
			var key_rect_pos:= Vector2(key_display_pos, size_half.y + 8) - key_size_half
			var key_rect: Rect2 = Rect2(key_rect_pos, key_size)
			
			draw_texture_rect(texture_keyframe, key_rect, false)
			#draw_rect(key_rect, Color.WHITE)
			#draw_rect(key_rect, Color.BLACK, false, 2.0)
	
	func get_displayed_keys() -> Array[int]:
		return displayed_keys
	
	func update_displayed_keys(update_project_sapacial_frames: bool) -> void:
		displayed_keys = owner_as_media_clip.clip_res.loop_components_animations_keys({&"displayed_keys": [] as Array[int]},
			func(anim_key: String, key_pos: float, key_val: Variant, info: Dictionary[StringName, Variant]) -> void:
				var key_pos_int: int = int(key_pos)
				if not info.displayed_keys.has(key_pos_int):
					info.displayed_keys.append(key_pos_int)
		).displayed_keys
		queue_redraw()
		if update_project_sapacial_frames:
			ProjectServer.update_curr_length_and_curr_spacial_frames()
	
	func _on_clip_res_comp_keyframe_added(comp: ComponentRes, usable_res: UsableRes, prop_key: StringName, prop_val: Variant, frame: int) -> void: update_displayed_keys(true)
	func _on_clip_res_comp_keyframe_removed(comp: ComponentRes, usable_res: UsableRes, prop_key: StringName, frame: int) -> void: update_displayed_keys(true)

class RollButton extends Button:
	
	func is_mouse_enter() -> bool:
		return get_global_rect().has_point(get_global_mouse_position())
	
	func spawn_roll_button(parent: Node) -> void:
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon = load("res://Asset/Icons/horizontal-alignment.png")
		parent.add_child(self)
		EditorServer.roll_buttons_spawned.append(self)
		
		set_pivot_offset(size / 2.0)
		IS.set_button_style(self, STYLE_ROLL_BUTTON, STYLE_ROLL_BUTTON, STYLE_ROLL_BUTTON)
		add_theme_stylebox_override(&"disabled", STYLE_ROLL_BUTTON)
		var tweener: TweenerComponent = get_tree().get_first_node_in_group(&"tweener")
		tweener.play(self, "scale", [Vector2(.5, 1.1), Vector2.ONE], [.0, .1])
		tweener.play(self, "modulate:a", [.3, .8], [.0, .3])
		
		while true:
			await get_tree().process_frame
			if not is_mouse_enter() and not button_pressed:
				await get_tree().create_timer(.2).timeout
				if not is_mouse_enter():
					free_roll_button()
					break
	
	func free_roll_button() -> void:
		disabled = true
		EditorServer.roll_buttons_spawned.clear()
		
		var tweener: TweenerComponent = get_tree().get_first_node_in_group(&"tweener")
		tweener.play(self, "scale", [Vector2(.5, 1.1)], [.1])
		tweener.play(self, "modulate:a", [.0], [.3])
		await tweener.tween.finished
		queue_free()


func _init() -> void:
	draw_focus = false
	
	selectable = true
	draggable = true
	group_when_dragging = true
	
	var request_func: Callable = EditorServer.time_line.request_media_clip_selection
	request_selection_func = request_func
	request_drag_func = request_func

func _ready() -> void:
	calculate_metadata(["layer_index", "clip_pos", "clip_res"])
	
	# Super Ready
	super()
	
	# Base
	IS.set_base_settings(self)
	clip_contents = true
	
	# Media Clip Setup
	selection_group = EditorServer.media_clips_selection_group
	var id_key = get_id_key()
	if selection_group.selected_objects.has(id_key):
		selection_group.add_object(id_key, self, get_metadata())
	
	# Focus Panel
	focus_panel = FocusPanelContainer.new(self)
	focus_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	focus_panel.name = "focus_panel"
	add_child(focus_panel)
	
	# Expand Control
	set_anchors_preset(Control.PRESET_FULL_RECT)
	l_expand_button = Button.new()
	l_expand_button.custom_minimum_size = Vector2(10, layer.size.y)
	l_expand_button.mouse_filter = Control.MOUSE_FILTER_PASS
	l_expand_button.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	IS.set_button_style(l_expand_button, STYLE_BUTTONS_SELECT)
	r_expand_button = l_expand_button.duplicate()
	add_child(l_expand_button)
	add_child(r_expand_button)
	r_expand_button.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	r_expand_button.position.x -= 10.0
	
	# Connections
	clip_res.media_clip_res_updated.connect(on_media_res_updated)
	clip_res.comp_animation_res_added.connect(on_media_res_animation_res_added)
	clip_res.comp_animation_res_removed.connect(on_media_res_animation_res_removed)
	
	focus_changed.connect(on_focus_changed)
	drag_started.connect(on_drag_started)
	drag_finished.connect(on_drag_finished)
	
	r_expand_button.mouse_entered.connect(on_expand_buttons_mouse_entered)
	l_expand_button.mouse_entered.connect(on_expand_buttons_mouse_entered)
	r_expand_button.mouse_exited.connect(on_expand_buttons_mouse_exited)
	l_expand_button.mouse_exited.connect(on_expand_buttons_mouse_exited)
	r_expand_button.button_down.connect(on_r_expand_button_drag_changed.bind(true))
	l_expand_button.button_down.connect(on_l_expand_button_drag_changed.bind(true))
	r_expand_button.button_up.connect(on_r_expand_button_drag_changed.bind(false))
	l_expand_button.button_up.connect(on_l_expand_button_drag_changed.bind(false))
	
	update_expand_buttons()
	on_focus_changed(is_focus)


func _input(event: InputEvent) -> void:
	if buttons_mouse_entered:
		return
	
	super(event)
	
	var timeline: TimeLine = EditorServer.time_line
	
	if event is InputEventMouseButton:
		
		match event.button_index:
			MOUSE_BUTTON_LEFT when timeline.timeline_selection_mode == 2:
				var pressed: bool = event.is_pressed()
				if pressed:
					if is_focus:
						is_editing = pressed
						press_pos = event.position
						input_mouse_motion_func = func() -> void:
							var from_delta: int = (press_pos.x - get_global_mouse_position().x) / timeline.display_frame_size
							var media_from_length: Vector2i = MediaServer.get_media_default_from_and_length(clip_res, 0, +INF)
							edit_clip_pos = clip_pos
							edit_from = clamp(clip_res.from + from_delta, media_from_length.x if media_from_length.x != -1 else 0, media_from_length.y - clip_res.length)
							edit_length = clip_res.length
							clip_panel._update_ui(edit_from, edit_length)
							layer.update()
				
				elif is_editing:
					input_mouse_motion_func = Callable()
					edit(true, true)
			
			MOUSE_BUTTON_RIGHT when is_focus:
				if event.is_pressed():
					press_pos = event.position
				else:
					if is_editing:
						is_editing = false
						input_mouse_motion_func = Callable()
						clip_panel._update_ui()
						layer.update()
					elif is_focus and press_pos.distance_to(event.position) <= min_drag_distance:
						select(event.ctrl_pressed, event.alt_pressed)
						if EditorServer.graph_editors_focused.is_empty():
							timeline.popup_media_clips_menu()
	
	elif event is InputEventMouseMotion:
		var local_mouse_pos: Vector2 = get_local_mouse_position()
		var timeline_modes_cond: bool = timeline.timeline_selection_mode == 0 and timeline.timeline_state == 0
		
		if is_focus:
			if timeline_modes_cond and not timeline.clips_selection_box.is_active and not focus_panel.visible:
				if local_mouse_pos.x < 10.0:
					request_spawn_l_roll_button()
				elif local_mouse_pos.x > size.x - 10.0:
					request_spawn_r_roll_button()
		
		if input_mouse_motion_func.is_valid():
			input_mouse_motion_func.call()


func _exit_tree() -> void:
	on_focus_changed(false)

# ---------------------------------------------------

func set_is_selected(new_val: bool) -> void:
	is_selected = new_val
	update_expand_buttons()

func focus_enter() -> void:
	set_select_style(STYLE_FOCUS, STYLE_BUTTONS_FOCUS)

func focus_exit() -> void:
	set_select_style(STYLE_SELECT, STYLE_BUTTONS_SELECT)

func get_id_key() -> String:
	return clip_res.id

func _get_dragged_rect() -> Control:
	return null

# ---------------------------------------------------

func set_clip_panel(new_val: MediaServer.ClipPanel) -> void:
	clip_panel = new_val

func get_clip_panel() -> MediaServer.ClipPanel:
	return clip_panel

# ---------------------------------------------------

func set_select_style(panel_style: StyleBoxFlat, buttons_style: StyleBoxFlat) -> void:
	if not focus_panel or not l_expand_button or not r_expand_button: return
	focus_panel.add_theme_stylebox_override(&"panel", panel_style)
	IS.set_button_style(l_expand_button, buttons_style)
	IS.set_button_style(r_expand_button, buttons_style)

func update_expand_buttons() -> void:
	var show_expand_buttons:= is_selected and not clip_panel.is_graph_editor_opened
	if focus_panel:
		focus_panel.visible = is_selected
	if l_expand_button:
		l_expand_button.visible = show_expand_buttons
		l_expand_button.size.y = size.y
	if r_expand_button:
		r_expand_button.visible = show_expand_buttons
		r_expand_button.size.y = size.y

func open_graph_editor() -> void:
	clip_panel.open_graph_editor()
	update_expand_buttons()

func close_graph_editors() -> void:
	clip_panel.close_graph_editor()
	update_expand_buttons()

func request_spawn_r_roll_button() -> void:
	var neighbor_clip_pos: int = clip_pos + clip_res.length
	var neighbor_clip_info: Variant = layer.displayed_media_clips.get(neighbor_clip_pos)
	if neighbor_clip_info != null:
		var neighbor_clip: MediaClip = neighbor_clip_info.clip
		set_meta(&"right_neighbor_clip", neighbor_clip)
		r_roll_button = RollButton.new()
		r_roll_button.global_position = global_position + Vector2(size.x - 20.0, .0)
		r_roll_button.size = Vector2(40.0, size.y)
		r_roll_button.spawn_roll_button(get_tree().current_scene)

func request_spawn_l_roll_button() -> void:
	var media_clips: Dictionary[int, Dictionary] = layer.displayed_media_clips
	var media_clips_keys: Array[int] = media_clips.keys()
	media_clips_keys.sort()
	var closer_clip_pos_index: int = media_clips_keys.find(clip_pos) - 1
	if closer_clip_pos_index >= 0 and media_clips_keys.size() >= closer_clip_pos_index:
		var closer_clip_pos: int = media_clips_keys.get(closer_clip_pos_index)
		var closer_clip: MediaClip = media_clips.get(closer_clip_pos).clip
		if clip_pos == closer_clip_pos + closer_clip.clip_res.length:
			set_meta(&"left_neighbor_clip", closer_clip)
			l_roll_button = RollButton.new()
			l_roll_button.global_position = global_position - Vector2(20.0, .0)
			l_roll_button.size = Vector2(40.0, size.y)
			l_roll_button.spawn_roll_button(get_tree().current_scene)

# ---------------------------------------------------

func clamp_target_length(target_length: int) -> int:
	return max(1, target_length)

func clamp_target_clip_pos(target_clip_pos: int) -> int:
	var clip_pos_max: int = clip_pos + clip_res.length - 1
	return min(target_clip_pos, clip_pos_max)

func drag_right() -> void:
	var curr_frame_info: Dictionary[int, Variant] = get_frame_from_mouse_pos()
	var curr_frame: int = curr_frame_info.keys()[0]
	var frames_delta: int = curr_frame - get_meta(&"drag_start_frame")
	var target_length: int = clip_res.length + frames_delta
	if curr_frame_info.values()[0] != null:
		target_length = curr_frame - clip_pos
		var drag_target_func: Callable = get_meta(&"drag_target_func")
		if drag_target_func.is_valid():
			target_length = drag_target_func.call()
		else:
			target_length += get_meta(&"drag_offset")
	target_length = clamp_target_length(target_length)
	if has_meta(&"drag_clamp"):
		var drag_clamp: Variant = get_meta(&"drag_clamp")
		if drag_clamp != null:
			target_length = clamp(target_length, drag_clamp.x, drag_clamp.y)
	
	edit_clip_pos = clip_pos
	edit_from = clip_res.from
	edit_length = target_length
	clip_panel._update_ui(edit_from, edit_length)
	
	if r_roll_button:
		r_roll_button.global_position = global_position + Vector2(size.x - 20.0, .0)
	
	focus_panel.queue_redraw()
	layer.update()

func drag_left() -> void:
	var curr_frame_info: Dictionary[int, Variant] = get_frame_from_mouse_pos()
	var curr_frame: int = curr_frame_info.keys()[0]
	var frames_delta: int = curr_frame - get_meta(&"drag_start_frame")
	var target_clip_pos: int = clip_pos + frames_delta
	if curr_frame_info.values()[0] != null:
		target_clip_pos = curr_frame
		var drag_target_func: Callable = get_meta(&"drag_target_func")
		if drag_target_func.is_valid():
			target_clip_pos = drag_target_func.call()
		else:
			target_clip_pos += get_meta(&"drag_offset")
	target_clip_pos = clamp_target_clip_pos(target_clip_pos)
	if has_meta(&"drag_clamp"):
		var drag_clamp: Variant = get_meta(&"drag_clamp")
		if drag_clamp != null:
			target_clip_pos = clamp(target_clip_pos, drag_clamp.x, drag_clamp.y)
	
	var clip_end: int = clip_pos + clip_res.length
	
	edit_clip_pos = target_clip_pos
	edit_from = target_clip_pos - clip_pos + clip_res.from
	edit_length = clip_end - edit_clip_pos
	clip_panel._update_ui(edit_from, edit_length)
	
	if l_roll_button:
		l_roll_button.global_position = global_position - Vector2(20.0, .0)
	
	focus_panel.queue_redraw()
	layer.update()

func split(split_right: bool, split_left: bool, split_in = null) -> void:
	if split_in == null:
		split_in = EditorServer.time_line.curr_frame
	if split_in == clip_pos:
		return
	ProjectServer.split_media_clip(get_metadata(), split_in, split_right, split_left)
	clip_panel._update_ui()

func edit(emit_changes: bool = true, force_layer_index: bool = false) -> void:
	if not edit_length: return
	
	ProjectServer.edit_media_clip(layer_index, clip_pos, {
		"frame_in": edit_clip_pos,
		"from": edit_from,
		"length": edit_length
	}, [], force_layer_index, emit_changes)
	
	await layer.updated
	
	var media_clips: Dictionary[int, Dictionary] = layer.displayed_media_clips
	if r_roll_button:
		var right_clip_pos: int = edit_clip_pos + edit_length
		if media_clips.has(right_clip_pos):
			var new_right_clip: MediaClip = media_clips.get(right_clip_pos).clip
			set_meta(&"right_neighbor_clip", new_right_clip)
		else: r_roll_button.free_roll_button()
	
	elif l_roll_button:
		var new_right_clip: MediaClip = media_clips.get(edit_clip_pos).clip
		new_right_clip.l_roll_button = l_roll_button
		on_l_roll_button_drag_changed.bind(true)
		new_right_clip.set_meta(&"left_neighbor_clip", get_meta(&"left_neighbor_clip"))

# ---------------------------------------------------

func on_media_res_updated() -> void:
	layer.reset_media_clip(clip_pos, is_selected)

func on_media_res_animation_res_added(comp_res: ComponentRes, usable_res: UsableRes, property_key: StringName, anim_res: AnimationRes) -> void:
	if clip_panel.is_graph_editor_opened: open_graph_editor()

func on_media_res_animation_res_removed(comp_res: ComponentRes, usable_res: UsableRes, property_key: StringName) -> void:
	if clip_panel.is_graph_editor_opened: open_graph_editor()

func on_focus_changed(new_val: bool) -> void:
	if new_val: EditorServer.media_clips_focused.append(self)
	else: EditorServer.media_clips_focused.erase(self)

func on_drag_started() -> void:
	selection_group.clear_previously_freed_instances()
	EditorServer.time_line.clips_start_move(
		TimeLine.ClipsMoveMode.MOVE_EDIT,
		selection_group.selected_objects.values(),
		selection_group.selected_objects[get_id_key()]
	)

func on_drag_finished() -> void:
	EditorServer.time_line.clips_end_move()


# ---------------------------------------------------

func on_expand_buttons_mouse_entered() -> void:
	buttons_mouse_entered = true

func on_expand_buttons_mouse_exited() -> void:
	buttons_mouse_entered = false

func on_r_expand_button_drag_changed(val: bool) -> void:
	var media_clips_modulate: Color = Color(1.,1.,1.,.6) if val else Color.WHITE
	if EditorServer.time_line.timeline_edit_mode == 0:
		layer.displayed_media_clips_set_modulate(media_clips_modulate)
		set_r_drag(val, 0)
	else:
		layer.displayed_media_clips_set_modulate(media_clips_modulate)
		selection_group.loop_selected_objects(func(object: MediaClip, metadata: Dictionary) -> void:
			object.set_r_drag(val, (object.clip_pos - clip_pos) + (object.clip_res.length - clip_res.length))
		)

func on_l_expand_button_drag_changed(val: bool) -> void:
	var media_clips_modulate: Color = Color(1.,1.,1.,.6) if val else Color.WHITE
	if EditorServer.time_line.timeline_edit_mode == 0:
		layer.displayed_media_clips_set_modulate(media_clips_modulate)
		set_l_drag(val, 0)
	else:
		layer.displayed_media_clips_set_modulate(media_clips_modulate)
		selection_group.loop_selected_objects(func(object: MediaClip, metadata: Dictionary) -> void:
			object.set_l_drag(val, object.clip_pos - clip_pos)
		)

func on_r_roll_button_drag_changed(val: bool) -> void:
	var right_neighbor_clip: MediaClip = get_meta(&"right_neighbor_clip")
	var drag_offset: int = (right_neighbor_clip.clip_pos - clip_pos) + (right_neighbor_clip.clip_res.length - clip_res.length)
	
	var drag_max: int = right_neighbor_clip.clip_pos + right_neighbor_clip.clip_res.length - 1
	var left_drag_clamp: Vector2i = Vector2i(1, drag_max - clip_pos)
	var right_drag_clamp: Vector2i = Vector2i(clip_pos + 1, drag_max)
	
	set_r_drag(val, 0, Callable(), left_drag_clamp)
	right_neighbor_clip.set_l_drag(val, drag_offset, func() -> int: return clip_pos + edit_length, right_drag_clamp)

func on_l_roll_button_drag_changed(val: bool) -> void:
	var left_neighbor_clip: MediaClip = get_meta(&"left_neighbor_clip")
	
	var drag_max: int = clip_pos + clip_res.length - 1
	var left_drag_clamp: Vector2i = Vector2i(1, drag_max - left_neighbor_clip.clip_pos)
	var right_drag_clamp: Vector2i = Vector2i(left_neighbor_clip.clip_pos + 1, drag_max)
	
	set_l_drag(val, 0, Callable(), right_drag_clamp)
	left_neighbor_clip.set_r_drag(val, left_neighbor_clip.clip_pos - clip_pos, func() -> int:
		return edit_clip_pos - left_neighbor_clip.clip_pos, left_drag_clamp)

func set_r_drag(val: bool, drag_offset: int, drag_target_func: Callable = Callable(), drag_clamp: Variant = null) -> void:
	input_mouse_motion_func = drag_right if val else Callable()
	set_drag(val, drag_offset, drag_target_func, drag_clamp)

func set_l_drag(val: bool, drag_offset: int, drag_target_func: Callable = Callable(), drag_clamp: Variant = null) -> void:
	input_mouse_motion_func = drag_left if val else Callable()
	set_drag(val, drag_offset, drag_target_func, drag_clamp)

func set_drag(val: bool, drag_offset: int, drag_target_func: Callable, drag_clamp: Variant) -> void:
	var timeline: TimeLine = EditorServer.time_line
	timeline.timeline_state = 3 * int(val)
	press_pos = get_global_mouse_position()
	is_editing = val
	if val:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var drag_start_frame: int = get_drag_start_frame(mouse_pos.x)
		set_meta(&"drag_start_frame", drag_start_frame)
		set_meta(&"drag_offset", drag_offset)
		set_meta(&"drag_target_func", drag_target_func)
		if drag_clamp != null:
			set_meta(&"drag_clamp", drag_clamp)
	else:
		edit(true, l_roll_button or r_roll_button)

func get_drag_start_frame(pos: int) -> int:
	var drag_start_frame: int = EditorServer.time_line.get_frame_from_display_pos(pos).keys()[0]
	return drag_start_frame

func get_frame_from_mouse_pos() -> Dictionary[int, Variant]:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var result: Dictionary[int, Variant] = EditorServer.time_line.get_frame_from_display_pos(mouse_pos.x)
	return result
