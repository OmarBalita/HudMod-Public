#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
##  This program is free software: you can redistribute it and/or modify   ##
##  it under the terms of the GNU General Public License as published by   ##
##  the Free Software Foundation, either version 3 of the License, or      ##
##  (at your option) any later version.                                    ##
##                                                                         ##
##  This program is distributed in the hope that it will be useful,        ##
##  but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           ##
##  GNU General Public License for more details.                           ##
##                                                                         ##
##  You should have received a copy of the GNU General Public License      ##
##  along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
class_name Player extends EditorControl

signal curr_frame_changed(new_frame: int)

# ---------------------------------------------------
# Editor Global Variables

@export_group("Theme")
@export_subgroup("Texture")
@export var texture_play: Texture2D = preload("res://Asset/Icons/play.png")
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
			EditorServer.full_screen_requested.append(get_instance_id())
		else:
			flex_view_control.reparent(screen_options_parent)
			screen_options_parent.move_child(flex_view_control, 0)
			EditorServer.full_screen_requested.erase(get_instance_id())
		
		EditorServer.update_window_mode()
		update_ui()

# RealTime Nodes

var tweener: TweenerComponent = TweenerComponent.new()

var screen_options_parent: SplitContainer

var flex_view_control: FlexViewportControl
var viewport: SubViewport

var options_container: BoxContainer
var play_button: IS.CustomTextureButton
var replay_button: IS.CustomTextureButton
var time_code_label: Label
var max_time_label: Label

var volume_control: VolumeControl = VolumeControl.new()

var full_screen_button: TextureButton
#var ratio_button: TextureButton
#var more_button: TextureButton

var control_panel: PanelContainer
var time_code_label2: Label
var cancel_full_screen_button: TextureButton


# ---------------------------------------------------
# Background Called Functions

func _ready_editor() -> void:
	
	_ready_ui()
	
	ProjectServer2.project_opened.connect(_on_project_server_project_opened)
	
	PlaybackServer.played.connect(_on_playback_server_played)
	PlaybackServer.stopped.connect(_on_playback_server_stopped)
	PlaybackServer.position_changed.connect(_on_playback_server_position_changed)
	
	play_button.pressed.connect(_on_play_button_pressed)
	replay_button.pressed.connect(_on_replay_button_pressed)
	full_screen_button.pressed.connect(_on_full_screen_button_pressed)
	#ratio_button.pressed.connect(_on_ratio_button_pressed)
	#more_button.pressed.connect(_on_more_button_pressed)
	
	cancel_full_screen_button.pressed.connect(_on_cancel_full_screen_button_pressed)


func _ready_ui() -> void:
	add_child(tweener)
	
	_ready_header()
	_ready_body()



func _ready_header() -> void:
	
	var header_box_container: BoxContainer = IS.create_box_container(12, false, {})
	
	const LOGO: CompressedTexture2D = preload("res://Asset/Icons/App/logo2-low.png")
	const HEART: CompressedTexture2D = preload("res://Asset/Icons/heart.png")
	
	var official_logo_button: Button = IS.create_button("HudMod", LOGO, "", false, false, false, {expand_icon = true, custom_minimum_size = Vector2(120.0, .0)})
	var support_button: Button = IS.create_button("Support", HEART, "", false, false, false, {expand_icon = true, custom_minimum_size = Vector2(120.0, .0)})
	
	const MIN_SIZE: Vector2 = Vector2(80., .0)
	
	var global_control: GlobalControl = EditorServer.global_controls[get_window()]
	if not global_control.is_node_ready():
		await global_control.ready
	
	var project_btn: MenuButton = IS.create_menu_button("Project", [
		{text = "New Project", shortcut = global_control.get_shortcut(&"new")},
		{text = "Open", shortcut = global_control.get_shortcut(&"open")},
		{text = "Open Recent", submenu = EditorServer.popup_menu_recent},
		{as_separator = true},
		{text = "Save", shortcut = global_control.get_shortcut(&"save")},
		{text = "Save As", shortcut = global_control.get_shortcut(&"save_as")},
		{as_separator = true},
		{text = "Undo", icon = preload("res://Asset/Icons/undo.png"), shortcut = global_control.get_shortcut(&"undo")},
		{text = "Redo", icon = preload("res://Asset/Icons/redo.png"), shortcut = global_control.get_shortcut(&"redo")},
		{as_separator = true},
		{text = "Exit", shortcut = global_control.get_shortcut(&"exit")},
	], {custom_minimum_size = MIN_SIZE})
	
	var editor_btn: MenuButton = IS.create_menu_button("Editor", [
		{text = "Editor Settings"},
		{as_separator = true},
		{text = "Layout", icon = preload("res://Asset/Icons/grid.png"), submenu = EditorServer.popup_menu_layout},
		{text = "Docks", submenu = EditorServer.popup_menu_docks},
		{text = "Toggle Fullscreen", shortcut = global_control.get_shortcut(&"toggle_fullscreen")}
	], {custom_minimum_size = MIN_SIZE})
	
	var help_btn: MenuButton = IS.create_menu_button("Help", [
		{text = "Report Bugs", icon = preload("res://Asset/Icons/report.png"), shortcut = global_control.get_shortcut(&"report_bugs")},
		{as_separator = true},
		{text = "Learn", disabled = true},
		{text = "Community"},
		{as_separator = true},
		{text = "About HudMod", icon = LOGO},
		{text = "Support HudMod", icon = HEART},
	], {custom_minimum_size = MIN_SIZE})
	
	header_box_container.add_child(official_logo_button)
	header_box_container.add_child(support_button)
	header_box_container.add_child(project_btn)
	header_box_container.add_child(editor_btn)
	header_box_container.add_child(help_btn)
	
	header.add_child(header_box_container)
	
	official_logo_button.pressed.connect(_on_official_logo_button_pressed)
	support_button.pressed.connect(_on_support_button_pressed)
	project_btn.get_popup().id_pressed.connect(_on_project_popup_id_pressed)
	editor_btn.get_popup().id_pressed.connect(_on_editor_popup_id_pressed)
	help_btn.get_popup().id_pressed.connect(_on_help_popup_id_pressed)


