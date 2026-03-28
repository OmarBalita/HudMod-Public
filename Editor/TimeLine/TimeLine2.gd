class_name TimeLine2 extends EditorControl

signal timeline_view_updated()

enum EditMode {
	MODE_SELECT,
	MODE_SPLIT,
	MODE_SLIP
}

enum EditMultiple {
	EDIT_SINGLE,
	EDIT_MULTIPLE
}

const SMALL_STEP_BY_FPS: Dictionary[int, int] = {
	80: 4,
	40: 2,
	1: 1
}

@onready var header_cont: BoxContainer = IS.create_box_container(12)
@onready var edit_mode_btn: OptionController = IS.create_options_controller_2(0, EditMode)
@onready var edit_multiple_btn: OptionController = IS.create_options_controller_2(1, EditMultiple)
@onready var add_layer_btn: Button = IS.create_button("Add Layer", IS.TEXTURE_ADD)
@onready var split_panelcont: PanelContainer = IS.create_panel_container()
@onready var split_left_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/left-split-clip.png"))
@onready var split_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/split-clip.png"))
@onready var split_right_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/right-split-clip.png"))
@onready var marker_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/location-marker.png"))
@onready var clip_path_ctrlr: PathController = PathController.new()
@onready var overlay_menu: Menu = IS.create_menu([
	MenuOption.new("", preload("res://Asset/Icons/AddClipMethods/place_on_top.png")),
	MenuOption.new("", preload("res://Asset/Icons/AddClipMethods/insert.png")),
	MenuOption.new("", preload("res://Asset/Icons/AddClipMethods/overwrite.png")),
	MenuOption.new("", preload("res://Asset/Icons/AddClipMethods/fit_to_fill.png")),
	MenuOption.new("", preload("res://Asset/Icons/AddClipMethods/replace.png"))
], false, false, {custom_minimum_size = Vector2(300., .0)})
@onready var snap_panelcont: PanelContainer = IS.create_panel_container()
@onready var snap_cursor_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/snap (1).png"), null, null, true)
@onready var snap_timemarks_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/snap (2).png"), null, null, true)
@onready var snap_clips_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/snap.png"), null, null, true)
@onready var center_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/world-origin.png"))

@onready var body_boxcont: BoxContainer = IS.create_box_container(6, true)
@onready var timemark_panel: TimeMarkPanelContainer = TimeMarkPanelContainer.new(self)
@onready var layers_body: LayersSelectContainer = LayersSelectContainer.new(self)
@onready var scroll_cont: ScrollContainer = IS.create_scroll_container()
@onready var layers_cont: ArrangableBoxContainer = ArrangableBoxContainer.new(layers_body, scroll_cont)
@onready var margin_control: Control = IS.create_empty_control(.0, 100.)
@onready var h_scrollbar: HScrollBar = HScrollBar.new()

@export var navigation_horizontal_speed: float = .1
@export var navigation_vertical_speed: float = 15.
@export var zoom_speed: float = .05
@export var zoom_min: float = .01
@export var zoom_max: float = 10.

@export var edges_scale: float = 100.
@export var edges_speed_factor_h: float = .1
@export var edges_speed_factor_v: float = 10.

@export var dist_to_snap: float = .2

@export var margin_size: float = 3.

var center: int = 0
var zoom: float = 1.:
	set(val): zoom = clampf(val, zoom_min, zoom_max)

var zoom_factor: float

var domain_len: int
var domain_step: int
var domain_small_step: int

var displ_frame_size: float
var displ_timemark_size_h: float

var edges_nav_horizontal: bool = false:
	set(val): edges_nav_horizontal = val; _update_process_enabling()
var edges_nav_vertical: bool = false:
	set(val): edges_nav_vertical = val; _update_process_enabling()
var edges_nav_velocity: Vector2

var frame_start: int
var frame_end: int

var clips_spacial_frames: PackedInt32Array
var timemarkers_spacial_frames: PackedInt32Array
var spacial_frames: PackedInt32Array

var displ_frame_start: float
var displ_frame_end: float

var predefined_frames: PackedFloat32Array
var small_step_scaler: int

var opened_clip_res: MediaClipRes
var layers: Dictionary[LayerRes, Layer2]


