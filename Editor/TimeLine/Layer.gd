class_name Layer extends DrawableRect

signal updated()

@export var index: int = 0:
	set(val):
		index = val
		displayed_media_clips_clear()
		if is_node_ready():
			update_customization_ui()

@export var is_root_layer: bool = false

func get_layer_index() -> int:
	return index

func set_layer_index(_index: int) -> void:
	index = _index

@export_group("Theme")
@export_subgroup("Texture")
@export var texture_lock: Texture2D = preload("res://Asset/Icons/padlock.png")
@export var texture_unlock: Texture2D = preload("res://Asset/Icons/padlock-unlock.png")
@export var texture_hide: Texture2D
@export var texture_show: Texture2D = preload("res://Asset/Icons/eye.png")
@export var texture_mute: Texture2D
@export var texture_unmute: Texture2D = preload("res://Asset/Icons/volume.png")
@export var texture_more: Texture2D = preload("res://Asset/Icons/more.png")
@export_group("Constants")
@export var curr_y_size: float:
	set(val):
		curr_y_size = val
		custom_minimum_size.y = val
		if side_rect: side_rect.custom_minimum_size.y = val
@export var side_panel_x_size: float:
	set(val):
		side_panel_x_size = val
		if side_rect: side_rect.custom_minimum_size.x = val

var displayed_media_clips: Dictionary[int, Dictionary]
var force_existing: int

var clips_control: Control = IS.create_empty_control()

var side_rect: ColorRect
var custom_color_rect: ColorRect
var lock_button: TextureButton
var layer_label: Label
var hide_button: TextureButton
var mute_button: TextureButton
var more_button: TextureButton



# Background Called Functions
# ---------------------------------------------------

func _init(_index: int = 0, _is_root_layer: bool = false) -> void:
	index = _index
	is_root_layer = _is_root_layer

func _ready() -> void:
	
	# Base Settings
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Start Clips Container
	add_child(clips_control)
	
	# Start Side Layer Edit
	side_rect = IS.create_color_rect(color.darkened(.3), {custom_minimum_size = Vector2(side_panel_x_size, curr_y_size)})
	var container = IS.create_box_container(10)
	custom_color_rect = IS.create_color_rect(Color(), {custom_minimum_size = Vector2(5.0, .0)})
	lock_button = IS.create_texture_button(texture_unlock, null, null, true)
	layer_label = IS.create_name_label(str("Layer ", index)); layer_label.custom_minimum_size.x = 100.0
	
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	IS.add_children(container, [
		IS.create_empty_control(),
		custom_color_rect,
		lock_button,
		layer_label
	])
	hide_button = IS.create_texture_button(texture_show, null, null, true)
	hide_button.pressed.connect(on_hide_button_pressed)
	container.add_child(hide_button)
	if is_root_layer:
		mute_button = IS.create_texture_button(texture_unmute, null, null, true)
		mute_button.pressed.connect(on_mute_button_pressed)
		container.add_child(mute_button)
	more_button = IS.create_texture_button(texture_more)
	more_button.pressed.connect(on_more_button_pressed)
	container.add_child(more_button)
	container.add_child(IS.create_empty_control())
	
	side_rect.add_child(container)
	add_child(side_rect)
	
	# Connections
	ProjectServer.media_clips_changed.connect(on_media_clips_changed)
	ProjectServer.layers_changed.connect(on_layers_changed)
	
	EditorServer.time_line.timeline_view_changed.connect(update)
	
	lock_button.pressed.connect(on_lock_button_pressed)
	
	# Update
	update_customization_ui()


func _draw() -> void:
	draw_line(Vector2.ZERO, Vector2(size.x, .0), Color(Color.BLACK, .5), 5)
	if ProjectServer.curr_layers.has(index):
		var is_locked: bool = ProjectServer.get_layer_lock(index)
		lock_button.change_button_pressed(is_locked)
		if is_root_layer:
			var is_muted: bool = ProjectServer.get_layer_mute(index)
			mute_button.change_button_pressed(is_muted)
		var is_hidden: bool = ProjectServer.get_layer_hide(index)
		hide_button.change_button_pressed(is_hidden)
		if is_locked:
			var dist_between: float = 30.0
			for time: int in size.x / dist_between:
				var x_pos: float = time * dist_between
				draw_line(Vector2(x_pos + 50, -5), Vector2(x_pos, curr_y_size + 5), Color(Color.YELLOW, .2), 10.0)
	super()


