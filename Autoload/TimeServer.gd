#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
##	This program is free software: you can redistribute it and/or modify   ##
##	it under the terms of the GNU General Public License as published by   ##
##	the Free Software Foundation, either version 3 of the License, or	   ##
##	(at your option) any later version.									   ##
##																		   ##
##	This program is distributed in the hope that it will be useful,		   ##
##	but WITHOUT ANY WARRANTY; without even the implied warranty of		   ##
##	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the		   ##
##	GNU General Public License for more details.						   ##
##																		   ##
##	You should have received a copy of the GNU General Public License	   ##
##	along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
extends Node


func frame_to_seconds(frame: int, fps: int = 0) -> float:
	if fps == 0: fps = ProjectServer2.fps
	return float(frame) / fps

func seconds_to_frame(seconds: float, fps: int = 0) -> int:
	if fps == 0: fps = ProjectServer2.fps
	return int(seconds * fps)

func map_frames_between_fps(frame: int, from_fps: int = 0, to_fps: int = 0) -> int:
	return seconds_to_frame(frame_to_seconds(frame, from_fps), to_fps)

func localize_frame(curr_frame: int, clip_pos: int) -> int:
	return curr_frame - clip_pos

func globalize_frame(local_frame: int, clip_pos: int) -> int:
	return local_frame + clip_pos

func frame_to_timecode(frame: int, fps: int = 0) -> String:
	if fps == 0: fps = ProjectServer2.fps
	var total_seconds:= frame / fps
	var hours:= int(total_seconds / 3600)
	var minutes:= int((total_seconds % 3600) / 60)
	var seconds:= int(total_seconds % 60)
	var frames:= int(frame % fps)
	return "%02d:%02d:%02d:%02d" % [hours, minutes, seconds, frames]

func timecode_to_frame(timecode: String, fps: int = 0) -> int:
	if fps == 0: fps = ProjectServer2.fps
	
	timecode = timecode.strip_edges()
	if timecode.is_empty():
		return -1
	
	var units: PackedStringArray = timecode.replace(";", ":").split(":")
	var size: int = units.size()
	
	if size < 1 or size > 4:
		return -1
	
	for idx: int in size:
		var unit: String = units[idx].strip_edges()
		if unit.is_empty() or not unit.is_valid_int():
			return -1
		units[idx] = unit
	
	var hours: int
	var minutes: int
	var seconds: int
	var frames: int
	
	match size:
		1:
			frames = int(units[0])
		2:
			seconds = int(units[0])
			frames = int(units[1])
		3:
			minutes = int(units[0])
			seconds = int(units[1])
			frames = int(units[2])
		4:
			hours = int(units[0])
			minutes = int(units[1])
			seconds = int(units[2])
			frames = int(units[3])
	
	return (hours * 3600 + minutes * 60 + seconds) * fps + frames


