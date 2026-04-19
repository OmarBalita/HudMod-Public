class_name Layer2 extends HSplitContainer

@onready var leftside_panel: PanelContainer = IS.create_panel_container(Vector2.ZERO, IS.style_cornerless_panel)
@onready var leftside_margin: MarginContainer = IS.create_margin_container(4, 4, 4, 4)
@onready var leftside_cont: BoxContainer = IS.create_box_container(6)

@onready var custom_color_rect: ColorRect = IS.create_color_rect()
@onready var lock_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/padlock-unlock.png"), null, preload("res://Asset/Icons/padlock.png"), true)
@onready var name_label: Label = IS.create_name_label("")
@onready var hide_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/eye.png"), null, preload("res://Asset/Icons/visible.png"), true)
@onready var mute_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/volume.png"), null, null, true)
@onready var more_btn: TextureButton = IS.create_texture_button(preload("res://Asset/Icons/more.png"))

@onready var clips_panel: ClipsPanelContainer = ClipsPanelContainer.new(self)
@onready var clips_body: Control = Control.new()

static var timeline: TimeLine2

var layer_idx: int
var layer_res: LayerRes: set = _set_layer_res

var clips: Dictionary[int, MediaServer.ClipPanel]
var locked_clips: Dictionary[int, MediaServer.ClipPanel]

func _set_layer_res(val: LayerRes) -> void:
	if layer_res:
		layer_res.lock_changed.disconnect(_on_layer_res_lock_changed)
		layer_res.hidden_changed.disconnect(_on_layer_res_hidden_changed)
		if layer_res is RootLayerRes:
			layer_res.mute_changed.disconnect(_on_layer_res_mute_changed)
	if val:
		val.lock_changed.connect(_on_layer_res_lock_changed)
		val.hidden_changed.connect(_on_layer_res_hidden_changed)
		if val is RootLayerRes:
			val.mute_changed.connect(_on_layer_res_mute_changed)
	layer_res = val

func _ready() -> void:
	
	dragging_enabled = false
	clips_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clips_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	leftside_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	leftside_panel.custom_minimum_size.x = 250.
	custom_color_rect.custom_minimum_size.x = 10.
	IS.expand(name_label, true)
	
	clips_body.clip_contents = true
	
	add_child(leftside_panel)
	leftside_panel.add_child(leftside_margin)
	leftside_margin.add_child(leftside_cont)
	
	leftside_cont.add_child(custom_color_rect)
	leftside_cont.add_child(lock_btn)
	leftside_cont.add_child(name_label)
	leftside_cont.add_child(hide_btn)
	if layer_res is RootLayerRes:
		leftside_cont.add_child(mute_btn)
	leftside_cont.add_child(more_btn)
	
	lock_btn.pressed.connect(_on_lock_btn_pressed)
	hide_btn.pressed.connect(_on_hide_btn_pressed)
	mute_btn.pressed.connect(_on_mute_btn_pressed)
	more_btn.pressed.connect(_on_more_btn_pressed)
	
	add_child(clips_panel)
	clips_panel.add_child(clips_body)


func get_clip(frame: int) -> MediaServer.ClipPanel:
	return clips[frame]

func get_locked_clip(frame: int) -> MediaServer.ClipPanel:
	return locked_clips[frame]

func has_clip(frame: int) -> bool:
	return clips.has(frame)

func spawn_clip(frame: int, clip_res: MediaClipRes, is_selected: bool) -> MediaServer.ClipPanel:
	
	if has_clip(frame):
		free_clip(frame)
	
	var clip: MediaServer.ClipPanel
	var clip_classname_info: Dictionary = MediaServer.object_clip_info[clip_res.get_classname()]
	if clip_classname_info.has(&"clip_panel"):
		clip = clip_classname_info.clip_panel.new(clip_res)
	else:
		clip = MediaServer.ObjectClipPanel.new(clip_res)
	clip.layer_idx = layer_idx
	clip.frame = frame
	clips_body.add_child(clip)
	clip._update_selection(is_selected)
	clips[frame] = clip
	return clip

