class_name Layer extends DrawableRect


@export_group("Theme")
@export_subgroup("Texture")
@export var texture_lock: Texture2D = preload("res://Asset/Icons/padlock.png")
@export var texture_unlock: Texture2D = preload("res://Asset/Icons/padlock-unlock.png")
@export var texture_hide: Texture2D
@export var texture_show: Texture2D = preload("res://Asset/Icons/eye.png")
@export var texture_mute: Texture2D
@export var texture_unmute: Texture2D = preload("res://Asset/Icons/volume.png")
@export var texture_more: Texture2D = preload("res://Asset/Icons/more.png")


var index = 0

var displayed_media_clips: Dictionary
var force_existing: int

var clips_control: Control

var side_rect: ColorRect
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
	clips_control = InterfaceServer.create_empty_control()
	add_child(clips_control)
	
	# Start Side Layer Edit
	side_rect = InterfaceServer.create_color_rect(color.darkened(.3), {custom_minimum_size = Vector2(300.0, size.y)})
	var container = InterfaceServer.create_box_container()
	lock_button = InterfaceServer.create_texture_button(texture_unlock, null, null, true)
	layer_label = InterfaceServer.create_label(str("Layer ", index)); layer_label.custom_minimum_size.x = 100.0
	hide_button = InterfaceServer.create_texture_button(texture_show, null, null, true)
	mute_button = InterfaceServer.create_texture_button(texture_unmute, null, null, true)
	more_button = InterfaceServer.create_texture_button(texture_more)
	
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_child(InterfaceServer.create_empty_control())
	container.add_child(lock_button)
	container.add_child(layer_label)
	container.add_child(hide_button)
	container.add_child(mute_button)
	container.add_child(more_button)
	container.add_child(InterfaceServer.create_empty_control())
	side_rect.add_child(container)
	add_child(side_rect)
	
	# Connections
	ProjectServer.media_clips_changed.connect(on_media_clips_changed)
	ProjectServer.layer_changed.connect(on_layer_changed)
	
	EditorServer.time_line.timeline_view_changed.connect(update)
	
	lock_button.pressed.connect(on_lock_button_pressed)
	hide_button.pressed.connect(on_hide_button_pressed)
	mute_button.pressed.connect(on_mute_button_pressed)
	more_button.pressed.connect(on_more_button_pressed)
	
	# Update
	update()


var press_pos: Vector2

func _gui_input(event: InputEvent) -> void:
	
	if EditorServer.media_clips_focused:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.is_pressed(): press_pos = event.position
			elif press_pos.distance_to(event.position) <= 5.0:
				var menu = InterfaceServer.create_popuped_menu([MenuOption.new("Past")])
				get_tree().get_current_scene().add_child(menu)
				menu.popup()



func _draw() -> void:
	var is_locked = ProjectServer.get_layer_lock(index)
	var is_hidden = ProjectServer.get_layer_hide(index)
	var is_muted = ProjectServer.get_layer_mute(index)
	lock_button.change_button_pressed(is_locked)
	hide_button.change_button_pressed(is_hidden)
	mute_button.change_button_pressed(is_muted)
	if is_locked:
		var dist_between = 30
		for time in size.x / dist_between:
			var x_pos = time * dist_between
			draw_line(Vector2(x_pos + 50, -5), Vector2(x_pos, size.y + 5), Color(Color.YELLOW, .2), 10.0)
	super()




# Process Functions
# ---------------------------------------------------


func update() -> void:
	
	var timeline = EditorServer.time_line
	
	var layer = ProjectServer.make_layer_absolute(index)
	
	for frame_in in layer.media_clips.keys():
		
		var clip_res = layer.media_clips[frame_in]
		
		var clip: MediaClip
		
		if displayed_media_clips.has(frame_in):
			clip = displayed_media_clips[frame_in]
		else:
			clip = MediaClip.new()
			var media_type = MediaServer.get_media_type_from_path(clip_res.media_resource_path)
			var media_clip_info = MediaServer.media_clip_info[media_type]
			# Setup Clip Informations
			clip.layer = self
			clip.type = media_type
			clip.layer_index = index
			clip.clip_pos = frame_in
			clip.clip_res = clip_res
			# Interface Setup
			clip.color = media_clip_info.bg_color
			clip.add_child(media_clip_info.control.call(clip_res))
			# Connections
			clip.selected.connect(on_clip_selected)
			clip.deselected.connect(on_clip_deselected)
			# Instance Clip
			clips_control.add_child(clip)
			displayed_media_clips[frame_in] = clip
		
		var length = clip_res.length
		if clip.is_editing:
			frame_in = clip.edit_frame_in
			length = clip.edit_length
		var display_begin_pos = timeline.get_display_pos_from_frame(frame_in, self)
		var display_end_pos = timeline.get_display_pos_from_frame(frame_in + length, self)
		clip.position = Vector2(display_begin_pos, .0)
		clip.size = Vector2(display_end_pos - display_begin_pos, size.y)
	
	clear_removed_clips()



func clear_removed_clips() -> void:
	var removable_frame_in: Array[int]
	var media_clips = ProjectServer.layers[index].media_clips
	
	for frame_in in displayed_media_clips:
		var media_clip = displayed_media_clips[frame_in]
		if not media_clips.has(frame_in):
			removable_frame_in.append(frame_in)
	
	for frame_in in removable_frame_in:
			displayed_media_clips[frame_in].queue_free()
			displayed_media_clips.erase(frame_in)


func update_force_existing() -> void:
	await get_tree().process_frame
	var selected_clips = EditorServer.media_clips_selection_group.get_objects({"layer_index": index}).size()
	force_existing = selected_clips
	#printt("force_existing updated with index:", index, ", force_existing:", force_existing)






# Connections Functions
# ---------------------------------------------------

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
	var menu = InterfaceServer.create_popuped_menu([
		MenuOption.new("Move Up"),
		MenuOption.new("Move Down"),
		MenuOption.new("Duplicate Layer"),
		MenuOption.new_line(),
		MenuOption.new("Layer Display Settings"),
		MenuOption.new("Layer Audio Settings"),
		MenuOption.new("Customization")
	])
	get_tree().get_current_scene().add_child(menu)
	menu.popup()

func on_clip_selected() -> void:
	update_force_existing()

func on_clip_deselected() -> void:
	update_force_existing()

