func _ready_body() -> void:
	
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
	
	viewport = Scene2.viewport
	view_container.add_child(viewport)
	flex_view_control.add_child(view_container)
	flex_view_control.viewport_container = view_container
	
	play_button = IS.create_texture_button(texture_play, null, texture_pause, "Play / Pause", true)
	replay_button = IS.create_texture_button(texture_replay, null, null, "Replay", true)
	time_code_label = IS.create_label("", "", IS.label_settings_bold)
	max_time_label = IS.create_label("")
	
	full_screen_button = IS.create_texture_button(texture_full_screen, null, null, "Fullscreen")
	#ratio_button = IS.create_texture_button(texture_ratio)
	#more_button = IS.create_texture_button(texture_more)
	
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
		#IS.create_v_line_panel(),
		#ratio_button,
		#more_button,
		IS.create_empty_control()
	])
	
	screen_options_parent.add_child(flex_view_control)
	screen_options_parent.add_child(options_container)
	body.add_child(screen_options_parent)
	
	# Time Slider
	control_panel = IS.create_panel_container(Vector2(.0, 60.0), load("res://UI&UX/RangeBlack.tres"))
	var control_margin: MarginContainer = IS.create_margin_container(20,20,20,20)
	var control_box: BoxContainer = IS.create_box_container()
	
	var space_ctrl: Control = IS.create_empty_control(.0, .0)
	
	time_code_label2 = Label.new()
	cancel_full_screen_button = TextureButton.new()
	cancel_full_screen_button.texture_normal = texture_cancel_full_screen
	cancel_full_screen_button.tooltip_text = "Cancel fullscreen"
	
	IS.expand(space_ctrl)
	IS.set_base_settings(time_code_label)
	IS.set_base_settings(cancel_full_screen_button)
	
	control_box.add_child(time_code_label2)
	control_box.add_child(space_ctrl)
	control_box.add_child(cancel_full_screen_button)
	
	control_margin.add_child(control_box)
	control_panel.add_child(control_margin)
	flex_view_control.add_child(control_panel)
	
	await get_tree().process_frame
	control_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)


func get_is_full_screen() -> bool:
	return is_full_screen

func set_is_full_screen(it_is: bool) -> void:
	is_full_screen = it_is

func update_ui() -> void:
	control_panel.visible = is_full_screen
	update_timecode()

func update_timecode() -> void:
	var curr_frame_timecode:= TimeServer.frame_to_timecode(PlaybackServer.position)
	var video_length_timecode:= TimeServer.frame_to_timecode(ProjectServer2.project_res.root_clip_res.length)
	time_code_label.set_text(curr_frame_timecode)
	max_time_label.set_text(video_length_timecode)
	time_code_label2.set_text(curr_frame_timecode + " / " + video_length_timecode)


func _on_project_server_project_opened(project_res: ProjectRes) -> void:
	update_ui()
	flex_view_control.update()


func _on_playback_server_played(at: int) -> void:
	play_button.button_pressed = true
	play_button.update_button()

func _on_playback_server_stopped(at: int) -> void:
	play_button.button_pressed = false
	play_button.update_button()

func _on_playback_server_position_changed(position: int) -> void:
	update_timecode()

func _on_play_button_pressed() -> void:
	if PlaybackServer.is_playing():
		PlaybackServer.stop()
	else:
		PlaybackServer.play()

func _on_replay_button_pressed() -> void:
	EditorServer.editor_settings.edit.replay = replay_button.button_pressed
	ResourceSaver.save(EditorServer.editor_settings, EditorServer.editor_settings_path)

func _on_full_screen_button_pressed() -> void:
	set_is_full_screen(true)

#func _on_ratio_button_pressed() -> void:
	#pass
#
#func _on_more_button_pressed() -> void:
	#pass

func _on_cancel_full_screen_button_pressed() -> void:
	set_is_full_screen(false)


func _on_official_logo_button_pressed() -> void:
	OS.shell_open(EditorServer.version_info.website_link)

func _on_support_button_pressed() -> void:
	OS.shell_open(EditorServer.version_info.support_link)

func _on_project_popup_id_pressed(id: int) -> void:
	match id:
		0: EditorServer.popup_new_project()
		1: EditorServer.popup_open_project()
		4: ProjectServer2.save()
		5: EditorServer.popup_save_as()
		7: ProjectServer2.undo()
		8: ProjectServer2.redo()
		10: EditorServer.popup_save_option_or_save(get_tree().quit)

func _on_editor_popup_id_pressed(id: int) -> void:
	match id:
		0: EditorServer.popup_editor_settings()
		4: EditorServer.toggle_fullscreen()

func _on_help_popup_id_pressed(id: int) -> void:
	match id:
		0: EditorServer.report_bugs()
		2: EditorServer.popup_learn()
		3: EditorServer.go_to_community()
		5: EditorServer.popup_about()
		6: OS.shell_open(EditorServer.version_info.support_link)