func free_clip(frame: int) -> void:
	clips[frame].queue_free()
	clips.erase(frame)

func lock_clip(frame: int) -> void:
	if clips.has(frame):
		var clip: MediaServer.ClipPanel = clips[frame]
		locked_clips[frame] = clip
		clips.erase(frame)

func unlock_clip(frame: int) -> void:
	if locked_clips.has(frame):
		var clip: MediaServer.ClipPanel = locked_clips[frame]
		clips[frame] = clip
		locked_clips.erase(frame)

func update_clip_transform(frame: int, clip: MediaServer.ClipPanel) -> void:
	var clip_res: MediaClipRes = clip.clip_res
	
	var displ_begin_pos: float = timeline.get_display_pos_from_frame(frame, clips_body)
	var displ_end_pos: float = timeline.get_display_pos_from_frame(frame + clip_res.length, clips_body)
	
	clip.position.x = displ_begin_pos
	clip.size = Vector2(displ_end_pos - displ_begin_pos, size.y)
	
	clip._update_ui_transform()

func update_clip_ui(frame: int) -> void:
	var clip: MediaServer.ClipPanel = clips[frame]
	update_clip_transform(frame, clip)
	clip._update_ui()

func update_clips_transform() -> void:
	
	for frame: int in clips:
		var clip: MediaServer.ClipPanel = clips[frame]
		update_clip_transform(frame, clip)
	
	clips_panel.queue_redraw()

func update_clips_selection(layer_port_selections: Dictionary) -> void:
	for frame: int in clips:
		clips[frame]._update_selection(layer_port_selections.has(frame))

func update_clips_coords() -> void:
	for frame: int in clips:
		var clip:= clips[frame]
		clip.layer_idx = layer_idx
		clip.frame = frame


func update_customization() -> void:
	name_label.text = "Layer %s" % layer_idx if layer_res.custom_name.is_empty() else layer_res.custom_name
	custom_color_rect.color = layer_res.custom_color
	update_size()

func update_size() -> void:
	
	var target_size: float = layer_res.custom_size
	
	for frame: int in clips:
		var clip: MediaServer.ClipPanel = clips[frame]
		if clip.is_graph_editor_opened:
			target_size = max(target_size, clip.box_container.size.y + 8.)
	
	custom_minimum_size.y = target_size


func select_clips() -> void:
	pass

func deselect_clips() -> void:
	pass

func delete_clips() -> void:
	pass

func move_up() -> void:
	move_to(layer_idx + 1)

func move_down() -> void:
	move_to(layer_idx - 1)

func move_to(target_idx: int) -> void:
	timeline.opened_clip_res.move_layer(layer_idx, target_idx)

func delete() -> void:
	timeline.opened_clip_res.remove_layer(layer_idx)


func popup_move_to() -> void:
	var max_layer_index: int = timeline.opened_clip_res.layers.size()
	var index_to_controller: FloatController = IS.create_float_edit(&"index", layer_idx, 0, max_layer_index - 1, 1, .1, 5, true)[0]
	
	var window_container: BoxContainer = WindowManager.popup_accept_window(
		get_window(), Vector2(400., 150.), "Move Layer to", func() -> void:
			move_to(index_to_controller.get_curr_val())
	)
	window_container.add_child(index_to_controller.get_parent())

