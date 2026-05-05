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
class_name PopupedBox extends PopupedControl

var box: BoxContainer
var elements: Array

func _ready() -> void:
	super()
	var margin_container = IS.create_margin_container()
	var scroll_container = IS.create_scroll_container()
	var margin2_container = IS.create_margin_container(0, 12, 0, 0)
	box = IS.create_box_container(12, true)
	
	for index: int in elements.size():
		var element = elements[index]
		if element is Array:
			for control in element:
				if control == null:
					continue
				box.add_child(control.get_parent())
		else: box.add_child(element)
	
	margin2_container.add_child(box)
	scroll_container.add_child(margin2_container)
	margin_container.add_child(scroll_container)
	add_child(margin_container)
	
	IS.expand(margin2_container, true, true)








