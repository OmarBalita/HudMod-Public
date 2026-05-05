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
class_name AppPerformanceRes extends UsableRes

@export var low_quality_for_playback: bool = true
@export var frames_dropped: int = 0
@export_range(50, 5000) var video_max_frame_cache: int = 500
@export_range(.1, 1., .1) var video_scale_factor: float = 1.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"low_quality_for_playback": export(bool_args(low_quality_for_playback)),
		&"frames_dropped": export(int_args(frames_dropped, 0, 3)),
		&"video_max_frame_cache": export(int_args(video_max_frame_cache, 50, 5000)),
		&"video_scale_factor": export(float_args(video_scale_factor, .1, 1., .1))
	}
