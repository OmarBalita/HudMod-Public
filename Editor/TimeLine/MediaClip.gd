class_name MediaClip extends FocusControl

const STYLE_SELECT: StyleBoxFlat = preload("uid://bdikx7yabbrki")
const STYLE_FOCUS: StyleBoxFlat = preload("uid://kkroptu2c0c1")
const STYLE_BUTTONS_SELECT: StyleBoxFlat = preload("uid://bb4m7kvycelsj")
const STYLE_BUTTONS_FOCUS: StyleBoxFlat = preload("uid://yvx6gwfm0v3b")

# Main Variables
var type: MediaClipRes.MediaType
var layer_index: int
var clip_pos: int
var clip_res: MediaClipRes

# RealTime Variables
var is_editing: bool

var edit_frame_in: int
var edit_from: int
var edit_length: int

var buttons_mouse_entered: bool
var r_button_dragged: bool
var l_button_dragged: bool

# RealTime Nodes
var layer: Layer
var clip_control: Control:
	set(val):
		if clip_control:
			clip_control.queue_free()
		if val:
			val.set_name("clip_control")
			add_child(val)
		clip_control = val
var graph_editors_container: BoxContainer:
	set(val):
		if graph_editors_container:
			graph_editors_container.queue_free()
		if val:
			val.set_name("editors_container")
			add_child(val)
		graph_editors_container = val
		var is_null: bool = val == null
		clip_control.visible = is_null
		update_expand_buttons()

var focus_panel: PanelContainer
var r_expand_button: Button
var l_expand_button: Button


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
	focus_panel = IS.create_panel_container(Vector2.ZERO, STYLE_SELECT, {visible = false})
	focus_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	focus_panel.name = "focus_panel"
	add_child(focus_panel)
	
	# Expand Control
	await get_tree().process_frame
	set_anchors_preset(Control.PRESET_FULL_RECT)
	l_expand_button = Button.new()
	l_expand_button.custom_minimum_size = Vector2(10, size.y)
	l_expand_button.mouse_filter = Control.MOUSE_FILTER_PASS
	IS.set_button_style(l_expand_button, STYLE_BUTTONS_SELECT)
	r_expand_button = l_expand_button.duplicate()
	add_child(l_expand_button)
	add_child(r_expand_button)
	r_expand_button.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	r_expand_button.position.x -= 10.0
	
	# Connections
	
	focus_changed.connect(on_focus_changed)
	drag_started.connect(on_drag_started)
	drag_finished.connect(on_drag_finished)
	
	r_expand_button.mouse_entered.connect(on_expand_buttons_mouse_entered)
	l_expand_button.mouse_entered.connect(on_expand_buttons_mouse_entered)
	r_expand_button.mouse_exited.connect(on_expand_buttons_mouse_exited)
	l_expand_button.mouse_exited.connect(on_expand_buttons_mouse_exited)
	r_expand_button.button_down.connect(set_r_button_dragged.bind(true))
	l_expand_button.button_down.connect(set_l_button_dragged.bind(true))
	r_expand_button.button_up.connect(set_r_button_dragged.bind(false))
	l_expand_button.button_up.connect(set_l_button_dragged.bind(false))
	
	update_lock()
	update_expand_buttons()


func _input(event: InputEvent) -> void:
	if not ProjectServer.get_layer_lock(layer_index):
		
		if buttons_mouse_entered:
			return
		
		super(event)
		
		if is_focus:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_RIGHT:
					if event.is_pressed(): press_pos = event.position
					elif press_pos.distance_to(event.position) <= min_drag_distance:
						EditorServer.time_line.popup_media_clips_menu()
						select(event.ctrl_pressed, event.alt_pressed)

func _physics_process(delta: float) -> void:
	if r_button_dragged:
		drag_right_button()
		layer.update()
	elif l_button_dragged:
		drag_left_button()
		layer.update()


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
	#var color_rect: ColorRect = ColorRect.new()
	#color_rect.color = Color(IS.COLOR_ACCENT_BLUE, .5)
	return null


