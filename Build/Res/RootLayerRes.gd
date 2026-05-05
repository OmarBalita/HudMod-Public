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
class_name RootLayerRes extends LayerRes

signal mute_changed(to: bool)

@export_group("Audio", "audio")
@export var mute: bool:
	set(val):
		mute = val
		AudioServer.set_bus_mute(get_bus_idx(), val)
		mute_changed.emit(val)
@export var volume: float = 1.

var bus_unique_name: StringName

func get_volume() -> float: return volume
func set_volume(new_val: float) -> void: volume = new_val
func get_mute() -> bool: return mute
func set_mute(new_val: bool) -> void: mute = new_val

func get_bus_unique_name() -> StringName: return bus_unique_name
func set_bus_unique_name(new_val: StringName) -> void: bus_unique_name = new_val

func get_bus_idx() -> int: return AudioServer.get_bus_index(bus_unique_name)

func _init() -> void:
	_init_bus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		AudioServer.remove_bus(AudioServer.get_bus_index(bus_unique_name))

func _init_bus() -> void:
	bus_unique_name = &"Layer_%d" % get_instance_id()
	AudioServer.add_bus()
	var curr_idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(curr_idx, bus_unique_name)