func popup_customization() -> void:
	
	var popup_title: Label = IS.create_label(name_label.text, IS.label_settings_header)
	var main_custname: StringName = layer_res.custom_name
	var main_custcolor: Color = layer_res.custom_color
	var main_custsize: int = layer_res.custom_size
	var custom_name_controller: LineEdit = IS.create_string_edit("Name", main_custname)[0]
	var custom_color_controller: ColorButton = IS.create_color_edit("Color", main_custcolor)[0]
	var custom_size_controller: FloatController = IS.create_float_edit("Size", main_custsize, 35, 200, 1, 1, 5, true)[0]
	
	custom_color_controller.color_controller_popup_type = 1
	
	var update_func: Callable = func(name: StringName, color: Color, size: int) -> void:
		layer_res.custom_name = name
		layer_res.custom_color = color
		layer_res.custom_size = size
		update_customization()
	
	var cancel_func: Callable = func() -> void:
		update_func.call(main_custname, main_custcolor, main_custsize)
	
	var controller_update_func: Callable = func(new_val: Variant) -> void:
		update_func.call(custom_name_controller.text, custom_color_controller.curr_color, custom_size_controller.curr_val)
	custom_name_controller.text_changed.connect(controller_update_func)
	custom_color_controller.color_changed.connect(controller_update_func)
	custom_size_controller.val_changed.connect(controller_update_func)
	
	var window_container: BoxContainer = WindowManager.popup_accept_window(
		get_window(),
		Vector2(400., 260.),
		"Layer Customization",
		update_func, cancel_func
	)
	
	IS.add_children(window_container, [
		popup_title,
		custom_name_controller.get_parent(),
		custom_color_controller.get_parent(),
		custom_size_controller.get_parent()
	])


func _on_lock_btn_pressed() -> void:
	layer_res.locked = lock_btn.button_pressed

func _on_hide_btn_pressed() -> void:
	layer_res.hidden = hide_btn.button_pressed

func _on_mute_btn_pressed() -> void:
	layer_res.mute = mute_btn.button_pressed

func _on_more_btn_pressed() -> void:
	IS.popup_menu([
		MenuOption.new("Select Clips", null, select_clips),
		MenuOption.new("Deselect Clips", null, deselect_clips),
		MenuOption.new("Delete Clips", null, delete_clips),
		MenuOption.new_line(),
		MenuOption.new("Move Up", null, move_up),
		MenuOption.new("Move Down", null, move_down),
		MenuOption.new("Move To", null, popup_move_to),
		MenuOption.new("Delete", null, delete),
		MenuOption.new_line(),
		MenuOption.new("Customization", null, popup_customization)
	], more_btn, get_window())


func _on_layer_res_lock_changed(to: bool) -> void:
	timeline.sort_layers()
	clips_panel.update_ui()

func _on_layer_res_hidden_changed(to: bool) -> void:
	pass

func _on_layer_res_mute_changed(to: bool) -> void:
	pass

class ClipsPanelContainer extends PanelContainer:
	
	var owner_as_layer: Layer2
	
	func _init(_owner_as_layer: Layer2) -> void:
		IS.set_base_panel_settings(self, IS.style_cornerless_panel)
		owner_as_layer = _owner_as_layer
		clip_contents = true
	
	func update_ui() -> void:
		modulate.a = .5 if owner_as_layer.layer_res.locked else 1.
		queue_redraw()
	
	func _draw() -> void:
		
		if owner_as_layer.layer_res.locked:
			
			var color:= Color(Color.YELLOW_GREEN, .5)
			
			var line_width: float = 30.
			var line_count: int = int(size.x / line_width)
			
			var up_yoffset: float = -10.
			var bottom_yoffset: float = size.y + 10.
			var bottom_xoffset: float = -(size.y + 20.) * .4
			
			for idx: int in line_count + 4:
				var pos: float = idx * line_width
				draw_line(Vector2(pos, up_yoffset), Vector2(pos + bottom_xoffset, bottom_yoffset), color, 15.)
		
		var timeline: TimeLine2 = EditorServer.time_line2
		var displacement: float = timeline.global_position.x - global_position.x
		var color: Color = Color(Color.BLACK, .2)
		
		var pos_start: float = timeline.get_display_pos_from_frame(timeline.frame_start) + displacement
		var rect2_start: Rect2 = Rect2(Vector2.ZERO, Vector2(pos_start, size.y))
		draw_rect(rect2_start, color)
		
		var pos_end: float = timeline.get_display_pos_from_frame(timeline.frame_end) + displacement
		var rect2_end: Rect2 = Rect2(Vector2(pos_end, .0), Vector2(size.x - pos_end, size.y))
		draw_rect(rect2_end, color)




