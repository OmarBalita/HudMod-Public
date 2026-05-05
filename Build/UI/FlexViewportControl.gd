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
class_name FlexViewportControl extends Control

@export var enabled: bool = true:
	set(val):
		enabled = val
		viewport_container.stretch = not val
		update()
@export var viewport_container: SubViewportContainer

func _init() -> void:
	clip_contents = true

func _ready() -> void:
	update()
	resized.connect(update)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)

func update() -> void:
	
	if not viewport_container: return
	
	if enabled:
		var viewport: SubViewport = null
		for child in viewport_container.get_children():
			if child is SubViewport:
				viewport = child
				break
		if not viewport:
			return
		
		var viewport_size = viewport.size
		
		var scale_ratio = min(
			size.x / viewport_size.x,
			size.y / viewport_size.y
		)
		
		viewport_container.scale = Vector2.ONE * scale_ratio
		
		var scaled_size = Vector2(viewport_size) * viewport_container.scale
		viewport_container.position = (size - scaled_size) / 2.0
	else:
		viewport_container.scale = Vector2.ONE
		viewport_container.position = Vector2.ZERO
		viewport_container.size = size










