#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
##	This program is free software: you can redistribute it and/or modify   ##
##	it under the terms of the GNU General Public License as published by   ##
##	the Free Software Foundation, either version 3 of the License, or	   ##
##	(at your option) any later version.									   ##
##																		   ##
##	This program is distributed in the hope that it will be useful,		   ##
##	but WITHOUT ANY WARRANTY; without even the implied warranty of		   ##
##	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the		   ##
##	GNU General Public License for more details.						   ##
##																		   ##
##	You should have received a copy of the GNU General Public License	   ##
##	along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
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
			viewport_texture_rect.reparent(get_tree().get_current_scene())
			viewport_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			EditorServer.full_screen_requested.append(get_instance_id())
		else:
			viewport_texture_rect.reparent(screen_bg_color_rect)
			viewport_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			EditorServer.full_screen_requested.erase(get_instance_id())
		
		EditorServer.update_window_mode()
		update_ui()

# RealTime Nodes

var screen_options_parent: SplitContainer

var screen_bg_color_rect: ColorRect
var viewport_texture_rect: TextureRect
var gizmos_drawer: GizmosDrawer
var viewport: SubViewport

var options_container: BoxContainer
var play_button: IS.CustomTextureButton
var replay_button: IS.CustomTextureButton
var time_code_label: Label
var max_time_label: Label
var time_code_edit: LineEdit

var volume_control: VolumeControl = VolumeControl.new()

var full_screen_button: TextureButton

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
	
	cancel_full_screen_button.pressed.connect(_on_cancel_full_screen_button_pressed)


func _ready_ui() -> void:
	_ready_header()
	_ready_body()
	viewport = Scene2.viewport



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
		{text = "Keyboard Customization"},
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
	
	screen_bg_color_rect = IS.create_color_rect(Color(.15, .15, .15, 1.))
	IS.expand(screen_bg_color_rect, true, true)
	
	viewport_texture_rect = IS.create_texture_rect(Scene2.viewport.get_texture())
	viewport_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	viewport_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	#IS.expand(viewport_texture_rect, true, true)
	
	options_container = IS.create_box_container(10, false,
	{"custom_minimum_size": Vector2(.0, 50.0), "alignment": BoxContainer.ALIGNMENT_CENTER})
	var time_panel: PanelContainer = IS.create_panel_container(Vector2(300, 0))
	var time_container: BoxContainer = IS.create_box_container()
	
	gizmos_drawer = GizmosDrawer.new()
	gizmos_drawer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	
	viewport_texture_rect.add_child(gizmos_drawer)
	screen_bg_color_rect.add_child(viewport_texture_rect)
	
	play_button = IS.create_texture_button(texture_play, null, texture_pause, "Play / Pause", true)
	replay_button = IS.create_texture_button(texture_replay, null, null, "Replay", true)
	time_code_label = IS.create_label("", "", IS.label_settings_bold)
	max_time_label = IS.create_label("")

	time_code_edit = LineEdit.new()
	time_code_edit.visible = false
	time_code_edit.context_menu_enabled = false
	time_code_edit.select_all_on_focus = true
	time_code_edit.caret_blink = true
	
	IS.set_font_from_label_settings(time_code_edit, IS.label_settings_bold)    
	time_code_edit.add_theme_color_override("caret_color", IS.label_settings_bold.font_color)
	time_code_edit.add_theme_constant_override(&"outline_size", .0)

	time_code_edit.add_theme_stylebox_override("normal", IS.style_box_empty)
	time_code_edit.add_theme_stylebox_override("focus", IS.style_box_empty)
	time_code_edit.add_theme_stylebox_override("read_only", IS.style_box_empty)

	time_code_label.mouse_filter = Control.MOUSE_FILTER_STOP
	time_code_label.gui_input.connect(_on_time_code_label_gui_input)
	time_code_edit.gui_input.connect(_on_time_code_edit_gui_input)
	time_code_edit.text_submitted.connect(_on_time_code_edit_text_submitted)
	time_code_edit.focus_exited.connect(_on_time_code_edit_focus_exited)
	
	full_screen_button = IS.create_texture_button(texture_full_screen, null, null, "Fullscreen")
	
	time_container.add_child(time_code_label)
	time_container.add_child(time_code_edit)
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
		IS.create_empty_control()
	])
	
	screen_options_parent.add_child(screen_bg_color_rect)
	screen_options_parent.add_child(options_container)
	body.add_child(screen_options_parent)
	
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
	viewport_texture_rect.add_child(control_panel)
	
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

func _start_timecode_edit_mode() -> void:
	time_code_edit.text = time_code_label.text
	time_code_edit.custom_minimum_size = time_code_label.size
	time_code_label.visible = false
	time_code_edit.visible = true
	time_code_edit.grab_focus()
	time_code_edit.select_all()

func _exit_timecode_edit_mode() -> void:
	time_code_edit.visible = false
	time_code_label.visible = true
	update_timecode()
	if EditorServer.time_line2.cursor_out_of_box():
		EditorServer.time_line2.navigate_horizontal_to(PlaybackServer.position)

func _on_project_server_project_opened(project_res: ProjectRes) -> void:
	update_ui()
	#flex_view_control.update()

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


func _on_time_code_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click and event.is_pressed():
		_start_timecode_edit_mode()

func _on_time_code_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
		time_code_edit.text = time_code_label.text
		_exit_timecode_edit_mode()
		get_viewport().set_input_as_handled()

func _on_time_code_edit_text_submitted(new_text: String) -> void:
	
	if Renderer.is_working:
		return
	
	var frame: int = TimeServer.timecode_to_frame(new_text)
	if frame != -1:
		var max_frame: int = ProjectServer2.project_res.root_clip_res.length
		frame = clampi(frame, 0, max_frame)
		PlaybackServer.stop()
		PlaybackServer.position = frame
	
	_exit_timecode_edit_mode()

func _on_time_code_edit_focus_exited() -> void:
	_exit_timecode_edit_mode()


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
		1: EditorServer.popup_keyboard_customization()
		5: EditorServer.toggle_fullscreen()

func _on_help_popup_id_pressed(id: int) -> void:
	match id:
		0: EditorServer.report_bugs()
		2: EditorServer.popup_learn()
		3: EditorServer.go_to_community()
		5: EditorServer.popup_about()
		6: OS.shell_open(EditorServer.version_info.support_link)
