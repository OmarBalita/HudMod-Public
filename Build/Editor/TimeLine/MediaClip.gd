class_name MediaClip extends FocusControl

const STYLE_SELECT: StyleBoxFlat = preload("uid://bdikx7yabbrki")
const STYLE_FOCUS: StyleBoxFlat = preload("uid://kkroptu2c0c1")
const STYLE_BUTTONS_SELECT: StyleBoxFlat = preload("uid://bb4m7kvycelsj")
const STYLE_BUTTONS_FOCUS: StyleBoxFlat = preload("uid://yvx6gwfm0v3b")

# Main Variables
var type: int
var layer_index: int
var clip_pos: int
var clip_res: MediaClipRes

# RealTime Variables
var is_editing: bool

var target_layer_index: int
var target_frame: int

var edit_frame_in: int
var edit_from: int
var edit_length: int

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
	
	var request_func: Callable = EditorServer.time_line.request_media_clip_selection
	request_selection_func = request_func
	request_drag_func = request_func
	metadata_keys = ["layer_index", "clip_pos", "clip_res"]

func _ready() -> void:
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
	focus_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	
	# Connections
	ProjectServer.layer_changed.connect(update_lock)
	
	resized.connect(update_expand_buttons)
	focus_changed.connect(on_focus_changed)
	selected.connect(update_expand_buttons)
	deselected.connect(update_expand_buttons)
	drag_started.connect(on_drag_started)
	dragging.connect(on_dragging)
	drag_finished.connect(on_drag_finished)
	dragged_rect_created.connect(on_dragged_rect_created)
	
	r_expand_button.button_down.connect(on_r_expand_button_downed)
	r_expand_button.button_up.connect(set_r_button_dragged.bind(false))
	l_expand_button.button_down.connect(set_l_button_dragged.bind(true))
	l_expand_button.button_up.connect(set_l_button_dragged.bind(false))
	
	update_lock()
	update_expand_buttons()
	select(true, false)

func _input(event: InputEvent) -> void:
	if not ProjectServer.get_layer_lock(layer_index) and EditorServer.time_line.timeline_selection_mode == 0:
		
		if r_button_dragged or l_button_dragged:
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


func focus_enter() -> void:
	set_select_style(STYLE_FOCUS, STYLE_BUTTONS_FOCUS)

func focus_exit() -> void:
	set_select_style(STYLE_SELECT, STYLE_BUTTONS_SELECT)

func get_id_key() -> String:
	return clip_res.id


func set_clip_control(new_val: Control) -> void:
	clip_control = new_val

func get_clip_control() -> Control:
	return clip_control

func set_graph_editors_container(new_val: BoxContainer) -> void:
	graph_editors_container = new_val

func get_graph_editors_container() -> BoxContainer:
	return graph_editors_container


func open_graph_editors() -> void:
	layer.open_graph_editors(clip_pos)

func close_graph_editors() -> void:
	layer.close_graph_editors(clip_pos)

func set_select_style(panel_style: StyleBoxFlat, buttons_style: StyleBoxFlat) -> void:
	if not focus_panel or not l_expand_button or not r_expand_button: return
	focus_panel.add_theme_stylebox_override("panel", panel_style)
	IS.set_button_style(l_expand_button, buttons_style)
	IS.set_button_style(r_expand_button, buttons_style)


func set_r_button_dragged(val: bool) -> void:
	r_button_dragged = val
	is_editing = val
	drag_right_button()
	EditorServer.time_line.timeline_state = 3 * int(val)
	if not val:
		edit()

func set_l_button_dragged(val: bool) -> void:
	l_button_dragged = val
	is_editing = val
	drag_left_button()
	EditorServer.time_line.timeline_state = 3 * int(val)
	if not val:
		edit()




func update_lock() -> void:
	if ProjectServer.get_layer_lock(layer_index):
		deselect()
		modulate.a = .5
	else:
		modulate.a = 1.0

func update_expand_buttons() -> void:
	focus_panel.visible = is_selected
	var show_expand_buttons:= is_selected and not graph_editors_container
	if l_expand_button:
		l_expand_button.visible = show_expand_buttons
		l_expand_button.size.y = size.y
	if r_expand_button:
		r_expand_button.visible = show_expand_buttons
		r_expand_button.position.x = size.x - 10
		r_expand_button.size.y = size.y

func drag_right_button() -> void:
	edit_frame_in = clip_pos
	edit_from = clip_res.from
	var length = TimeServer.seconds_to_frame(MediaServer.get_audio_duration_with_ffprobe(clip_res.media_resource_path))
	edit_length = clamp(EditorServer.time_line.get_frame_from_mouse_pos([clip_res]) - clip_pos, 1, length - clip_res.from if type else +INF)