# Process Functions
# ---------------------------------------------------

func get_media_clip(clip_pos: int) -> MediaClip:
	return displayed_media_clips[clip_pos].clip

func has_media_clip(clip_pos: int) -> bool:
	return displayed_media_clips.has(clip_pos)

func reset_media_clip(clip_pos: int, select: bool = true) -> void:
	remove_media_clip(clip_pos)
	spawn_media_clip(clip_pos, ProjectServer.get_layer(index).media_clips[clip_pos], select)

func request_remove_media_clip(clip_pos: int) -> void:
	if displayed_media_clips.has(clip_pos):
		remove_media_clip(clip_pos)

func remove_media_clip(clip_pos: int) -> void:
	var media_clip: MediaClip = get_media_clip(clip_pos)
	media_clip.queue_free()
	displayed_media_clips.erase(clip_pos)

func send_media_clip_expanded_graph_editors(clip_pos: int, expanded_graph_editors: Array[bool]) -> void:
	set_meta(str("f", clip_pos), expanded_graph_editors)

func spawn_media_clip(clip_pos: int, clip_res: MediaClipRes, select_new_clips: bool = true) -> MediaClip:
	var clip: MediaClip
	
	if clip_res is ImportedClipRes:
		clip = ImportedClip.new()
		var clip_type: int = clip_res.type
		clip.type = clip_type
		# Interface Setup
		var clip_panel_id: GDScript = MediaServer.imported_clip_info.get(clip_type).clip_panel
		clip.set_clip_panel(clip_panel_id.new(clip))
	
	elif clip_res is ObjectClipRes:
		clip = ObjectClip.new()
		var clip_panel: MediaServer.ObjectClipPanel = MediaServer.ObjectClipPanel.new(clip)
		clip.set_clip_panel(clip_panel)
	
	# Setup Clip Informations
	ObjectServer.describe(clip, {
		"layer" = self,
		"layer_index" = index,
		"clip_pos" = clip_pos,
		"clip_res" = clip_res
	})
	
	var clip_pos_str = str("f", clip_pos)
	if has_meta(clip_pos_str):
		clip.clip_panel.graph_editors_expanded = get_meta(clip_pos_str)
		clip.open_graph_editor.call_deferred()
		remove_meta(clip_pos_str)
	
	# Connections
	clip.selected.connect(on_clip_selected)
	clip.deselected.connect(on_clip_deselected)
	# Instance Clip
	clips_control.add_child(clip)
	if select_new_clips:
		clip.select(true, false, false, false)
		
	displayed_media_clips[clip_pos] = {&"clip": clip}
	return clip

func select_media_clip(clip_pos: int) -> void:
	if displayed_media_clips.has(clip_pos):
		get_media_clip(clip_pos).select(true, false, false, false)

func set_clips_modulate(new_modulate: Color) -> void:
	clips_control.modulate = new_modulate

func set_clips_modulate_transparent() -> void:
	set_clips_modulate(Color(1.,1.,1.,.3))

func set_clips_modulate_white() -> void:
	set_clips_modulate(Color.WHITE)

func loop_displayed_media_clips(method: Callable) -> void:
	for frame_in: int in displayed_media_clips.keys():
		var info: Dictionary = displayed_media_clips[frame_in]
		method.call(frame_in, info)

func displayed_media_clips_select_all() -> void:
	loop_displayed_media_clips(func(frame_in: int, info: Dictionary) -> void:
		var media_clip: MediaClip = info.clip
		media_clip.select(true, false, false, false)
	)

func displayed_media_clips_deselect_all() -> void:
	loop_displayed_media_clips(func(frame_in: int, info: Dictionary) -> void:
		var media_clip: MediaClip = info.clip
		media_clip.deselect()
	)

func displayed_media_clips_clear() -> void:
	loop_displayed_media_clips(func(frame_in: int, info: Dictionary) -> void:
		info.clip.queue_free()
	)
	displayed_media_clips.clear()

