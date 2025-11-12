class_name Player extends EditorRect


signal curr_frame_changed(new_frame: int)


# ---------------------------------------------------
# Editor Global Variables

@export var draw_editor: DrawEdit = DrawEdit.new()
@export var draw_editor_control: DrawEditControl = DrawEditControl.new()

@export_group("Theme")
@export_subgroup("Texture")
@export var texture_play: Texture2D = preload("res://Asset/Icons/play-button-arrowhead.png")
@export var texture_replay: Texture2D = preload("res://Asset/Icons/reset.png")
@export var texture_pause: Texture2D = preload("res://Asset/Icons/pause.png")
@export var texture_ratio: Texture2D = preload("res://Asset/Icons/aspect-ratio.png")
@export var texture_full_screen: Texture2D = preload("res://Asset/Icons/expand.png")
@export var texture_cancel_full_screen: Texture2D = preload("res://Asset/Icons/cancel-expand.png")
@export var texture_more: Texture2D = preload("res://Asset/Icons/more.png")


# RealTime Variables

var curr_frame: int:
	set(val):
		curr_frame = val
		update_timecode()
		time_slider.slider_controller.set_curr_val_manually(val)
		update_object_editor()


var is_full_screen: bool:
	set(val):
		is_full_screen = val
		
		if val:
			flex_view_control.reparent(get_tree().get_current_scene())
			flex_view_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			get_window().mode = Window.MODE_FULLSCREEN
		else:
			flex_view_control.reparent(screen_options_parent)
			screen_options_parent.move_child(flex_view_control, 0)
			get_window().mode = Window.MODE_MAXIMIZED
		
		update_ui()

# RealTime Nodes

var tweener: TweenerComponent = TweenerComponent.new()

var screen_options_parent: SplitContainer

var flex_view_control: FlexViewportControl
var viewport: SubViewport

var options_container: BoxContainer
var play_button: TextureButton
var replay_button: TextureButton
var time_code_label: Label
var max_time_label: Label
var full_screen_button: TextureButton
var ratio_button: TextureButton
var more_button: TextureButton

var slider_panel: PanelContainer
var slider_time_code_label: Label
var time_slider: SliderControl
var cancel_full_screen_button: TextureButton

var curr_object_editor: Control:
	set(val):
		curr_object_editor = val
		if val:
			hide_slider_panel()
		var has_object_editor: bool = curr_object_editor == null
		options_container.visible = has_object_editor
		flex_view_control.enabled = has_object_editor



# ---------------------------------------------------
# Background Called Functions

func _ready() -> void:
	super()
	
	# Describe Player
	_ready_ui()
	
	# Connections
	
	EditorServer.media_clips_selection_group.selected_objects_changed.connect(on_media_clips_selection_selected_objects_changed)
	EditorServer.time_line.curr_frame_changed.connect(on_timeline_curr_frame_changed)
	
	play_button.pressed.connect(on_play_button_pressed)
	replay_button.pressed.connect(on_replay_button_pressed)
	full_screen_button.pressed.connect(on_full_screen_button_pressed)
	ratio_button.pressed.connect(on_ratio_button_pressed)
	more_button.pressed.connect(on_more_button_pressed)
	
	time_slider.slider_controller.val_changed.connect(on_time_slider_val_changed)
	time_slider.slider_controller.grab_finished.connect(on_time_slider_grab_finished)
	cancel_full_screen_button.pressed.connect(on_cancel_full_screen_button_pressed)
	
	flex_view_control.focus_changed.connect(on_flex_view_focus_changed)
	
	# Update
	update_ui()