func _ready_editor() -> void:
	
	#region header
	
	var path_scroll_cont: ScrollContainer = IS.create_scroll_container(3, 0)
	path_scroll_cont.add_child(clip_path_ctrlr)
	
	clip_path_ctrlr.set_root_name(&"Root")
	
	overlay_menu.expand_icons = true
	snap_cursor_btn.button_pressed = true
	snap_clips_btn.button_pressed = true
	
	header.add_child(header_cont)
	IS.add_children(header_cont, [
		edit_mode_btn,
		edit_multiple_btn,
		add_layer_btn,
		split_panelcont,
		marker_btn,
		path_scroll_cont,
		overlay_menu,
		snap_panelcont,
		center_btn,
	])
	var split_cont: BoxContainer = IS.create_box_container(12)
	var snap_cont: BoxContainer = IS.create_box_container(12)
	split_panelcont.add_child(split_cont)
	snap_panelcont.add_child(snap_cont)
	split_cont.add_child(split_left_btn)
	split_cont.add_child(split_btn)
	split_cont.add_child(split_right_btn)
	snap_cont.add_child(snap_cursor_btn)
	snap_cont.add_child(snap_timemarks_btn)
	snap_cont.add_child(snap_clips_btn)
	
	IS.expand(path_scroll_cont, true)
	IS.expand(clip_path_ctrlr, true)
	IS.set_button_style(edit_mode_btn, IS.STYLE_BUTTON_ACCENT)
	
	edit_mode_btn.selected_option_changed.connect(_on_mode_btn_selected_option_changed)
	edit_multiple_btn.selected_option_changed.connect(_on_edit_multiple_btn_selected_option_changed)
	add_layer_btn.pressed.connect(_on_add_layer_btn_pressed)
	marker_btn.pressed.connect(_on_marker_btn_pressed)
	clip_path_ctrlr.undo_requested.connect(_on_clip_path_ctrlr_undo_requested)
	center_btn.pressed.connect(_on_center_btn_pressed)
	
	#endregion
	
	#region body
	
	body.add_child(body_boxcont)
	IS.add_children(body_boxcont, [timemark_panel, layers_body, h_scrollbar])
	layers_body.add_child(scroll_cont)
	scroll_cont.add_child(layers_cont)
	layers_cont.add_child(margin_control)
	
	clip_contents = true
	
	timemark_panel.custom_minimum_size.y = 30.
	timemark_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layers_body.mouse_filter = Control.MOUSE_FILTER_PASS
	
	layers_body.add_theme_stylebox_override(&"panel", IS.STYLE_BOX_EMPTY)
	layers_cont.add_theme_constant_override(&"separation", 2)
	
	IS.expand(body_boxcont, true, true)
	IS.expand(layers_body, true, true)
	IS.expand(layers_cont, true, true)
	
	body_boxcont.gui_input.connect(_body_boxcont_gui_input)
	body.gui_input.connect(_body_gui_input)
	
	layers_body.resized.connect(update_timeline_view)
	layers_body.selected_changed.connect(update_layers_clips_selection)
	
	scroll_cont.get_v_scroll_bar().scrolling.connect(_on_scroll_cont_scroll_bar_scrolling)
	
	h_scrollbar.scrolling.connect(_on_h_scrollbar_scrolling)
	
	#endregion
	
	open_project_res(ProjectServer2.project_res)
	open_clip_res(ProjectServer2.opened_clip_res_path.back())
	ProjectServer2.project_opened.connect(_on_project_server_project_opened)
	ProjectServer2.opened_clip_res_changed.connect(_on_project_server_opened_clip_res_changed)
	
	update_timeline_view()
	update_all_spacial_frames()
	
	_update_process_enabling()

func _body_boxcont_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		update_edges_navs_velocity()

func _body_gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		
		var method: Callable
		
		if event.ctrl_pressed: method = try_effect_zoom
		elif event.shift_pressed: method = navigate_horizontal
		else: method = navigate_vertical
		
		match event.button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				method.call(1)
			MOUSE_BUTTON_WHEEL_UP:
				method.call(-1)
		
		update_timeline_view()


func _process(delta: float) -> void:
	apply_edges_navs(delta)

func _update_process_enabling() -> void:
	set_process(edges_nav_horizontal or edges_nav_vertical)

func _draw() -> void:
	
	var timemarkpanel_pos: Vector2 = timemark_panel.global_position - global_position
	var cursor_pos: float = get_display_pos_from_cursor()
	
	if cursor_pos > 268. and cursor_pos <= size.x - 16.: # layer.leftside_panel.size = 250. + body.margin_left = 8. + layer.split_cont.sepration = 12. = 268.
		draw_line(Vector2(cursor_pos, timemarkpanel_pos.y + timemark_panel.size.y + 8.), Vector2(cursor_pos, size.y - (h_scrollbar.size.y + 12. if h_scrollbar.visible else 8.)), Color.LIGHT_GRAY, 2.)


func navigate_horizontal(dir: int) -> void: center += dir * (navigation_horizontal_speed * ProjectServer2.project_res.fps) * zoom_factor
func navigate_horizontal_to(target_center: int, t: float = 1.) -> void: center = lerp(center, target_center, t)
func navigate_to_cursor(nav_dir: int) -> void:
	var cursor_pos: float = get_display_pos_from_cursor()
	if cursor_pos < .0 or cursor_pos > size.x:
		var displacement: int = displ_timemark_size_h / displ_frame_size
		navigate_horizontal_to(PlaybackServer.position + displacement * nav_dir)

func navigate_vertical(dir: int) -> void: scroll_cont.scroll_vertical += dir * navigation_vertical_speed
func navigate_vertical_to(target: int, t: float = 1.) -> void: scroll_cont.scroll_vertical = lerp(scroll_cont.scroll_vertical, target, t)


func try_effect_zoom(dir: int) -> void:
	if EditorServer.graph_editors_focused.is_empty():
		effect_zoom(dir)

func effect_zoom(dir: int) -> void:
	var old_zoom: float = zoom
	var zoom_effect: float = dir * zoom_speed
	
	if zoom < 1.:
		zoom_effect *= maxf(.1, zoom)
	
	zoom += zoom_effect
	
	if zoom == old_zoom:
		return
	
	var displacement: int = (get_frame_from_mouse_pos() - center) * .05
	if zoom > old_zoom: displacement *= -1
	center += displacement


func update_edges_navs_velocity() -> void:
	var mouse_pos: Vector2 = layers_body.get_local_mouse_position()
	var dist_h:= Vector2(mouse_pos.x, layers_body.size.x - mouse_pos.x) # Vector2(dist_left, dist_right)
	var dist_v:= Vector2(mouse_pos.y, layers_body.size.y - mouse_pos.y) # Vector2(dist_up, dist_down)
	
	if dist_h.x < edges_scale: edges_nav_velocity.x = dist_h.x - edges_scale
	elif dist_h.y < edges_scale: edges_nav_velocity.x = edges_scale - dist_h.y
	else: edges_nav_velocity.x = .0
	
	if dist_v.x < edges_scale: edges_nav_velocity.y = dist_v.x - edges_scale
	elif dist_v.y < edges_scale: edges_nav_velocity.y = edges_scale - dist_v.y
	else: edges_nav_velocity.y = .0

