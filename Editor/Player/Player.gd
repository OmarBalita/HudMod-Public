class_name Player extends EditorControl

signal curr_frame_changed(new_frame: int)

# ---------------------------------------------------
# Editor Global Variables

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

var is_full_screen: bool:
	set(val):
		is_full_screen = val
		
		if val:
			if header_panel.windowed:
				header_panel.target_to_layout()
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

var volume_control: VolumeControl = VolumeControl.new()

var full_screen_button: TextureButton
var ratio_button: TextureButton
var more_button: TextureButton

var slider_panel: PanelContainer
var slider_time_code_label: Label
var cancel_full_screen_button: TextureButton


# ---------------------------------------------------
# Background Called Functions

func _ready_editor() -> void:
	
	_ready_ui()
	
	PlaybackServer.played.connect(_on_playback_server_played)
	PlaybackServer.stopped.connect(_on_playback_server_stopped)
	PlaybackServer.position_changed.connect(_on_playback_server_position_changed)
	
	play_button.pressed.connect(_on_play_button_pressed)
	replay_button.pressed.connect(_on_replay_button_pressed)
	full_screen_button.pressed.connect(_on_full_screen_button_pressed)
	ratio_button.pressed.connect(_on_ratio_button_pressed)
	more_button.pressed.connect(_on_more_button_pressed)
	
	cancel_full_screen_button.pressed.connect(_on_cancel_full_screen_button_pressed)
	
	# Update
	update_ui()


func _ready_ui() -> void:
	add_child(tweener)
	
	var header_box_container: BoxContainer = IS.create_box_container(12, false, {})
	var official_logo_button: Button = IS.create_button("HudMod", load("res://Asset/Icons/App/logo2_bg.png"), false, false, {expand_icon = true, custom_minimum_size = Vector2(120.0, .0)})
	header_box_container.add_child(official_logo_button)
	header.add_child(header_box_container)
	
	screen_options_parent = IS.create_split_container(1, true)
	flex_view_control = FlexViewportControl.new()
	ObjectServer.describe(flex_view_control, {
		size_flags_vertical = Control.SIZE_EXPAND_FILL,
		draw_focus = false,
	})
	var view_container = IS.create_viewport_container({size_flags_vertical = Control.SIZE_EXPAND_FILL})
	options_container = IS.create_box_container(10, false,
	{"custom_minimum_size": Vector2(.0, 50.0), "alignment": BoxContainer.ALIGNMENT_CENTER})
	var time_panel = IS.create_panel_container(Vector2(300, 0))
	var time_container = IS.create_box_container()
	
	viewport = SubViewport.new()
	viewport.audio_listener_enable_2d = true
	view_container.add_child(viewport)
	flex_view_control.add_child(view_container)
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
	time_container.add_child(max_time_label)
	time_panel.add_child(time_container)
	
	IS.add_children(options_container, [
		IS.create_empty_control(),
		play_button,
		replay_button,
		IS.create_v_line_panel(),
		time_panel,
		volume_control,
		full_screen_button,
		IS.create_v_line_panel(),
		ratio_button,
		more_button,
		IS.create_empty_control()
	])
	
	screen_options_parent.add_child(flex_view_control)
	screen_options_parent.add_child(options_container)
	body.add_child(screen_options_parent)
	
	# Time Slider
	slider_panel = IS.create_panel_container(Vector2(.0, 60.0), load("res://UI&UX/RangeBlack.tres"))
	var slider_margin = IS.create_margin_container(20,20,20,20)
	var slider_box = IS.create_box_container()
	
	slider_time_code_label = IS.create_label("")
	cancel_full_screen_button = IS.create_texture_button(texture_cancel_full_screen)
	
	slider_box.add_child(slider_time_code_label)
	slider_box.add_child(cancel_full_screen_button)
	
	slider_margin.add_child(slider_box)
	slider_panel.add_child(slider_margin)
	flex_view_control.add_child(slider_panel)
	
	await get_tree().process_frame
	slider_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	slider_panel.modulate.a = .0


func get_is_full_screen() -> bool:
	return is_full_screen

func set_is_full_screen(it_is: bool) -> void:
	is_full_screen = it_is

func update_ui() -> void:
	slider_time_code_label.visible = is_full_screen
	cancel_full_screen_button.visible = is_full_screen
	update_timecode()

func update_timecode() -> void:
	var curr_frame_timecode:= TimeServer.frame_to_timecode(PlaybackServer.position)
	var video_length_timecode:= TimeServer.frame_to_timecode(ProjectServer2.project_res.root_clip_res.length)
	time_code_label.set_text(curr_frame_timecode)
	max_time_label.set_text(video_length_timecode)
	slider_time_code_label.set_text(curr_frame_timecode + " / " + video_length_timecode)


func _on_playback_server_played(at: int) -> void:
	play_button.button_pressed = true

func _on_playback_server_stopped(at: int) -> void:
	play_button.button_pressed = false


func _on_playback_server_position_changed(position: int) -> void:
	update_timecode()

func _on_play_button_pressed() -> void:
	if PlaybackServer.is_playing():
		PlaybackServer.stop()
	else:
		PlaybackServer.play()

func _on_replay_button_pressed() -> void:
	EditorServer.editor_settings.is_replay = replay_button.button_pressed

func _on_full_screen_button_pressed() -> void:
	set_is_full_screen(true)

func _on_ratio_button_pressed() -> void:
	pass

func _on_more_button_pressed() -> void:
	pass

func _on_cancel_full_screen_button_pressed() -> void:
	set_is_full_screen(false)







