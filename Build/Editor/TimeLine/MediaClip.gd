class_name MediaClip extends FocusControl



var color: Color

var is_editing: bool

var type: int
var layer_index: int
var clip_pos: int
var clip_res: MediaClipRes

var target_layer_index: int
var target_frame: int

var edit_frame_in: int
var edit_from: int
var edit_length: int

var r_button_dragged: bool
var l_button_dragged: bool


var layer: Layer
var r_expand_button: Button
var l_expand_button: Button






func _init() -> void:
	
	draw_select = true
	
	selectable = true
	select_cancelers.append(EditorServer.time_line.is_timeline_state_equal_to.bind(2))
	metadata_keys = ["layer_index", "clip_pos", "clip_res"]

func _ready() -> void:
	
	# Super Ready
	super()
	
	# Base
	InterfaceServer.set_base_settings(self)
	clip_contents = true
	
	# Media Clip Setup
	selection_group = EditorServer.media_clips_selection_group
	var id_key = get_id_key()
	if selection_group.selected_objects.has(id_key):
		selection_group.add_object(id_key, self, get_metadata())
	
	# Expand Control
	await get_tree().process_frame
	set_anchors_preset(Control.PRESET_FULL_RECT)
	l_expand_button = Button.new()
	l_expand_button.custom_minimum_size = Vector2(10, size.y)
	l_expand_button.mouse_filter = Control.MOUSE_FILTER_STOP
	InterfaceServer.set_button_style(l_expand_button)
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
	
	r_expand_button.button_down.connect(set_r_button_dragged.bind(true))
	r_expand_button.button_up.connect(set_r_button_dragged.bind(false))
	l_expand_button.button_down.connect(set_l_button_dragged.bind(true))
	l_expand_button.button_up.connect(set_l_button_dragged.bind(false))
	
	update_lock()
	update_expand_buttons()


func _input(event: InputEvent) -> void:
	if not ProjectServer.get_layer_lock(layer_index):
		super(event)
		
		if is_focus:
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_RIGHT:
					if event.is_pressed(): press_pos = event.position
					elif press_pos.distance_to(event.position) <= min_drag_distance:
						popup_context_menu()



func _physics_process(delta: float) -> void:
	if r_button_dragged:
		drag_right_button()
		layer.update()
	elif l_button_dragged:
		drag_left_button()
		layer.update()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	super()

func get_id_key() -> String:
	return clip_res.id




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
	if l_expand_button:
		l_expand_button.visible = is_selected
	if r_expand_button:
		r_expand_button.visible = is_selected
		r_expand_button.position.x = size.x - 10

func drag_right_button() -> void:
	edit_frame_in = clip_pos
	edit_from = clip_res.from
	var length = TimeServer.seconds_to_frame(MediaServer.get_audio_duration_with_ffprobe(clip_res.media_resource_path))
	edit_length = clamp(get_frame_from_mouse_pos() - clip_pos, 1, length - clip_res.from if type else +INF)

func drag_left_button() -> void:
	var display_frame = get_frame_from_mouse_pos()
	var expand_dist = display_frame - clip_pos
	var end_pos = clip_res.length + clip_pos
	var frame_in_max = end_pos - 1
	edit_frame_in = clamp(display_frame, clip_pos - clip_res.from if type else -INF, frame_in_max)
	edit_from = clamp(expand_dist + clip_res.from, 0, frame_in_max)
	edit_length = end_pos - edit_frame_in

func split(split_right: bool, split_left: bool) -> void:
	ProjectServer.split_media_clip(get_metadata(), EditorServer.time_line.curr_frame, split_right, split_left)


func edit(emit_changes: bool = true) -> void:
	ProjectServer.edit_media_clip(layer_index, clip_pos, {
		"frame_in": edit_frame_in,
		"from": edit_from,
		"length": edit_length
	}, emit_changes)