func apply_edges_navs(delta: float) -> void:
	var is_dirty: bool
	
	if edges_nav_horizontal and edges_nav_velocity.x:
		center += edges_nav_velocity.x * zoom_factor * edges_speed_factor_h * ProjectServer2.project_res.fps * delta
		PlaybackServer.position = snap_frame(get_frame_from_mouse_pos(), true, false)
		is_dirty = true
	
	if edges_nav_vertical and edges_nav_velocity.y:
		scroll_cont.scroll_vertical += edges_nav_velocity.y * edges_speed_factor_v * delta
		is_dirty = true
	
	if is_dirty:
		update_timeline_view()


func update_timeline_view() -> void:
	await get_tree().process_frame
	
	_update_vars()
	
	_update_horizontal_scrollbar()
	update_layers_clips()
	timemark_panel.update_timemarkpanel_view()
	queue_redraw()
	
	_update_waveforms_pixelate_scale()
	
	timeline_view_updated.emit()


func _update_vars() -> void:
	
	var fps: int = ProjectServer2.project_res.fps
	
	var zoom_base: float
	var zoom_exp: float = ceilf(zoom)
	var zoom_scale_factor: float = zoom_exp - zoom
	
	if zoom >= .5: zoom_base = 2.
	elif zoom >= .25: zoom_base = 1.
	elif zoom >= .125: zoom_base = .5
	else: zoom_base = .25
	
	zoom_factor = pow(zoom_base, zoom_exp)
	
	domain_len = zoom_factor * fps * 10
	domain_step = zoom_factor * fps
	domain_small_step = max(1, zoom_factor * small_step_scaler)
	
	displ_frame_size = timemark_panel.size.x / domain_len * (1. + zoom_scale_factor)
	displ_timemark_size_h = timemark_panel.size.x / 2.


func _update_horizontal_scrollbar() -> void:
	
	var margin_frames: int = margin_size * ProjectServer2.project_res.fps
	
	var farleft: int = get_frame_from_display_pos(.0)
	var farright: int = get_frame_from_display_pos(timemark_panel.size.x)
	var min: int = frame_start - margin_frames - int(250. / displ_frame_size)
	var max: int = frame_end + margin_frames
	var page: int = farright - farleft
	
	h_scrollbar.min_value = min
	h_scrollbar.max_value = max
	h_scrollbar.page = page
	h_scrollbar.value = center - displ_timemark_size_h / displ_frame_size
	
	h_scrollbar.visible = page < max - min


func _update_waveforms_pixelate_scale() -> void:
	var pixel_scale: float
	if zoom > 6.: pixel_scale = 8.
	elif zoom > 4.: pixel_scale = 4.
	elif zoom > 2.: pixel_scale = 2.
	else: pixel_scale = 1.
	MediaServer.WaveformBoxContainer.set_pixelate_scale(pixel_scale)


func get_display_pos_from_frame(frame: int) -> float:
	return displ_timemark_size_h + (frame - center) * displ_frame_size

func get_display_pos_from_cursor() -> float:
	return get_display_pos_from_frame(PlaybackServer.position)

func get_frame_from_display_pos(pos: float) -> int:
	return round((pos - displ_timemark_size_h) / displ_frame_size + center)

func get_frame_from_mouse_pos() -> int:
	return get_frame_from_display_pos(get_local_mouse_position().x)




