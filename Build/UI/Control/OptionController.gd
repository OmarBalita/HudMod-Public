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
class_name OptionController extends Button

signal selected_option_changed(id: int, option: MenuOption)

@export var save_path: String

var options: Array

var selected_id: int:
	set(val):
		selected_id = val
		if options.size() > val:
			selected_option = options[val]
			if is_node_ready():
				update_display_option()

var selected_option: MenuOption

func _ready() -> void:
	pressed.connect(on_pressed)
	update_display_option()

func update_display_option() -> void:
	text = options[selected_id].text

func get_selected_id() -> int:
	return selected_id

func set_selected_id(new_selected_id: int) -> void:
	selected_id = new_selected_id
	selected_option_changed.emit(selected_id, selected_option)

func set_selected_id_manually(new_selected_id: int) -> void:
	selected_id = new_selected_id

func on_pressed() -> void:
	var menu: PopupedMenu = IS.popup_menu(options, self, get_window())
	menu.menu_button_pressed.connect(on_menu_button_pressed)

func on_menu_button_pressed(id: int) -> void:
	set_selected_id(id)
