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
class_name Menu extends ScrollContainer

signal focus_index_changed(index: int)
signal updated()

@export var options: Array
@export var is_vertical: bool

var focus_index: int:
	set(val):
		focus_index = val
		
		if val < 0: val = options.size() - 1
		elif val > options.size() - 1: val = 0
		
		if buttons_container:
			var new_focus_button = buttons_container.get_child(val)
			if focus_button:
				IS.set_font_from_label_settings(focus_button, IS.label_settings_main)
			if new_focus_button:
				IS.set_font_from_label_settings(new_focus_button, IS.label_settings_header)
			focus_button = new_focus_button
			focus_button.button_pressed = true
			
			await get_tree().process_frame
			set_focus_panel_transform()
		
		focus_index_changed.emit(focus_index)

var use_tween: bool

var buttons_container: BoxContainer

var focus_panel: Panel
var focus_button: Button

var expand_icons: bool

var button_group:= ButtonGroup.new()


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	update()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
			set_focus_panel_transform()

func _draw() -> void:
	await get_tree().process_frame
	set_focus_panel_transform()

func update() -> void:
	for i: Node in get_children():
		i.queue_free()
	
	buttons_container = IS.create_box_container(12, is_vertical)
	IS.expand(buttons_container, true, true)
	focus_panel = IS.create_panel(IS.style_accent)
	
	add_child(focus_panel)
	add_child(buttons_container)
	
	var focused_option_button: Button
	 
	for index: int in options.size():
		var option: MenuOption = options[index]
		var option_button: Button = IS.create_button(option.text, option.icon, option.text, true, true, true, {expand_icon = expand_icons})
		option_button.toggle_mode = true
		option_button.button_group = button_group
		option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_button.pressed.connect(set_focus_index.bind(index))
		if not option.function.is_null(): option_button.pressed.connect(option.function)
		for key: StringName in option.get_meta_list():
			var val = option.get_meta(key)
			option_button.set(key, val)
		buttons_container.add_child(option_button)
		if index == focus_index:
			focused_option_button = option_button
		else:
			IS.set_font_from_label_settings(option_button, IS.label_settings_main)
	
	set_focus_index(focus_index, false)
	custom_minimum_size = buttons_container.size
	
	updated.emit()

func get_focus_index() -> int:
	return focus_index

func set_focus_index(new_focus_index: int, _use_tween: bool = true) -> void:
	use_tween = _use_tween
	focus_index = new_focus_index

func set_focus_panel_transform() -> void:
	if focus_panel and focus_button:
		focus_panel.global_position = focus_button.global_position
		focus_panel.size = focus_button.size



