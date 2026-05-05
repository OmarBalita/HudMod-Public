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
class_name UIProfile extends Resource

signal ui_visiblity_updated()

var ui_conds_keys: Array # Conditions as [Callable(), [result_1, result_2, ...]]
var ui_conds_vals: Array # Controls, ui elements

func set_ui_conditions(new_conds_keys: Array, new_conds_vals: Array) -> void:
	ui_conds_keys = new_conds_keys
	ui_conds_vals = new_conds_vals

func add_ui_condition(ui_key: Array, ui_val: Array) -> void:
	ui_conds_keys.append(ui_key)
	ui_conds_vals.append(ui_val)

func update() -> void:
	
	for idx: int in ui_conds_keys.size():
		var key: Array = ui_conds_keys[idx]
		var cond_func: Callable = key[0]
		var needed_results: Array = key[1]
		
		var is_accepted: bool = needed_results.has(cond_func.call())
		
		var vals: Array = ui_conds_vals[idx]
		
		for ui_object: Control in vals:
			ui_object.visible = is_accepted

