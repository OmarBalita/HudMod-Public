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

## MADE BY AHMED GD
@tool class_name TweenerComponent extends Node

signal finished()

@export var processMode: Tween.TweenProcessMode = Tween.TWEEN_PROCESS_IDLE

@export_group("Minually")
@export var curves: Array[Curve]

@export_group("Automatically")
@export var transType: Tween.TransitionType = Tween.TRANS_LINEAR
@export var easeType: Tween.EaseType = Tween.EASE_IN

var start: Variant
var end: Variant = 1.0

var tween: Tween

func play(obj: Variant, method: String, values: Array[Variant], duration: Array[float], loop: bool = false, trans: Tween.TransitionType = transType, _ease: Tween.EaseType = easeType, delay: float = 0) -> void:
	tween = create_tween().set_trans(trans).set_ease(_ease)
	tween.set_process_mode(processMode)
	
	var curr_dur: float
	for i in range(values.size()):
		if i <= duration.size() - 1: curr_dur = duration[i]
		tween.tween_property(obj, method, values[i], curr_dur).set_delay(delay)
	
	await tween.finished
	finished.emit()
	
	if (loop):
		play(obj, method, values, duration, loop, trans, _ease)

func play_curve(object: Variant, method: String, startIn: Variant = 0.0, endIn: Variant = 1.0, duration: float = 1.0, curveIndex: int = 0, loop: bool = false, delay: float = 0) -> void:
	tween = create_tween()
	tween.set_process_mode(processMode)
	
	tween.tween_method(interpolate.bind(object, method, curveIndex, startIn, endIn), 0.0, 1.0, duration).set_delay(delay)
	tween.play()
	
	await tween.finished
	finished.emit()
	
	if (loop):
		play_curve(object, method, startIn, endIn, duration, curveIndex, loop, delay)

func interpolate(newValue: Variant, object: Variant, property: String, index: int, a: Variant, b: Variant) -> void:
	object.set(property, a + ((b - a) * curves[index].sample(newValue)))

func kill_tween() -> void:
	if tween: tween.kill()
