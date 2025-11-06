class_name Layer extends DrawableRect

@export var index: int = 0:
	set(val):
		index = val
		ProjectServer.make_layer_absolute(index)

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

func _init(_index: int = 0) -> void:
	index = _index

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
	hide_button = IS.create_texture_button(texture_show, null, null, true)
	mute_button = IS.create_texture_button(texture_unmute, null, null, true)
	more_button = IS.create_texture_button(texture_more)
	
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	IS.add_childs(container, [
		IS.create_empty_control(),
		custom_color_rect,
		lock_button,
		layer_label,
		hide_button,
		mute_button,
		more_button,
		IS.create_empty_control()
	])
	side_rect.add_child(container)
	add_child(side_rect)
	
	# Connections
	ProjectServer.media_clips_moved.connect(on_media_clips_moved)
	ProjectServer.media_clips_changed.connect(on_media_clips_changed)
	ProjectServer.layer_changed.connect(on_layer_changed)
	
	EditorServer.time_line.timeline_view_changed.connect(update)
	
	lock_button.pressed.connect(on_lock_button_pressed)
	hide_button.pressed.connect(on_hide_button_pressed)
	mute_button.pressed.connect(on_mute_button_pressed)
	more_button.pressed.connect(on_more_button_pressed)
	
	# Update
	update_customization_ui()

func _gui_input(event: InputEvent) -> void:
	
	#if EditorServer.media_clips_focused:
		#return
	
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_RIGHT:
			#if event.is_pressed(): press_pos = event.position
			#elif press_pos.distance_to(event.position) <= 5.0:
				#var menu = IS.create_popuped_menu([MenuOption.new("Past")])
				#get_tree().get_current_scene().add_child(menu)
				#menu.popup()
	
	pass

func _draw() -> void:
	var is_locked: bool = ProjectServer.get_layer_lock(index)
	var is_hidden: bool = ProjectServer.get_layer_hide(index)
	var is_muted: bool = ProjectServer.get_layer_mute(index)
	lock_button.change_button_pressed(is_locked)
	hide_button.change_button_pressed(is_hidden)
	mute_button.change_button_pressed(is_muted)
	if is_locked:
		var dist_between: float = 30.0
		for time: int in size.x / dist_between:
			var x_pos: float = time * dist_between
			draw_line(Vector2(x_pos + 50, -5), Vector2(x_pos, curr_y_size + 5), Color(Color.YELLOW, .2), 10.0)
	super()


# Process Functions
# ---------------------------------------------------

func loop_displayed_media_clips(method: Callable) -> void:
	for frame_in: int in displayed_media_clips.keys():
		var info: Dictionary = displayed_media_clips[frame_in]
		method.call(frame_in, info)

func displayed_media_clips_clear() -> void:
	loop_displayed_media_clips(func(frame_in: int, info: Dictionary) -> void:
		info.clip.queue_free()
	)
	displayed_media_clips.clear()

func displayed_media_clips_update_expand_buttons() -> void:
	loop_displayed_media_clips(func(frame_in: int, info: Dictionary) -> void:
		(displayed_media_clips[frame_in].clip as MediaClip).update_expand_buttons()
	)


func update() -> void:
	update_size()
	spawn_and_manage_clips()
	clear_removed_clips()

func update_size() -> void:
	var timeline: TimeLine = EditorServer.time_line
	
	var layer_size: float = ProjectServer.get_layer_customization(index).size
	var custom_size: float = .0
	
	for frame_in: int in displayed_media_clips.keys():
		var info: Dictionary = displayed_media_clips[frame_in]
		var curr_custom_size: float = info.custom_size
		if curr_custom_size > custom_size:
			custom_size = curr_custom_size
	
	var result_size: float = max(custom_size if custom_size else layer_size, layer_size)
	curr_y_size = result_size