class TimeMarkPanelContainer extends PanelContainer:
	
	var timeline: TimeLine2
	
	@onready var timemarkers_control: Control = IS.create_empty_control()
	
	var timemarkers: Dictionary[TimeMarkerRes, TimeMarker2]
	
	var displayed_frames: Dictionary[int, float] # {frame: display_pos}
	
	var cursor_is_dragging: bool:
		set(val):
			cursor_is_dragging = val
			timeline.edges_nav_horizontal = val
	
	func _init(_timeline: TimeLine2) -> void:
		timeline = _timeline
		clip_contents = true
	
	func _ready() -> void:
		add_child(timemarkers_control)
		open_project_res(ProjectServer2.project_res)
		ProjectServer2.project_opened.connect(_on_project_server_project_opened)
	
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				cursor_is_dragging = event.is_pressed()
				playback_position_follow_mouse_position()
		elif event is InputEventMouseMotion:
			if cursor_is_dragging:
				playback_position_follow_mouse_position()
	
	func update_timemarkpanel_view() -> void:
		transform_timemarkers()
		queue_redraw()
	
	func _draw() -> void:
		
		var font: Font = IS.LABEL_SETTINGS_MAIN.font
		
		var size_h: Vector2 = size / 2.
		var size_q: Vector2 = size / 4.
		var str_offer: float = size_h.y + font.get_descent(16) + 2.
		
		var center: int = timeline.center
		var domain_h: int = timeline.domain_len / 2
		var domain_step: int  = timeline.domain_step
		var domain_small_step: int = timeline.domain_small_step
		
		var dist_to_abs: int = snappedi(center, domain_step) - center
		
		displayed_frames.clear()
		
		for frame: int in range(-domain_h - domain_small_step, domain_h + domain_small_step, domain_small_step):
			
			frame += center + dist_to_abs
			
			var displ_pos: float = timeline.get_display_pos_from_frame(frame) - 8.
			var displ_size_y: float
			var color: Color
			
			displayed_frames[frame] = displ_pos
			
			if frame % domain_step == 0:
				draw_string(font, Vector2(displ_pos + 10., str_offer), TimeServer.frame_to_timecode(frame))
				displ_size_y = size.y
				color = Color.WEB_GRAY
			else:
				displ_size_y = size_q.y
				color = Color.DIM_GRAY
			
			draw_line(Vector2(displ_pos, .0), Vector2(displ_pos, displ_size_y), color, 2.)
		
		draw_line(Vector2.ZERO, Vector2(size.x, .0), Color.WEB_GRAY, 2.)
		
		var cursor_pos: float = timeline.get_display_pos_from_cursor()
		
		draw_rect(Rect2(Vector2(cursor_pos - 100., .0), Vector2(200., size.y)), Color.LIGHT_GRAY, true)
		var timecode: String = TimeServer.frame_to_timecode(PlaybackServer.position)
		var offset: Vector2 = font.get_string_size(timecode)
		draw_string(font, Vector2(cursor_pos - offset.x / 2., offset.y), timecode, 0, -1, 16, Color.BLACK)
		
		displayed_frames.sort()
	
	func playback_position_follow_mouse_position() -> void:
		PlaybackServer.position = timeline.snap_frame(timeline.get_frame_from_mouse_pos(), true, false)
		timeline.update_timeline_view()
	
	func open_project_res(project_res: ProjectRes) -> void:
		if not project_res:
			return
		
		for tmr: TimeMarkerRes in timemarkers:
			timemarkers[tmr].queue_free()
		timemarkers.clear()
		
		var tmrs: Dictionary[int, TimeMarkerRes] = project_res.timemarkers
		for frame: int in tmrs:
			spawn_timemarker(frame, tmrs[frame])
		
		project_res.timemarker_added.connect(_on_projectres_timemarker_added)
		project_res.timemarker_removed.connect(_on_projectres_timemarker_removed)
		project_res.timemarker_moved.connect(_on_projectres_timemarker_moved)
	
	func spawn_timemarker(frame: int, timemarker_res: TimeMarkerRes) -> void:
		var timemarker:= TimeMarker2.new()
		timemarker.frame = frame
		timemarker.timemarker_res = timemarker_res
		timemarker.custom_minimum_size = Vector2(10., 10.)
		timemarkers_control.add_child(timemarker)
		timemarkers[timemarker_res] = timemarker
		transform_timemarker(frame, timemarker_res)
	
	func free_timemarker(frame: int, timemarker_res: TimeMarkerRes) -> void:
		timemarkers[timemarker_res].queue_free()
		timemarkers.erase(timemarker_res)
	
	func move_timemarker(timemarker_res: TimeMarkerRes, to_frame: int) -> void:
		timemarkers[timemarker_res].frame = to_frame
		transform_timemarker(to_frame, timemarker_res)
	
	func transform_timemarkers() -> void:
		var tmrs: Dictionary[int, TimeMarkerRes] = ProjectServer2.project_res.timemarkers
		for frame: int in tmrs:
			transform_timemarker(frame, tmrs[frame])
	
	func transform_timemarker(frame: int, timemarker_res: TimeMarkerRes) -> void:
		timemarkers[timemarker_res].position.x = timeline.get_display_pos_from_frame(frame) - 8.
	
	func _on_project_server_project_opened(project_res: ProjectRes) -> void:
		open_project_res(project_res)
	
	func _on_projectres_timemarker_added(frame: int, timemarker: TimeMarkerRes) -> void:
		spawn_timemarker(frame, timemarker)
		update_timemarkers_spacial_frames()
	
	func _on_projectres_timemarker_removed(frame: int, timemarker: TimeMarkerRes) -> void:
		free_timemarker(frame, timemarker)
		update_timemarkers_spacial_frames()
	
	func _on_projectres_timemarker_moved(from_frame: int, to_frame: int, timemarker: TimeMarkerRes) -> void:
		move_timemarker(timemarker, to_frame)
		update_timemarkers_spacial_frames()
	
	func update_timemarkers_spacial_frames() -> void:
		timeline.update_timemarkers_spacial_frames()
		timeline.update_spacial_frames()


