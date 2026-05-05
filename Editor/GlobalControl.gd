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
class_name GlobalControl extends ShortcutNode

var editor_header: EditorControl.HeaderPanel

func _init() -> void:
	set_mouse_filter(Control.MOUSE_FILTER_IGNORE)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	EditorServer.global_controls[get_window()] = self
	
	key = &"Global"
	cond_func = EditorServer.shortcuts_cond_func
	load_shortcuts_from_settings()

func _input(event: InputEvent) -> void:
	super(event)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			var focus_owner: Control = get_viewport().gui_get_focus_owner()
			if focus_owner and not focus_owner.get_global_rect().has_point(get_global_mouse_position()):
				get_viewport().gui_release_focus()
	
	elif event is InputEventKey:
		
		if event.is_pressed() and event.ctrl_pressed:
			
			var content_scale_add: float
			
			match event.keycode:
				Key.KEY_EQUAL: content_scale_add = .05
				Key.KEY_MINUS: content_scale_add = -.05
			
			if content_scale_add:
				EditorServer.editor_settings.theme.content_scale += content_scale_add
				EditorServer.update_from_theme_settings()
				ResourceSaver.save(EditorServer.editor_settings, EditorServer.editor_settings_path)

func _exit_tree() -> void:
	EditorServer.global_controls.erase(get_window())

func frame_jump(jump: int) -> void:
	if Renderer.is_working: return
	PlaybackServer.position += jump
	EditorServer.time_line2.navigate_to_cursor(sign(jump))
	EditorServer.time_line2.update_timeline_view()

func frame_spacial(step: int) -> void:
	if Renderer.is_working: return
	PlaybackServer.position = EditorServer.time_line2.get_next_spacial_frame(PlaybackServer.position, step)
	EditorServer.time_line2.navigate_to_cursor(sign(step))
	EditorServer.time_line2.update_timeline_view()

func play_and_stop() -> void:
	if Renderer.is_working: return
	if PlaybackServer.is_playing(): PlaybackServer.stop()
	else: PlaybackServer.play()

func new() -> void: EditorServer.popup_new_project()
func open() -> void: EditorServer.popup_open_project()
func save() -> void: ProjectServer2.save()
func save_as() -> void: EditorServer.popup_save_as()
func undo() -> void: ProjectServer2.undo()
func redo() -> void: ProjectServer2.redo()
func exit() -> void: EditorServer.popup_save_option_or_save(get_tree().quit)
func toggle_fullscreen() -> void: EditorServer.toggle_fullscreen()
func report_bugs() -> void: EditorServer.report_bugs()





