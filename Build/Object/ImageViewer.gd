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
class_name ImageViewer extends Node2D

@export var texture: Texture2D:
	set(val):
		texture = val
		queue_redraw()

@export_group("Offset")
@export var offset: Vector2 = Vector2.ZERO:
	set(val):
		offset = val
		queue_redraw()
@export var flip_h: bool = false:
	set(val):
		flip_h = val
		queue_redraw()
@export var flip_v: bool = false:
	set(val):
		flip_v = val
		queue_redraw()

var texture_scale: Vector2

func _draw() -> void:
	
	if not texture:
		return
	
	var view_size: Vector2i = Scene2.viewport.size
	
	var tex_size: Vector2 = texture.get_size()
	
	var scale_factor: float = min(view_size.x / tex_size.x, view_size.y / tex_size.y)
	var final_size: Vector2 = tex_size * scale_factor
	
	var position: Vector2 = -final_size / 2. + offset
	
	var rect: Rect2 = Rect2(position, final_size)
	
	if flip_h:
		rect.size.x *= -1.
	if flip_v:
		rect.size.y *= -1.
	
	draw_texture_rect(texture, rect, false)