class LayersSelectContainer extends SelectContainer:
	
	var timeline: TimeLine2
	
	var clips_fordelete: Array[Vector2i]
	
	var clips_menu: Array = [
		#MenuOption.new_line(),
		#MenuOption.new("Group", null, group_clips),
		#MenuOption.new("UnGroup", null, ungroup_clips),
		MenuOption.new_line(),
		MenuOption.new("Enter", null, enter_clip),
		MenuOption.new("Create Parent", null, create_parent),
		MenuOption.new("Reparent", null, reparent_clip),
		MenuOption.new("Parent Up", null, parent_up.bind(1)),
		MenuOption.new("Clear Parents", null, clear_parents),
		MenuOption.new_line(),
		MenuOption.new("Open Graph Editor", null, open_graph_editors),
		MenuOption.new("Close Graph Editor", null, close_graph_editors),
		MenuOption.new_line(),
		MenuOption.new("Save as Global Preset", null, save_presets.bind(true)),
		MenuOption.new("Save as Project Preset", null, save_presets.bind(false)),
		MenuOption.new_line(),
		#MenuOption.new("Replace Media", null, replace_clips),
		MenuOption.new("Reverse Clip", null, reverse_clips),
		MenuOption.new("Extract Audio", null, extract_audio)
	]
	
	func _init(_timeline: TimeLine2) -> void:
		timeline = _timeline
	
	func _ready() -> void:
		super()
		shortcut_node.register_shortcut_quickly(&"enter_clip", enter_clip, [ShortcutNode.new_event_key(Key.KEY_ENTER)])
		shortcut_node.register_shortcut_quickly(&"exit_clip", exit_clip, [ShortcutNode.new_event_key(Key.KEY_BACKSPACE)])
		shortcut_node.register_shortcut_quickly(&"create_parent", create_parent, [ShortcutNode.new_event_key(Key.KEY_P, false, true)])
		shortcut_node.register_shortcut_quickly(&"reparent", reparent_clip, [ShortcutNode.new_event_key(Key.KEY_R, false, true)])
		shortcut_node.register_shortcut_quickly(&"parent_up", parent_up.bind(1), [ShortcutNode.new_event_key(Key.KEY_U, false, true)])
		shortcut_node.register_shortcut_quickly(&"clear_parents", clear_parents, [ShortcutNode.new_event_key(Key.KEY_C, false, true)])
		
		shortcut_node.cond_func = EditorServer.layers_body_shortcut_node_cond_func
	
	func _gui_input(event: InputEvent) -> void:
		super(event)
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if event.is_pressed():
					popup_options_menu()
	
	func _get_port_obj(port_idx: int) -> Object:
		return timeline.get_layer_from_idx(port_idx)
	
	func _request_selection_box_select(port_idx: int, port_obj: Object, idx: int) -> bool:
		return selectbox_globalrect.intersects(port_obj.get_clip(idx).get_global_rect())
	
	func _set_focused(new_val: Vector2i) -> void:
		if has_selectable_val(focused.x, focused.y):
			var latest_clip: MediaServer.ClipPanel = timeline.get_layer_from_idx(focused.x).get_clip(focused.y)
			if latest_clip: latest_clip.select_panel.modulate = Color.WHITE.lerp(latest_clip.get_theme_stylebox(&"panel").bg_color, .5)
		var new_clip: MediaServer.ClipPanel = timeline.get_layer_from_idx(new_val.x).get_clip(new_val.y)
		if new_clip: new_clip.select_panel.modulate = Color.WHITE
		super(new_val)
	
	
	func delete_selected_vals() -> void:
		super()
		timeline.opened_clip_res.remove_clips(clips_fordelete)
		clips_fordelete.clear()
		emit_selected_changed()
	
	func past_selected_vals() -> void:
		super()
		if copied.is_empty():
			return
		
		var clips_forpast: Dictionary[Vector2i, MediaClipRes]
		
		for port_idx: int in copied:
			var port: Dictionary = copied[port_idx]
			
			for idx: int in port:
				var frame: int = idx - copied_start + PlaybackServer.position
				clips_forpast[Vector2i(port_idx, frame)] = port[idx].duplicate_media_res()
		
		timeline.opened_clip_res.add_clips_by_coords(clips_forpast, timeline.overlay_menu.focus_index)
	
	func _delete_val(port_idx: int, idx: int) -> void:
		clips_fordelete.append(Vector2i(port_idx, idx))
	
	func _past_val(port_idx: int, idx: int) -> void:
		pass
	
	#func group_clips() -> void:
		#pass
	#
	#func ungroup_clips() -> void:
		#pass
	
	func enter_clip() -> void:
		if is_val_selected(focused.x, focused.y):
			ProjectServer2.open_clip_res(get_focused_val())
	
	func exit_clip() -> void:
		ProjectServer2.try_exit_clip_res()
	
	func create_parent() -> void:
		var target_frame: int = PlaybackServer.position
		
		var parent_clip_res:= Display2DClipRes.new()
		parent_clip_res.length = 500
		
		var selected_coords: Array[Vector2i] = selected_to_coords()
		var new_children: Dictionary[Vector2i, MediaClipRes] = _dictintint_to_dictvec2i(selected, 0, target_frame, _get_min_indices(selected))
		
		parent_clip_res.add_clips_by_coords(new_children, 0)
		
		timeline.opened_clip_res.remove_clips(selected_coords, false)
		timeline.free_clips(selected_coords)
		
		timeline.opened_clip_res.add_clips(0, target_frame, [parent_clip_res], timeline.overlay_menu.focus_index)
	
	func reparent_clip() -> void:
		
		if not is_focused_exists():
			return
		
		var parent_clip_res: MediaClipRes = get_focused_val()
		
		selected[focused.x].erase(focused.y)
		
		var selected_coords: Array[Vector2i] = selected_to_coords()
		var children: Dictionary[Vector2i, MediaClipRes] = _dictintint_to_dictvec2i(selected, 0, PlaybackServer.position, _get_min_indices(selected))
		
		parent_clip_res.add_clips_by_coords(children)
		timeline.opened_clip_res.remove_clips(selected_coords)
		
		var parent_clip: MediaServer.ClipPanel = timeline.get_layer_from_idx(focused.x).get_clip(focused.y)
		parent_clip.update_has_clips()
		parent_clip.queue_redraw()
	
	func parent_up(times: int) -> void:
		
		if times == 0: return
		if ProjectServer2.opened_clip_res_path.size() <= times: return
		
		var parent_clip_res: MediaClipRes = ProjectServer2.opened_clip_res_path[-times - 1]
		
		var min_indices: Vector2i = _get_min_indices(selected)
		
		var selected_coords: Array[Vector2i] = selected_to_coords()
		var to_up_clips_ress: Dictionary[Vector2i, MediaClipRes] = _dictintint_to_dictvec2i(selected, 0, min_indices.y, min_indices)
		
		parent_clip_res.add_clips_by_coords(to_up_clips_ress)
		timeline.opened_clip_res.remove_clips(selected_coords)
	
	func clear_parents() -> void:
		parent_up(ProjectServer2.opened_clip_res_path.size() - 1)
	
	func open_graph_editors() -> void:
		
		loop_selected_vals({},
			func(port_idx: int, idx: int, info: Dictionary[StringName, Variant]) -> void:
				timeline.get_layer_from_idx(port_idx).get_clip(idx).open_graph_editor()
		)
		update_layers_size()
	
	func close_graph_editors() -> void:
		
		loop_selected_vals({},
			func(port_idx: int, idx: int, info: Dictionary[StringName, Variant]) -> void:
				timeline.get_layer_from_idx(port_idx).get_clip(idx).close_graph_editor()
		)
		update_layers_size()
	
	#func replace_clips() -> void:
		#pass
	
	func reverse_clips() -> void:
		pass
	
	func extract_audio() -> void:
		pass
	
	func save_presets(global: bool) -> void:
		pass
	
	
	func update_layers_size() -> void:
		await get_tree().process_frame
		for layer_idx: int in selected:
			timeline.get_layer_from_idx(layer_idx).update_size()
	
	
	func _get_min_indices(dict: Dictionary[int, Dictionary]) -> Vector2i:
		
		const INT_MAX: int = (1 << 63) - 1
		var min_port_idx: int = INT_MAX
		var min_idx: int = INT_MAX
		
		for port_idx: int in dict:
			var port: Dictionary = dict[port_idx]
			min_port_idx = min(min_port_idx, port_idx)
			for idx: int in port:
				min_idx = min(min_idx, idx)
		
		return Vector2i(min_port_idx, min_idx)
	
	func _dictintint_to_dictvec2i(dict: Dictionary[int, Dictionary], layer_start: int, frame_start: int, min_indices: Vector2i) -> Dictionary[Vector2i, MediaClipRes]:
		var new_dict: Dictionary[Vector2i, MediaClipRes]
		
		var min_layer: int = min_indices.x
		var min_frame: int = min_indices.y
		
		for port_idx: int in dict:
			var port: Dictionary = dict[port_idx]
			var target_layer: int = port_idx - min_layer + layer_start
			for idx: int in port:
				var target_frame: int = idx - min_frame + frame_start
				new_dict[Vector2i(target_layer, target_frame)] = port[idx].duplicate_media_res()
		
		return new_dict