# ---------------------------------------------------

func set_clip_control(new_val: Control) -> void:
	clip_control = new_val

func get_clip_control() -> Control:
	return clip_control

func set_graph_editors_container(new_val: BoxContainer) -> void:
	graph_editors_container = new_val

func get_graph_editors_container() -> BoxContainer:
	return graph_editors_container


# ---------------------------------------------------

func set_select_style(panel_style: StyleBoxFlat, buttons_style: StyleBoxFlat) -> void:
	if not focus_panel or not l_expand_button or not r_expand_button: return
	focus_panel.add_theme_stylebox_override("panel", panel_style)
	IS.set_button_style(l_expand_button, buttons_style)
	IS.set_button_style(r_expand_button, buttons_style)

func update_lock() -> void:
	if ProjectServer.get_layer_lock(layer_index):
		deselect()
		modulate.a = .5
	else:
		modulate.a = 1.0

func update_expand_buttons() -> void:
	var show_expand_buttons:= is_selected and not graph_editors_container
	if focus_panel:
		focus_panel.visible = is_selected
	if l_expand_button:
		l_expand_button.visible = show_expand_buttons
		l_expand_button.size.y = size.y
	if r_expand_button:
		r_expand_button.visible = show_expand_buttons
		r_expand_button.size.y = size.y
		#r_expand_button.position.x = size.x - 10

func open_graph_editors() -> void:
	layer.open_graph_editors(clip_pos)

func close_graph_editors() -> void:
	layer.close_graph_editors(clip_pos)


# ---------------------------------------------------

func drag_right_button() -> void:
	edit_frame_in = clip_pos
	edit_from = clip_res.from
	var length: int = clip_res.length # TimeServer.seconds_to_frame(MediaServer.get_audio_duration_with_ffprobe(clip_res.key_as_path))
	var is_range_limit: bool = type in [2, 3]
	edit_length = clamp(EditorServer.time_line.get_frame_from_mouse_pos([clip_res]) - clip_pos, 1, length - clip_res.from if is_range_limit else +INF)

func drag_left_button() -> void:
	var display_frame: int = EditorServer.time_line.get_frame_from_mouse_pos([clip_res])
	var expand_dist: int = display_frame - clip_pos
	var end_pos: int = clip_res.length + clip_pos
	var frame_in_max: int = end_pos - 1
	var is_range_limit: bool = type in [2, 3]
	edit_frame_in = clamp(display_frame, clip_pos - clip_res.from if is_range_limit else -INF, frame_in_max)
	edit_from = clamp(expand_dist + clip_res.from, 0, frame_in_max)
	edit_length = end_pos - edit_frame_in

func split(split_right: bool, split_left: bool, split_in = null) -> void:
	if split_in == null:
		split_in = EditorServer.time_line.curr_frame
	ProjectServer.split_media_clip(get_metadata(), split_in, split_right, split_left)

func edit(emit_changes: bool = true) -> void:
	ProjectServer.edit_media_clip(layer_index, clip_pos, {
		"frame_in": edit_frame_in,
		"from": edit_from,
		"length": edit_length
	}, emit_changes)


# ---------------------------------------------------

func on_focus_changed(new_val: bool) -> void:
	if new_val: EditorServer.media_clips_focused.append(self)
	else: EditorServer.media_clips_focused.erase(self)

func on_drag_started() -> void:
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

func set_r_button_dragged(val: bool) -> void:
	r_button_dragged = val
	drag_right_button()
	set_button_dragged(val)

func set_l_button_dragged(val: bool) -> void:
	l_button_dragged = val
	drag_left_button()
	set_button_dragged(val)

func set_button_dragged(val: bool) -> void:
	EditorServer.time_line.timeline_state = 3 * int(val)
	press_pos = get_global_mouse_position()
	is_editing = val
	if not val: edit()