func displayed_media_clips_update_expand_buttons() -> void:
	loop_displayed_media_clips(func(frame_in: int, info: Dictionary) -> void:
		displayed_media_clips[frame_in].clip.update_expand_buttons()
	)

func displayed_media_clips_clip_panel_update_ui_transform() -> void:
	loop_displayed_media_clips(func(frame_in: int, info: Dictionary) -> void:
		displayed_media_clips[frame_in].clip.clip_panel._update_ui_transform()
	)

func displayed_media_clips_set_modulate(new_modulate: Color, media_clips_ignored: Array = []) -> void:
	loop_displayed_media_clips(func(frame_in: int, info: Dictionary) -> void:
		if not media_clips_ignored.has(info.clip):
			displayed_media_clips[frame_in].clip.modulate = new_modulate
	)



func update(select_new_clips: bool = true) -> void:
	update_size.call_deferred()
	spawn_and_manage_clips.call_deferred(select_new_clips)
	clear_removed_clips.call_deferred()

func update_size() -> void:
	var layer_size: float = ProjectServer.get_layer_customization(index).size
	var custom_size: float = .0
	
	for frame_in: int in displayed_media_clips.keys():
		var clip_panel: MediaServer.ClipPanel = displayed_media_clips[frame_in].clip.clip_panel
		if clip_panel.is_graph_editor_opened:
			if clip_panel.custom_height > custom_size:
				custom_size = clip_panel.custom_height
	
	var result_size: float = max(custom_size if custom_size else layer_size, layer_size)
	curr_y_size = result_size

func spawn_and_manage_clips(select_new_clips: bool) -> void:
	var timeline: TimeLine = EditorServer.time_line
	var layer: Dictionary = ProjectServer.get_layer_if(index)
	
	for frame_in: int in layer.media_clips.keys():
		
		var clip_res: MediaClipRes = layer.media_clips[frame_in]
		var clip: MediaClip = null
		
		if displayed_media_clips.has(frame_in):
			clip = get_media_clip(frame_in)
		else:
			clip = spawn_media_clip(frame_in, clip_res, select_new_clips)
		
		var length: int = clip_res.length
		if clip.is_editing:
			frame_in = clip.edit_clip_pos
			length = clip.edit_length
		var display_begin_pos: float = timeline.get_display_pos_from_frame(frame_in, self)
		var display_end_pos: float = timeline.get_display_pos_from_frame(frame_in + length, self)
		clip.position = Vector2(display_begin_pos, .0)
		clip.size = Vector2(display_end_pos - display_begin_pos, curr_y_size)
		clip.clip_panel._update_ui_transform()

func clear_removed_clips() -> void:
	var removable_frame_in: Array[int]
	var media_clips: Dictionary = ProjectServer.get_layer_if(index).media_clips
	
	for frame_in: int in displayed_media_clips:
		var media_clip: MediaClip = displayed_media_clips[frame_in].clip
		if not media_clips.has(frame_in):
			removable_frame_in.append(frame_in)
	
	for frame_in: int in removable_frame_in:
		displayed_media_clips[frame_in].clip.queue_free()
		displayed_media_clips.erase(frame_in)
	
	updated.emit()

func update_force_existing() -> void:
	await get_tree().process_frame
	var selected_clips = EditorServer.media_clips_selection_group.get_selected_objects({"layer_index": index}).size()
	force_existing = selected_clips
	#printt("force_existing updated with index:", index, ", force_existing:", force_existing)

func update_customization_ui() -> void:
	var customization: Dictionary = ProjectServer.get_layer_customization(index)
	layer_label.text = customization.name if customization.name else "Layer %s" % index
	custom_color_rect.color = customization.color
	update(false)
	displayed_media_clips_update_expand_buttons()


# Layer Tools Functions
# ---------------------------------------------------

func select_all() -> void:
	displayed_media_clips_select_all()

func deselect_all() -> void:
	displayed_media_clips_deselect_all()

func delete_all() -> void:
	ProjectServer.clear_layer_media_clips(index)
	update()