func _ready_ui() -> void:
	add_child(tweener)
	
	screen_options_parent = IS.create_split_container(1, true)
	flex_view_control = FlexViewportControl.new()
	ObjectServer.describe(flex_view_control, {
		size_flags_vertical = Control.SIZE_EXPAND_FILL,
		draw_focus = false,
		mouse_entering_calculation = false,
		rect_calculation = true
	})
	var view_container = IS.create_viewport_container({size_flags_vertical = Control.SIZE_EXPAND_FILL})
	options_container = IS.create_box_container(10, false,
	{"custom_minimum_size": Vector2(.0, 50.0), "alignment": BoxContainer.ALIGNMENT_CENTER})
	var time_panel = IS.create_panel_container(Vector2(300, 0))
	var time_container = IS.create_box_container()
	
	viewport = SubViewport.new()
	view_container.add_child(viewport)
	flex_view_control.add_child(view_container)
	viewport.size = ProjectServer.resolution
	flex_view_control.viewport_container = view_container
	
	play_button = IS.create_texture_button(texture_play, null, texture_pause, true)
	play_button.accent_color = play_button.normal_color
	replay_button = IS.create_texture_button(texture_replay, null, null, true)
	time_code_label = IS.create_label("", IS.LABEL_SETTINGS_BOLD)
	max_time_label = IS.create_label("")
	ratio_button = IS.create_texture_button(texture_ratio)
	full_screen_button = IS.create_texture_button(texture_full_screen)
	more_button = IS.create_texture_button(texture_more)
	
	time_container.add_child(time_code_label)
	#time_container.add_child(IS.create_v_line_panel(15))
	time_container.add_child(max_time_label)
	time_panel.add_child(time_container)
	
	IS.add_childs(options_container, [
		IS.create_empty_control(),
		play_button,
		replay_button,
		IS.create_v_line_panel(),
		time_panel,
		IS.create_empty_control(10, 10, {size_flags_horizontal = Control.SIZE_EXPAND_FILL}),
		full_screen_button,
		IS.create_v_line_panel(),
		ratio_button,
		more_button,
		IS.create_empty_control()
	])
	
	screen_options_parent.add_child(flex_view_control)
	screen_options_parent.add_child(options_container)
	body.add_child(screen_options_parent)
	
	# Objects Editors
	draw_editor_control.draw_edit = draw_editor
	
	viewport.add_child(draw_editor)
	flex_view_control.add_child(draw_editor_control)
	
	draw_editor_control.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	draw_editor_control.set_enabling(false)
	
	# Time Slider
	slider_panel = IS.create_panel_container(Vector2(.0, 60.0), load("res://UI&UX/RangeBlack.tres"))
	var slider_margin = IS.create_margin_container(20,20,20,20)
	var slider_box = IS.create_box_container()
	
	slider_time_code_label = IS.create_label("")
	time_slider = IS.create_slider_control(curr_frame, 0, ProjectServer.default_length, 1)
	IS.expand(time_slider)
	ObjectServer.describe(time_slider.slider_controller, {
		rounded_corners = false,
		bg_color = Color(Color.GRAY, .2),
		grabber_main_color = IS.COLOR_ACCENT_BLUE.lightened(.2)
	})
	cancel_full_screen_button = IS.create_texture_button(texture_cancel_full_screen)
	
	slider_box.add_child(slider_time_code_label)
	slider_box.add_child(time_slider)
	slider_box.add_child(cancel_full_screen_button)
	
	slider_margin.add_child(slider_box)
	slider_panel.add_child(slider_margin)
	flex_view_control.add_child(slider_panel)
	
	await get_tree().process_frame
	slider_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	slider_panel.modulate.a = .0


func get_curr_frame() -> int:
	return curr_frame

func set_curr_frame(new_frame: int) -> void:
	curr_frame = new_frame

func get_is_full_screen() -> bool:
	return is_full_screen

func set_is_full_screen(it_is: bool) -> void:
	is_full_screen = it_is

func show_slider_panel() -> void:
	if curr_object_editor: return
	slider_panel.show()
	tweener.play(slider_panel, "modulate:a", [1.0], [.1])

func hide_slider_panel() -> void:
	tweener.play(slider_panel, "modulate:a", [.0], [.1])
	var tween = tweener.tween
	await tween.finished
	if tween == tweener.tween:
		slider_panel.hide()

func update_ui() -> void:
	slider_time_code_label.visible = is_full_screen
	cancel_full_screen_button.visible = is_full_screen
	time_slider.slider_controller.max_val = ProjectServer.curr_length
	update_timecode()

func update_timecode() -> void:
	var curr_frame_timecode:= TimeServer.frame_to_timecode(curr_frame)
	var video_length_timecode:= TimeServer.frame_to_timecode(ProjectServer.curr_length)
	time_code_label.set_text(curr_frame_timecode)
	max_time_label.set_text(video_length_timecode)
	slider_time_code_label.set_text(curr_frame_timecode + " / " + video_length_timecode)

func update_object_editor() -> void:
	var focus = EditorServer.media_clips_selection_group.focused
	if focus:
		var focus_metadata: Dictionary = focus.metadata
		var object: Node = Scene.get_scene_node(focus_metadata.layer_index)
		
		var object_editor: Control
		
		if object is GDDraw:
			draw_editor.draw_node = object
			object_editor = draw_editor_control
		
		var is_frame_entered_media: bool = ProjectServer.is_frame_on_media(curr_frame, focus_metadata.clip_pos, focus_metadata.clip_res.length)
		if object_editor:
			object_editor.set_enabling(is_frame_entered_media)
			curr_object_editor = object_editor
		else:
			disable_curr_object_editor()
	else:
		disable_curr_object_editor()


func disable_curr_object_editor() -> void:
	if curr_object_editor:
		curr_object_editor.set_enabling(false)
		curr_object_editor = null



func on_media_clips_selection_selected_objects_changed() -> void:
	update_object_editor()

func on_timeline_curr_frame_changed(new_frame: int) -> void:
	set_curr_frame(new_frame)

func on_play_button_pressed() -> void:
	var timeline: TimeLine = EditorServer.time_line
	if play_button.button_pressed:
		timeline.play()
	else:
		timeline.stop()

func on_replay_button_pressed() -> void:
	EditorServer.editor_settings.is_replay = replay_button.button_pressed

func on_full_screen_button_pressed() -> void:
	set_is_full_screen(true)

func on_ratio_button_pressed() -> void:
	pass

func on_more_button_pressed() -> void:
	pass

func on_time_slider_val_changed(new_val: float) -> void:
	curr_frame = new_val
	EditorServer.set_frame(new_val)
	curr_frame_changed.emit(new_val)

func on_time_slider_grab_finished() -> void:
	if not flex_view_control.is_focus:
		hide_slider_panel()

func on_cancel_full_screen_button_pressed() -> void:
	set_is_full_screen(false)

func on_flex_view_focus_changed(is_focus: bool) -> void:
	if is_focus: show_slider_panel()
	elif not time_slider.slider_controller.is_grab:
		hide_slider_panel()











