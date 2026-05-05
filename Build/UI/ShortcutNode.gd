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
class_name ShortcutNode extends Control

signal shortcut_performed(key: StringName)

@export var key: StringName = &""
@export var shortcuts: Dictionary
@export var enabled: bool = true

var methods_object: Object = self
var cond_func: Callable


func load_shortcuts_from_settings() -> void:
	EditorServer.editor_settings.shortcuts.load_shortcuts_to(self)

static func new_shortcut(key_code: Key, ctrl_pressed: bool = false, shift_pressed: bool = false, alt_pressed: bool = false) -> Shortcut:
	var shortcut: Shortcut = Shortcut.new()
	var event_key:= InputEventKey.new()
	event_key.keycode = key_code
	event_key.ctrl_pressed = ctrl_pressed
	event_key.shift_pressed = shift_pressed
	event_key.alt_pressed = alt_pressed
	shortcut.events = [event_key]
	return shortcut

func get_shortcuts() -> Dictionary:
	return shortcuts

func set_shortcuts(new_val: Dictionary) -> void:
	shortcuts = new_val

func get_shortcut(key: StringName) -> Shortcut:
	return shortcuts[key][0]

func _init() -> void:
	set_process_input(false)
	mouse_entered.connect(set_process_input.bind(true))
	mouse_exited.connect(set_process_input.bind(false))
	
	mouse_filter = Control.MOUSE_FILTER_PASS
	IS.expand(self, true, true)

func _input(event: InputEvent) -> void:
	
	if cond_func.is_valid() and not cond_func.call():
		return
	
	if not is_visible_in_tree():
		return
	
	if not get_global_rect().has_point(get_global_mouse_position()):
		return
	
	if event is InputEventKey:
		
		if not event.is_pressed():
			return
		
		for shortcut_key: StringName in shortcuts:
			
			var info: Array = shortcuts[shortcut_key]
			var shortcut: Shortcut = info[0]
			
			if shortcut.matches_event(event):
				
				var method_name: StringName = info[1]
				methods_object.callv(method_name, info[2] if info.size() >= 3 else [])
				
				shortcut_performed.emit(shortcut_key)
				return