func popup_move_to() -> void:
	var max_layer_index: int = ProjectServer.get_curr_layers().size() - 1
	var index_to_controller: FloatController = IS.create_float_edit("index", false, true, index, 0, max_layer_index, 0, .1, 10, true)[1]
	
	var window_container: BoxContainer = WindowManager.popup_accept_window(
		get_window(), Vector2(400.0, 150.0), "Move Layer to", func() -> void:
			move_to(index_to_controller.get_curr_val())
	)
	window_container.add_child(index_to_controller.get_parent())

func move_to(index_to: int) -> void:
	var timeline: TimeLine = EditorServer.time_line
	ProjectServer.move_layer(index, index_to)

func move_up() -> void:
	move_to(index + 1)

func move_down() -> void:
	move_to(index - 1)

func delete() -> void:
	ProjectServer.delete_layer(index)

func popup_display_settings() -> void:
	pass

func popup_audio_settings() -> void:
	pass

func popup_customization_settings() -> void:
	
	var popup_title: Label = IS.create_label(layer_label.text, IS.LABEL_SETTINGS_HEADER)
	var main_custom: Dictionary = ProjectServer.get_layer_customization(index).duplicate(true)
	var custom_name_controller: LineEdit = IS.create_line_edit_edit("Name", "", main_custom.name)[0]
	var custom_color_controller: ColorButton = IS.create_color_edit("Color", main_custom.color)[0]
	var custom_size_controller: FloatController = IS.create_float_edit("Size", false, true, main_custom.size, 35.0, 200.0, 5.0, .1)[1]
	
	custom_color_controller.color_controller_popup_type = 1
	
	var update_func: Callable = func() -> void:
		ProjectServer.set_layer_customization(index,
			custom_name_controller.text,
			custom_color_controller.curr_color,
			custom_size_controller.curr_val
		)
		update_customization_ui()
	
	var cancel_func: Callable = func() -> void:
		ProjectServer.set_layer_customization(index,
		main_custom.name, main_custom.color, main_custom.size
		)
		update_customization_ui()
	
	var controller_update_func: Callable = func(new_val: Variant) -> void: update_func.call()
	custom_name_controller.text_changed.connect(controller_update_func)
	custom_color_controller.color_changed.connect(controller_update_func)
	custom_size_controller.val_changed.connect(controller_update_func)
	
	var window_container: BoxContainer = WindowManager.popup_accept_window(
		get_window(),
		Vector2(400.0, 260.0),
		"Layer Customization",
		update_func, cancel_func
	)
	
	IS.add_children(window_container, [
		popup_title,
		custom_name_controller.get_parent(),
		custom_color_controller.get_parent(),
		custom_size_controller.get_parent()
	])


# Connections Functions
# ---------------------------------------------------

func on_media_clips_changed() -> void:
	update()
	await get_tree().process_frame
	clear_drawn_entities()

func on_layers_changed() -> void:
	displayed_media_clips_clear()
	update_customization_ui()

func on_lock_button_pressed() -> void:
	ProjectServer.set_layer_lock(index, lock_button.button_pressed)

func on_hide_button_pressed() -> void:
	ProjectServer.set_layer_hide(index, hide_button.button_pressed)

func on_mute_button_pressed() -> void:
	ProjectServer.set_layer_mute(index, mute_button.button_pressed)

func on_more_button_pressed() -> void:
	var menu: PopupedMenu = IS.create_popuped_menu([
		MenuOption.new("Select Clips", null, select_all),
		MenuOption.new("Deselect Clips", null, deselect_all),
		MenuOption.new("Delete Clips", null, delete_all),
		MenuOption.new_line(),
		MenuOption.new("Move Up", null, move_up),
		MenuOption.new("Move Down", null, move_down),
		MenuOption.new("Move To", null, popup_move_to),
		MenuOption.new("Delete", null, delete),
		MenuOption.new_line(),
		#MenuOption.new("Layer Display Settings", null, popup_display_settings),
		#MenuOption.new("Layer Audio Settings", null, popup_audio_settings),
		MenuOption.new("Customization", null, popup_customization_settings)
	])
	get_tree().get_current_scene().add_child(menu)
	menu.popup()

func on_clip_selected() -> void:
	update_force_existing()

func on_clip_deselected() -> void:
	update_force_existing()
