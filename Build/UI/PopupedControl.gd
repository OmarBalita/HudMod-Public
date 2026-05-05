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
class_name PopupedControl extends PanelContainer

signal popuped()
signal popdowned()

@export_group("Custom Properties")
@export var poppable_down: bool = true
@export var popdown_when_mouse_move: bool
@export var popdown_duration: float = 1.0
@export var popup_speed: float = .05
@export var popdown_speed: float = .05
@export var hidden_on_start: bool = true

var mouse_move_popdown_requested: bool

var tweener:= TweenerComponent.new()


func _ready() -> void:
	
	# Setup TweenerComponent
	tweener.easeType = Tween.EASE_OUT
	add_child(tweener)
	
	# Connections
	
	# Setup Base Settings
	if hidden_on_start:
		hide()
		await get_tree().process_frame
		custom_minimum_size.x = size.x + 50
		custom_minimum_size.y = size.y

func _input(event: InputEvent) -> void:
	if poppable_down:
		var mouse_in: bool = get_global_rect().has_point(get_global_mouse_position())
		
		if event is InputEventMouseButton:
			if event.is_pressed() and not mouse_in:
				if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
					await get_tree().process_frame
					popdown()
		
		elif event is InputEventMouseMotion:
			if popdown_when_mouse_move and not mouse_move_popdown_requested:
				mouse_move_popdown_requested = true
				await get_tree().create_timer(popdown_duration).timeout
				if not mouse_in:
					popdown()
				mouse_move_popdown_requested = false

func popup(pos: Variant = null) -> void:
	await get_tree().process_frame
	if pos == null:
		pos = get_global_mouse_position()
	
	var window_size = Vector2(get_window().size / get_window().content_scale_factor)
	var dist = pos + custom_minimum_size - window_size
	
	if dist.x > 0:
		pos.x -= dist.x
	if dist.y > 0:
		pos.y -= dist.y
	
	show()
	global_position = pos
	pivot_offset = size / 2
	tweener.play(self, "scale", [Vector2(.9, .9), Vector2.ONE], [.0, popup_speed])
	tweener.play(self, "modulate:a", [.0, 1.0], [.0, popup_speed])
	popuped.emit()


func popdown() -> void:
	set_meta("ended", true)
	tweener.play(self, "scale", [Vector2(.9, .9)], [popdown_speed])
	tweener.play(self, "modulate:a", [.0], [popdown_speed])
	await tweener.finished
	hide()
	
	queue_free()
	popdowned.emit()