func get_frame_from_mouse_pos() -> int:
	return EditorServer.time_line.get_frame_from_display_pos(get_global_mouse_position().x, [clip_res]).keys()[0]

func popup_context_menu() -> void:
	
	var menu = InterfaceServer.create_popuped_menu([
		MenuOption.new("Cut"),
		MenuOption.new("Copy"),
		MenuOption.new("Duplicate"),
		MenuOption.new("Remove"),
		MenuOption.new_line(),
		MenuOption.new("Group"),
		MenuOption.new("UnGroup"),
		MenuOption.new_line(),
		MenuOption.new("Reparent"),
		MenuOption.new("Parent Up"),
		MenuOption.new("Clear Parents"),
		MenuOption.new_line(),
		MenuOption.new("Replace Media"),
		MenuOption.new("Reverse Clip"),
		MenuOption.new("Extract Audio"),
		MenuOption.new_line(),
		MenuOption.new("Go Inside"),
		MenuOption.new("Open Graph Editor"),
		MenuOption.new_line(),
		MenuOption.new("Render Clip/s"),
		MenuOption.new("Save Clip/s as"),
		MenuOption.new("Save as Global Preset"),
		MenuOption.new("Save as Project Preset")
	])
	get_tree().get_current_scene().add_child(menu)
	menu.popup()







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
				
				var begin_pos = dragged_rect.global_position.x
				var frame_begin_result = timeline.get_frame_from_display_pos(begin_pos, clips_resources, true, true, false)
				var frame_end_result = timeline.get_frame_from_display_pos(begin_pos + size.x, clips_resources, true, true, false)
				var begin_snap_dist = frame_begin_result.values()[0]
				var end_snap_dist = frame_end_result.values()[0]
				
				if begin_snap_dist or end_snap_dist == null:
					var begin_frame = frame_begin_result.keys()[0]
					target_frame = begin_frame
					timeline.set_snap_pos(begin_frame if begin_snap_dist != null else null)
				elif end_snap_dist or begin_snap_dist == null:
					var end_frame = frame_end_result.keys()[0]
					target_frame = end_frame - clip_res.length
					timeline.set_snap_pos(end_frame if end_snap_dist != null else null)
				
				var selected_objects = selection_group.selected_objects
				var layer_delta = target_layer_index - layer_index
				var frame_delta = target_frame - clip_pos
				
				for key in selected_objects:
					var selected_clip = selected_objects[key].object
					if not is_instance_valid(selected_clip): continue
					if selected_clip == self: continue
					var clip_target_layer = selected_clip.layer_index + layer_delta
					var clip_target_frame = selected_clip.clip_pos + frame_delta
					selected_clip.target_layer_index = clip_target_layer
					selected_clip.target_frame = clip_target_frame
					
					#var clip_layer = timeline.get_layer_from_index(clip_target_layer)
					#var clip_dragged_rect = selected_clip.dragged_rect
					#if clip_layer and clip_dragged_rect:
						#var rect_x_pos = timeline.get_display_pos_from_frame(timeline.get_frame_from_display_pos(clip_dragged_rect.global_position.x, [], true, true, false).keys()[0], clip_layer)
						#clip_layer.draw_new_rect(Rect2(Vector2(rect_x_pos, 0), selected_clip.size))
				
				var rect_x_pos = timeline.get_display_pos_from_frame(target_frame, layer)
				layer.draw_new_rect(Rect2(Vector2(rect_x_pos, 0), size))
				break


func on_drag_finished() -> void:
	
	var timeline = EditorServer.time_line
	timeline.set_timeline_state(0)
	
	if target_layer_index == -1:
		ProjectServer.media_clips_changed.emit()
		return
	
	ProjectServer.move_media_clips(
		selection_group.get_selected_meta(),
		selection_group.get_selected_objects_property("target_layer_index"),
		selection_group.get_selected_objects_property("target_frame")
	)
	
	timeline.clear_layers_drawed_entities()















