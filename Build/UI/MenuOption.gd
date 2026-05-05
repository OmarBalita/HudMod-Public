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
class_name MenuOption extends Resource


@export var is_separation_line: bool

@export var text: String
@export var icon: Texture2D
@export var forward: Array[MenuOption]
@export var hidden: bool

@export var function: Callable

@export var checkable: bool
@export var checked: bool:
	set(val):
		if not checkable:
			return
		checked = val
		#if checked:
			#if check_group:
				#var last_option = check_group.last_checked_option
				#if last_option:
					#check_group.last_checked_option.checked = false
				#check_group.last_checked_option = self

var check_group: CheckGroup


func _init(_text: String = "", _icon: Texture2D = null, _function: Callable = Callable()) -> void:
	text = _text
	icon = _icon
	function = _function

static func new_line() -> MenuOption:
	var line = MenuOption.new("", null)
	line.is_separation_line = true
	return line

static func new_checked(_text: String = "", _check_group: CheckGroup = null, _icon: Texture2D = null) -> MenuOption:
	var menu_option = MenuOption.new(_text, _icon)
	menu_option.checkable = true
	menu_option.check_group = _check_group
	return menu_option

static func new_options_with_check_group(options_info: Array[Dictionary], check_group_path: String = "", check_index: int = 0) -> Array:
	var options: Array
	
	var group: CheckGroup
	if not check_group_path.is_empty() and FileAccess.file_exists(check_group_path):
		group = ResourceLoader.load(check_group_path)
	if group == null:
		group = CheckGroup.new()
		group.checked_index = check_index
		group.save_path = check_group_path
		if not check_group_path.is_empty():
			ResourceSaver.save(group, check_group_path)
	
	for index in options_info.size():
		var info = options_info[index]
		var option:= MenuOption.new()
		
		if info.has("text"):
			option.text = info.text
		if info.has("icon"):
			option.icon = info.icon
		if info.has("forward"):
			option.forward = info.forward
		
		option.checkable = true
		option.check_group = group
		if check_index == index:
			option.checked = true
		options.append(option)
	
	return options