func update_clips_spacial_frames() -> void:
	clips_spacial_frames.clear()
	
	frame_start = opened_clip_res.clip_pos
	frame_end = frame_start + opened_clip_res.length
	
	displ_frame_start = get_display_pos_from_frame(frame_start)
	displ_frame_end = get_display_pos_from_frame(frame_end)
	
	for layer_res: LayerRes in opened_clip_res.layers:
		var clips: Dictionary[int, MediaClipRes] = layer_res.clips
		for frame: int in clips:
			clips_spacial_frames.append(frame)
			clips_spacial_frames.append(frame + clips[frame].length)
	
	clips_spacial_frames.append(frame_start)
	clips_spacial_frames.append(frame_end)
	
	clips_spacial_frames.sort()

func update_timemarkers_spacial_frames() -> void:
	timemarkers_spacial_frames.clear()
	for frame: int in ProjectServer2.project_res.timemarkers:
		timemarkers_spacial_frames.append(frame)
	timemarkers_spacial_frames.sort()

func update_spacial_frames() -> void:
	spacial_frames = clips_spacial_frames + timemarkers_spacial_frames
	spacial_frames.sort()

func update_all_spacial_frames() -> void:
	update_clips_spacial_frames()
	update_timemarkers_spacial_frames()
	update_spacial_frames()

func snap_frame(frame: int, ignore_cursor: bool, ignore_timemarkers: bool, ignore_frames: PackedInt32Array = []) -> int:
	var _dist_to_snap: float = (dist_to_snap * ProjectServer2.project_res.fps) * zoom_factor
	var dist: float = INF
	
	if snap_timemarks_btn.button_pressed:
		var snap_frame: int = snap_with_timemarks(frame)
		var new_dist: int = absi(snap_frame - frame)
		if new_dist < _dist_to_snap:
			frame = snap_frame
	
	if snap_clips_btn.button_pressed:
		var snap_frame: int = snap_with_clips(frame)
		var new_dist: int = absi(snap_frame - frame)
		if new_dist < _dist_to_snap and new_dist < dist:
			dist = new_dist
			frame = snap_frame
	
	if snap_cursor_btn.button_pressed:
		var snap_frame: int = snap_with_cursor_and_timemarkers(frame, ignore_cursor, ignore_timemarkers)
		var new_dist: int = absi(snap_frame - frame)
		if new_dist < _dist_to_snap and new_dist < dist:
			dist = new_dist
			frame = snap_frame
	
	return frame

func snap_with_timemarks(frame: int) -> int:
	var target_frame: int
	var target_dist: float = INF
	var displayed_frames: Dictionary[int, float] = timemark_panel.displayed_frames
	
	for new_frame: int in displayed_frames:
		var dist_to: int = absi(new_frame - frame)
		if dist_to < target_dist:
			target_frame = new_frame
			target_dist = dist_to
	
	return target_frame

