#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Founded by Omar Mohammed Balita.                                       ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
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
class_name PathController extends HBoxContainer

signal root_requested()
signal undo_requested(undo_times: int)

@export var path: Array
@export var root_name: StringName = &"Project"

func get_root_name() -> StringName:
	return root_name

func set_root_name(new_val: StringName) -> void:
	root_name = new_val

func update(_path: Array) -> void:
	path = _path
	
	for node: Node in get_children():
		node.queue_free()
	
	for time: int in path.size() + 1:
		time -= 1
		
		var button: Button = IS.create_button("", null, "", false, false, false, {flat = true})
		var folder_name: String = root_name
		
		if time > -1:
			folder_name = path[time]
		
		var undo_times: int = path.size() - time - 1
		
		button.mouse_entered.connect(button.queue_redraw)
		button.mouse_exited.connect(button.queue_redraw)
		button.draw.connect(draw_button_underline.bind(button))
		button.pressed.connect(on_button_pressed.bind(undo_times))
		
		button.text = folder_name
		add_child(button)
		add_child(IS.create_label("/"))

func draw_button_underline(button: Button) -> void:
	
	if not button.is_hovered() or button.disabled:
		return
	
	var font: Font = button.get_theme_font(&"font")
	var font_size: int = button.get_theme_font_size(&"font_size")
	var text_width: float = font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	
	var style: StyleBox = button.get_theme_stylebox(&"normal")
	var content_rect: Rect2 = Rect2(Vector2(style.get_margin(SIDE_LEFT), style.get_margin(SIDE_TOP)), button.size - style.get_minimum_size())
	
	var start_x: float
	match button.alignment:
		HORIZONTAL_ALIGNMENT_LEFT: start_x = content_rect.position.x
		HORIZONTAL_ALIGNMENT_RIGHT: start_x = content_rect.end.x - text_width
		_: start_x = content_rect.position.x + (content_rect.size.x - text_width) / 2.
	
	var baseline: float = content_rect.position.y + (content_rect.size.y - font.get_height(font_size)) / 2. + font.get_ascent(font_size)
	var thickness: float = maxf(font.get_underline_thickness(font_size), 1.)
	var y: float = baseline + font.get_underline_position(font_size) + thickness / 2.
	
	var color: Color = button.get_theme_color(&"font_pressed_color" if button.button_pressed else &"font_hover_color")
	button.draw_line(Vector2(start_x, y), Vector2(start_x + text_width, y), color, thickness)

func on_button_pressed(undo_times: int) -> void:
	
	await get_tree().process_frame
	
	if path.size() == 0:
		open_root_menu()
		root_requested.emit()
	else:
		undo_requested.emit(undo_times)

func open_root_menu() -> void:
	pass