func drag_left_button() -> void:
	var display_frame = EditorServer.time_line.get_frame_from_mouse_pos([clip_res])
	var expand_dist = display_frame - clip_pos
	var end_pos = clip_res.length + clip_pos
	var frame_in_max = end_pos - 1
	edit_frame_in = clamp(display_frame, clip_pos - clip_res.from if type else -INF, frame_in_max)
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




func on_focus_changed(new_val: bool) -> void:
	if new_val: EditorServer.media_clips_focused.append(self)
	else: EditorServer.media_clips_focused.erase(self)

func on_drag_started() -> void:
	var timeline = EditorServer.time_line
	timeline.set_timeline_state(1)

func on_dragging() -> void:
	
	var timeline = EditorServer.time_line
	var displayed_layers = timeline.layers_container.get_children()
	
	var mouse_pos = get_global_mouse_position()
	
	if not following_drag:
		target_layer_index = -1
		timeline.clear_layers_drawed_entities()
		
		for layer: Layer in displayed_layers:
			
			if layer.get_global_rect().has_point(mouse_pos):
				
				target_layer_index = layer.index
				
				var clips_resources = selection_group.get_selected_objects_property("clip_res")
				
				var begin_pos: float = dragged_rect.global_position.x
				var frame_begin_result: Dictionary[int, Variant] = timeline.get_frame_from_display_pos(begin_pos, clips_resources, true, true, false)
				var frame_end_result: Dictionary[int, Variant] = timeline.get_frame_from_display_pos(begin_pos + size.x, clips_resources, true, true, false)
				var begin_snap_dist: Variant = frame_begin_result.values()[0]
				var end_snap_dist = frame_end_result.values()[0]
				
				if begin_snap_dist or end_snap_dist == null:
					var begin_frame = frame_begin_result.keys()[0]
					target_frame = begin_frame
					timeline.set_snap_pos(begin_frame if begin_snap_dist != null else null)
				
				elif end_snap_dist or begin_snap_dist == null:
					var end_frame = frame_end_result.keys()[0]
					target_frame = end_frame - clip_res.length
					timeline.set_snap_pos(end_frame if end_snap_dist != null else null)
				
				var selected_objects: Dictionary[String, Dictionary] = selection_group.selected_objects
				var layer_delta: int = target_layer_index - layer_index
				var frame_delta: int = target_frame - clip_pos
				
				for key in selected_objects:
					var selected_clip = selected_objects[key].object
					if not is_instance_valid(selected_clip): continue
					if selected_clip == self: continue
					var clip_target_layer = selected_clip.layer_index + layer_delta
					var clip_target_frame = selected_clip.clip_pos + frame_delta
					selected_clip.target_layer_index = clip_target_layer
					selected_clip.target_frame = clip_target_frame
					
					var clip_layer = timeline.get_layer(clip_target_layer)
					var clip_dragged_rect = selected_clip.dragged_rect
					if clip_layer and clip_dragged_rect:
						var rect_x_pos = timeline.get_display_pos_from_frame(timeline.get_frame_from_display_pos(clip_dragged_rect.global_position.x, [], true, true, false).keys()[0], clip_layer)
						var rect2: Rect2 = Rect2(Vector2(rect_x_pos, 0), selected_clip.size)
						clip_layer.draw_new_rect(rect2, Color(IS.COLOR_ACCENT_BLUE, .4))
						clip_layer.draw_new_rect(rect2, IS.COLOR_ACCENT_BLUE, false, 5.0)
				
				var rect_x_pos: float = timeline.get_display_pos_from_frame(target_frame, layer)
				var rect2: Rect2 = Rect2(Vector2(rect_x_pos, 0), Vector2(size.x, layer.curr_y_size))
				layer.draw_new_rect(rect2, Color(IS.COLOR_ACCENT_BLUE, .4))
				layer.draw_new_rect(rect2, IS.COLOR_ACCENT_BLUE, false, 5.0)

func on_drag_finished() -> void:
	
	if target_layer_index == -1:
		ProjectServer.media_clips_changed.emit()
		return
	
	ProjectServer.move_media_clips(
		selection_group.get_selected_meta(),
		selection_group.get_selected_objects_property("target_layer_index"),
		selection_group.get_selected_objects_property("target_frame")
	)
	
	var timeline = EditorServer.time_line
	timeline.set_timeline_state(0)


func on_dragged_rect_created(dragged_rect: Control) -> void:
	var clip_control: Control = dragged_rect.get_node("clip_control")
	var editors_container: BoxContainer = dragged_rect.get_node("editors_container")
	dragged_rect.get_node("focus_panel").size = size
	clip_control.show(); clip_control.size = size
	if editors_container: editors_container.hide()


func on_r_expand_button_downed() -> void:
	set_r_button_dragged(true)

func on_r_expand_button_upped() -> void:
	set_r_button_dragged(false)
	
func on_l_expand_button_downed() -> void:
	set_l_button_dragged(true)

func on_l_expand_button_upped() -> void:
	set_l_button_dragged(false)