func snap_with_clips(frame: int) -> int:
	if clips_spacial_frames.is_empty():
		return frame
	return clips_spacial_frames[ArrHelper.int32_array_find_closest(frame, clips_spacial_frames)]

func snap_with_cursor_and_timemarkers(frame: int, ignore_cursor: bool, ignore_timemarkers: bool) -> int:
	var target_frame: int = frame
	var target_dist: float = INF
	
	if not ignore_timemarkers:
		if timemarkers_spacial_frames:
			var timemarker_target_idx: int = ArrHelper.int32_array_find_closest(frame, timemarkers_spacial_frames)
			target_frame = timemarkers_spacial_frames[timemarker_target_idx]
			target_dist = absi(target_frame - frame)
	
	if not ignore_cursor:
		var dist_to_cursor: int = absi(PlaybackServer.position - frame)
		if dist_to_cursor < target_dist: return PlaybackServer.position
	
	return target_frame

func get_next_spacial_frame(frame: int, step: int) -> int:
	
	if spacial_frames.is_empty():
		return frame
	
	var curr_idx: int = ArrHelper.int32_array_find_leftright(frame, spacial_frames).y
	var target_idx: int = curr_idx
	var target_frame: int = frame
	
	while target_frame == frame:
		target_idx += step
		if target_idx > spacial_frames.size() - 1 and step > 0:
			return spacial_frames[step - 1]
		target_frame = spacial_frames[target_idx]
	
	return target_frame

func open_project_res(project_res: ProjectRes) -> void:
	update_predefined_frames(project_res.fps)
	
	var min_small_step: int
	small_step_scaler = 0
	
	for fps_channel: int in SMALL_STEP_BY_FPS:
		if project_res.fps >= fps_channel:
			min_small_step = SMALL_STEP_BY_FPS[fps_channel]
			break
	
	for frame: int in predefined_frames:
		if frame > min_small_step:
			small_step_scaler = frame
			break

func update_predefined_frames(fps: int) -> void:
	
	predefined_frames = [.25, .5, 1.]
	
	var divs: PackedInt32Array = CustomMath.get_divisors(fps)
	for div: int in divs:
		predefined_frames.append(div)
	
	predefined_frames.append(fps)
	
	const TIME_MULTIPLIER: PackedInt32Array = [2, 5, 10, 30, 60, 120, 300, 600, 1800, 3600, 7200]
	
	for m: int in TIME_MULTIPLIER:
		var step_val: int = fps * m
		if not predefined_frames.has(step_val):
			predefined_frames.append(step_val)
	
	predefined_frames.sort()


func open_clip_res(clip_res: MediaClipRes) -> void:
	
	if opened_clip_res: _disconnect_clip_res(opened_clip_res)
	if not clip_res: return
	
	_connect_clip_res(clip_res)
	opened_clip_res = clip_res
	
	for layer_res: LayerRes in layers:
		layers[layer_res].queue_free()
	layers.clear()
	
	var layers_ress: Array[LayerRes] = clip_res.layers
	for layer_idx: int in layers_ress.size():
		var layer_res: LayerRes = layers_ress[layer_idx]
		var layer_clips: Dictionary[int, MediaClipRes] = layer_res.get_clips()
		var layer: Layer2 = spawn_layer(layer_idx, layer_res)
		for frame: int in layer_clips:
			layer.spawn_clip(frame, layer_clips[frame], false)
	
	var clip_res_path: Array[MediaClipRes] = ProjectServer2.opened_clip_res_path
	var string_path: Array
	for idx: int in range(1, clip_res_path.size()):
		var path_clip_res: MediaClipRes = clip_res_path[idx]
		string_path.append(path_clip_res.get_display_name())
	clip_path_ctrlr.update(string_path)
	
	sort_layers()
	update_layers_clips(true)
	update_when_clips_changed()

func _disconnect_clip_res(clip_res: MediaClipRes) -> void:
	clip_res.layer_added.disconnect(_on_clip_res_layer_added)
	clip_res.layer_removed.disconnect(_on_clip_res_layer_removed)
	clip_res.layer_moved.disconnect(_on_clip_res_layer_moved)
	clip_res.clips_added.disconnect(_on_clip_res_clips_added)
	clip_res.clips_removed.disconnect(_on_clip_res_clips_removed)
	clip_res.clips_moved.disconnect(_on_clip_res_clips_moved)
	clip_res.clips_updated.disconnect(_on_clip_res_clips_updated)

func _connect_clip_res(clip_res: MediaClipRes) -> void:
	clip_res.layer_added.connect(_on_clip_res_layer_added)
	clip_res.layer_removed.connect(_on_clip_res_layer_removed)
	clip_res.layer_moved.connect(_on_clip_res_layer_moved)
	clip_res.clips_added.connect(_on_clip_res_clips_added)
	clip_res.clips_removed.connect(_on_clip_res_clips_removed)
	clip_res.clips_moved.connect(_on_clip_res_clips_moved)
	clip_res.clips_updated.connect(_on_clip_res_clips_updated)


func get_layer_from_idx(layer_idx: int) -> Layer2:
	return get_layer(opened_clip_res.get_layer(layer_idx))

func get_layer(layer_res: LayerRes) -> Layer2:
	return layers[layer_res]

func spawn_layer(layer_idx: int, layer_res: LayerRes) -> Layer2:
	var layer: Layer2 = Layer2.new()
	layer.layer_res = layer_res
	layer.layer_idx = layer_idx
	layers_cont.add_child(layer)
	layers[layer_res] = layer
	return layer

func free_layer(layer_res: LayerRes) -> void:
	layers[layer_res].queue_free()
	layers.erase(layer_res)
	sort_layers()