func spawn_and_manage_clips() -> void:
	var timeline: TimeLine = EditorServer.time_line
	var layer: Dictionary = ProjectServer.get_layer(index)
	
	for frame_in: int in layer.media_clips.keys():
		
		var clip_res = layer.media_clips[frame_in]
		
		var clip: MediaClip
		
		if displayed_media_clips.has(frame_in):
			clip = displayed_media_clips[frame_in].clip
		else:
			clip = MediaClip.new()
			var media_type:= MediaServer.get_media_type_from_path(clip_res.media_resource_path)
			var media_clip_info = MediaServer.media_clip_info[media_type]
			# Setup Clip Informations
			ObjectServer.describe(clip, {
				layer = self,
				type = media_type,
				layer_index = index,
				clip_pos = frame_in,
				clip_res = clip_res
			})
			# Interface Setup
			if media_clip_info.has("control"): clip.set_clip_control(media_clip_info.control.call(clip_res, media_clip_info.style))
			else: clip.set_clip_control(IS.create_clip_basic_control(media_clip_info.default_name, media_clip_info.style))
			# Connections
			clip.selected.connect(on_clip_selected)
			clip.deselected.connect(on_clip_deselected)
			# Instance Clip
			clips_control.add_child(clip)
			displayed_media_clips[frame_in] = {
				"clip": clip,
				"graph_editors": {} as Dictionary[Dictionary, Dictionary],
				"custom_size": .0
			}
		
		var length = clip_res.length
		if clip.is_editing:
			frame_in = clip.edit_frame_in
			length = clip.edit_length
		var display_begin_pos = timeline.get_display_pos_from_frame(frame_in, self)
		var display_end_pos = timeline.get_display_pos_from_frame(frame_in + length, self)
		clip.position = Vector2(display_begin_pos, .0)
		clip.size = Vector2(display_end_pos - display_begin_pos, curr_y_size)

func clear_removed_clips() -> void:
	var removable_frame_in: Array[int]
	var media_clips = ProjectServer.layers[index].media_clips
	
	for frame_in: int in displayed_media_clips:
		var media_clip: MediaClip = displayed_media_clips[frame_in].clip
		if not media_clips.has(frame_in):
			removable_frame_in.append(frame_in)
	
	for frame_in: int in removable_frame_in:
		displayed_media_clips[frame_in].clip.queue_free()
		displayed_media_clips.erase(frame_in)

func update_force_existing() -> void:
	await get_tree().process_frame
	var selected_clips = EditorServer.media_clips_selection_group.get_objects({"layer_index": index}).size()
	force_existing = selected_clips
	#printt("force_existing updated with index:", index, ", force_existing:", force_existing)

func open_graph_editors(frame: int) -> void:
	
	var info: Dictionary = displayed_media_clips[frame]
	var clip: MediaClip = info.clip
	var clip_res: MediaClipRes = clip.clip_res
	var components: Dictionary[String, Array] = clip_res.components
	var graph_editors: Dictionary[Dictionary, Dictionary] = info.graph_editors
	
	var graph_editors_container: BoxContainer = IS.create_box_container(0, true, {})
	var header_rect: ColorRect = IS.create_color_rect(clip.clip_control.get_theme_stylebox("panel").bg_color, {custom_minimum_size = Vector2(.0, 30.0)})
	var margin_container: MarginContainer = IS.create_margin_container(12,2,2,2)
	var name_label: Label = IS.create_label(clip_res.media_resource_path, IS.LABEL_SETTINGS_BOLD, {})
	margin_container.add_child(name_label)
	header_rect.add_child(margin_container)
	graph_editors_container.add_child(header_rect)
	clip.set_graph_editors_container(graph_editors_container)
	clip.move_child(graph_editors_container, 0)
	
	var calculate_custom_size: Callable = func(update_layer: bool = false) -> void:
		await get_tree().process_frame
		
		var custom_size: float = 30.0
		for graph_editor_key: Dictionary in graph_editors:
			var editor_info: Dictionary = graph_editors[graph_editor_key]
			var category: Category = editor_info.graph_editor
			editor_info.is_expanded = category.is_expanded
			custom_size += category.size.y
		info.custom_size = custom_size
		
		if update_layer:
			update()
			#EditorServer.time_line.update_layers()
	
	var hue_scale: float
	
	for section_key: String in components.keys():
		var section_components: Array = components[section_key]
		
		for component: ComponentRes in section_components:
			var animations: Dictionary[UsableRes, Dictionary] = component.animations
			
			for usable_res: UsableRes in animations.keys():
				var usable_res_animations: Dictionary = animations[usable_res]
				
				for property_key: StringName in usable_res_animations.keys():
					var anim_res: AnimationRes = usable_res_animations[property_key]
					var graph_editor_key: Dictionary = {"usable_res": usable_res, "property_key": property_key}
					
					var curr_color: Color = Color.from_hsv(hue_scale, .8, .6)
					var category: Category = IS.create_category(true, component.res_id + ":" + property_key, curr_color, Vector2.ZERO, false)
					var color_rect: ColorRect = IS.create_color_rect(curr_color, {custom_minimum_size = Vector2(.0, 150.0)})
					
					var is_expanded: bool
					if graph_editors.has(graph_editor_key):
						is_expanded = graph_editors[graph_editor_key].is_expanded
						if is_expanded: category.is_expanded = true
					
					category.expand_changed.connect(calculate_custom_size.bind(true))
					
					graph_editors_container.add_child(category)
					category.add_content(color_rect)
					IS.expand(category)
					
					graph_editors[graph_editor_key] = {"graph_editor": category, "is_expanded": is_expanded}
					
					hue_scale += .1
	
	calculate_custom_size.call()

