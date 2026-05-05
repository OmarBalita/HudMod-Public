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
class_name AppEditorSettings extends UsableRes

signal settings_updated()

@export var high_quality_for_playback: bool = false

@export var media_explorer_waveform_color_a: Color = Color(0.273, 0.463, 1.0, 1.0)
@export var media_explorer_waveform_color_b: Color = Color(0.0, 0.589, 0.872, 1.0)

@export var edit: AppEditRes = AppEditRes.new()
@export var performance: AppPerformanceRes = AppPerformanceRes.new()
@export var shortcuts: AppShortcutsRes = AppShortcutsRes.new()
@export var theme: AppThemeRes = AppThemeRes.new()


var media_clip_default_length_f: int
var project_min_length_f: int

var media_explorer_waveform_gradient: Gradient


func _init() -> void:
	update_internal_props()

func update_internal_props() -> void:
	
	media_explorer_waveform_gradient = Gradient.new()
	media_explorer_waveform_gradient.add_point(.0, media_explorer_waveform_color_a)
	media_explorer_waveform_gradient.add_point(.999, media_explorer_waveform_color_b)
	
	settings_updated.emit()

func update_internal_props_base_on_project() -> void:
	edit.update_internal_props_base_on_project()