func is_layer_hidden(layer: Layer2) -> bool:
	return not get_global_rect().intersects(layer.get_global_rect())

func sort_layers() -> void:
	
	layers_body.clear_selectable_ports()
	layers_body.emit_selected_changed()
	
	var layers_ress: Array[LayerRes] = opened_clip_res.layers
	var layers_size: int = layers_ress.size()
	
	for layer_idx: int in layers_size:
		var layer_res: LayerRes = layers_ress[layer_idx]
		
		var layer: Layer2 = layers[layer_res]
		layer.layer_idx = layer_idx
		
		layers_cont.move_child(layer, layers_size - layer_idx - 1)
		layer.update_customization()
		
		layers_body.add_selectable_port(layer_idx, layer_res.get_clips())
	
	layers_cont.move_child(margin_control, layers_size)

func update_layers_clips(force_update: bool = false) -> void:
	var layer_skip_cond: Callable
	if force_update: layer_skip_cond = func(layer: Layer2) -> bool: return false
	else: layer_skip_cond = func(layer: Layer2) -> bool: return is_layer_hidden(layer)
	
	var layers_ress: Array[LayerRes] = opened_clip_res.layers
	
	for idx: int in layers_ress.size():
		var layer: Layer2 = get_layer_from_idx(idx)
		if layer_skip_cond.call(layer):
			continue
		layer.update_clips(self)

func update_layers_clips_selection() -> void:
	var layers_ress: Array[LayerRes] = opened_clip_res.layers
	var selected: Dictionary[int, Dictionary] = layers_body.selected
	for idx: int in layers_ress.size():
		get_layer_from_idx(idx).update_clips_selection(selected[idx] if selected.has(idx) else {})

func update_layers_customization() -> void:
	var layers_ress: Array[LayerRes] = opened_clip_res.layers
	for idx: int in layers_ress.size():
		get_layer_from_idx(idx).update_customization()

func update_when_clips_changed() -> void:
	await get_tree().process_frame
	update_layers_clips()
	update_layers_clips_selection()
	update_clips_spacial_frames()
	update_spacial_frames()
	_update_horizontal_scrollbar()


func spawn_clips(clips: Dictionary[Vector2i, MediaClipRes]) -> void:
	for coord: Vector2i in clips:
		var clip_res: MediaClipRes = clips[coord]
		var layer: Layer2 = get_layer_from_idx(coord.x)
		layer.spawn_clip(coord.y, clip_res, false)

func free_clips(clips_coords: Array[Vector2i]) -> void:
	for coord: Vector2i in clips_coords:
		var layer: Layer2 = get_layer_from_idx(coord.x)
		if layer.has_clip(coord.y):
			layer.free_clip(coord.y)

func update_clips(clips_coords: Array[Vector2i]) -> void:
	for coord: Vector2i in clips_coords:
		get_layer_from_idx(coord.x).update_clip_ui(coord.y)


func _on_mode_btn_selected_option_changed(id: int, option: MenuOption) -> void:
	match id:
		0: body.mouse_default_cursor_shape = Control.CURSOR_ARROW
		1: body.mouse_default_cursor_shape = Control.CURSOR_IBEAM
		2: body.mouse_default_cursor_shape = Control.CURSOR_HSIZE

func _on_edit_multiple_btn_selected_option_changed(id: int, option: MenuOption) -> void:
	pass

func _on_add_layer_btn_pressed() -> void:
	await get_tree().process_frame
	opened_clip_res.add_layer(opened_clip_res.layers.size())

func _on_marker_btn_pressed() -> void:
	ProjectServer2.project_res.add_timemarker(PlaybackServer.position)

func _on_clip_path_ctrlr_undo_requested(undo_times: int) -> void:
	ProjectServer2.try_exit_clip_res(undo_times)

func _on_center_btn_pressed() -> void:
	PlaybackServer.position = 0
	navigate_horizontal_to(0)
	update_timeline_view()

func _on_scroll_cont_scroll_bar_scrolling() -> void:
	update_timeline_view()

func _on_h_scrollbar_scrolling() -> void:
	center = h_scrollbar.value + displ_timemark_size_h / displ_frame_size
	update_timeline_view()

func _on_project_server_project_opened(project_res: ProjectRes) -> void:
	open_project_res(project_res)

func _on_project_server_opened_clip_res_changed(old_one: MediaClipRes, new_one: MediaClipRes) -> void:
	open_clip_res(new_one)

func _on_clip_res_layer_added(layer_idx: int, layer: LayerRes) -> void:
	spawn_layer(layer_idx, layer)
	sort_layers()

func _on_clip_res_layer_removed(layer_idx: int, layer: LayerRes) -> void:
	free_layer(layer)

func _on_clip_res_layer_moved(from_idx: int, to_idx: int, layer: LayerRes) -> void:
	sort_layers()

func _on_clip_res_clips_added(clips: Dictionary[Vector2i, MediaClipRes]) -> void:
	spawn_clips(clips)
	update_when_clips_changed()

func _on_clip_res_clips_removed(clips_coords: Array[Vector2i]) -> void:
	free_clips(clips_coords)
	update_when_clips_changed()

func _on_clip_res_clips_moved(from_coords: Array[Vector2i], to: Dictionary[Vector2i, MediaClipRes]) -> void:
	free_clips(from_coords)
	spawn_clips(to)
	update_when_clips_changed()

func _on_clip_res_clips_updated(coords: Array[Vector2i]) -> void:
	update_clips(coords)