func close_graph_editors(frame: int) -> void:
	var info: Dictionary = displayed_media_clips[frame]
	info.clip.set_graph_editors_container(null)
	info.custom_size = .0

func update_customization_ui() -> void:
	var customization: Dictionary = ProjectServer.get_layer_customization(index)
	layer_label.text = customization.name if customization.name else "Layer %s" % index
	custom_color_rect.color = customization.color
	update()
	displayed_media_clips_update_expand_buttons()


# Layer Tools Functions
# ---------------------------------------------------

func select_all() -> void:
	#var selection_group: SelectionGroupRes = EditorServer.media_clips_selection_group
	#selection_group.add_objects()
	pass

func deselect_all() -> void:
	pass

func delete_all() -> void:
	pass

func popup_move_to() -> void:
	var max_layer_index: int = ProjectServer.layers.size() - 1
	var index_to_controller: FloatController = IS.create_float_edit("index", false, true, index, 0, max_layer_index, 0, .1, 10, true)[1]
	
	var window_container: BoxContainer = WindowManager.popup_accept_window(
		get_window(), Vector2(400.0, 150.0), "Move Layer to", func() -> void:
			move_to(index_to_controller.get_curr_val())
	)
	window_container.add_child(index_to_controller.get_parent())

func move_to(index_to: int) -> void:
	var timeline: TimeLine = EditorServer.time_line
	
	var layer_from: Layer = self
	var layer_to: Layer = timeline.get_layer(index_to)
	
	if not layer_to: return
	
	layer_from.displayed_media_clips_clear()
	layer_to.displayed_media_clips_clear()
	
	ProjectServer.move_layer(index, index_to)
	
	layer_from.update_customization_ui()
	layer_to.update_customization_ui()

func delete() -> void:
	pass

func move_up() -> void:
	move_to(index + 1)

func move_down() -> void:
	move_to(index - 1)

func duplicate_layer() -> void:
	pass

func popup_display_settings() -> void:
	pass

func popup_audio_settings() -> void:
	pass

func popup_customization_settings() -> void:
	
	var main_custom: Dictionary[StringName, Variant] = ProjectServer.get_layer_customization(index).duplicate(true)
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
		Vector2(400.0, 300.0),
		"Layer Customization",
		update_func, cancel_func
	)
	
	IS.add_childs(window_container, [
		custom_name_controller.get_parent(),
		custom_color_controller.get_parent(),
		custom_size_controller.get_parent()
	])


# Connections Functions
# ---------------------------------------------------

func on_media_clips_moved() -> void:
	await get_tree().process_frame
	clear_drawed_entities()

func on_media_clips_changed() -> void:
	update()

func on_layer_changed() -> void:
	queue_redraw()

func on_lock_button_pressed() -> void:
	ProjectServer.set_layer_lock(index, lock_button.button_pressed)

func on_hide_button_pressed() -> void:
	ProjectServer.set_layer_hide(index, hide_button.button_pressed)

func on_mute_button_pressed() -> void:
	ProjectServer.set_layer_mute(index, mute_button.button_pressed)

func on_more_button_pressed() -> void:
	var menu: PopupedMenu = IS.create_popuped_menu([
		MenuOption.new("Select Clips", null, select_all),
		MenuOption.new("Deselect Clips", null, select_all),
		MenuOption.new("Delete Clips", null, delete_all),
		MenuOption.new_line(),
		MenuOption.new("Delete", null, delete),
		MenuOption.new("Move Up", null, move_up),
		MenuOption.new("Move Down", null, move_down),
		MenuOption.new("Move To", null, popup_move_to),
		MenuOption.new("Duplicate", null, duplicate_layer),
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












