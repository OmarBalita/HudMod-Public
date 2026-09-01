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
class_name ProjectRes extends UsableRes

signal resolution_changed(resolution: Vector2i)
signal fps_changed(fps: int)

signal timemarker_added(frame: int, timemarker: TimeMarkerRes)
signal timemarker_removed(frame: int, timemarker: TimeMarkerRes)
signal timemarker_moved(from_frame: int, to_frame: int, timemarker: TimeMarkerRes)

const PRESET_OPTIONS: Dictionary[StringName, Dictionary] = {
	# --- Legacy & Low Presets ---
	&"240p (Ultra Low)": {&"resolution": Vector2i(426, 240), &"fps": 24},
	&"360p (Legacy Web)": {&"resolution": Vector2i(640, 360), &"fps": 30},
	&"480p SD (DVD)": {&"resolution": Vector2i(854, 480), &"fps": 30},
	# --- Standard & HD Presets ---
	&"720p HD": {&"resolution": Vector2i(1280, 720), &"fps": 30},
	&"1080p Full HD (30 FPS)": {&"resolution": Vector2i(1920, 1080), &"fps": 30},
	&"1080p Full HD (60 FPS)": {&"resolution": Vector2i(1920, 1080), &"fps": 60},
	&"1080p Cinema (24 FPS)": {&"resolution": Vector2i(1920, 1080), &"fps": 24.0},
	# --- Vertical & Social Presets ---
	&"1080x1920 Vertical (30 FPS)": {&"resolution": Vector2i(1080, 1920), &"fps": 30},
	&"1080x1920 Vertical (60 FPS)": {&"resolution": Vector2i(1080, 1920), &"fps": 60},
	&"1080x1080 Square": {&"resolution": Vector2i(1080, 1080), &"fps": 30},
	# --- High & Professional Presets ---
	&"1440p 2K QHD": {&"resolution": Vector2i(2560, 1440), &"fps": 60},
	&"4K Ultra HD (UHD)": {&"resolution": Vector2i(3840, 2160), &"fps": 60},
	&"4K DCI Cinema": {&"resolution": Vector2i(4096, 2160), &"fps": 24},
	&"8K Ultra HD": {&"resolution": Vector2i(7680, 4320), &"fps": 60}
}

@export var version_name: StringName

@export var project_name: StringName = &"HudMod Video"

@export var resolution: Vector2 = Vector2(1920, 1080):
	set(val):
		resolution = val
		resolution_changed.emit(resolution)

@export var fps: int = 30:
	set(val):
		fps = val
		delta = 1.0 / fps
		fps_changed.emit(fps)

@export var timemarkers: Dictionary[int, TimeMarkerRes]
@export var root_clip_res: RootClipRes = RootClipRes.new()

var aspect_ratio: Vector2
var delta: float = 1. / fps

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"project_name": export(string_args(String(project_name))),
		&"resolution": export(vec2_args(resolution, true, false, FloatController.SuffixType.TYPE_PIXEL, Vector2(480, 7680), Vector2(240, 4320))),
		&"fps": export(int_args(fps, 6, 120))
	}

func _custom_editor_spawned(edit_cont: EditContainer, props_editors: Dictionary[StringName, Control]) -> void:
	var header_cont: BoxContainer = edit_cont.header_cont
	var preset_options_ctrlr: OptionController = IS.create_options_controller_2(0, PRESET_OPTIONS)
	preset_options_ctrlr.selected_option_changed.connect(
		func(id: int, option: MenuOption) -> void:
			var option_info: Dictionary = PRESET_OPTIONS[StringName(option.text)]
			props_editors.resolution.set_curr_value_and_update_controller(Vector2(option_info.resolution))
			props_editors.fps.set_curr_value_and_update_controller(option_info.fps)
	)
	header_cont.add_child(preset_options_ctrlr)

func get_project_name() -> StringName: return project_name
func set_project_name(new_val: StringName) -> void: project_name = new_val

func get_resolution() -> Vector2i: return Vector2i(1024, 720)
func get_fps() -> int: return fps
func get_root_clip_res() -> RootClipRes: return root_clip_res

func set_resolution(new_val: Vector2) -> void: resolution = new_val
func set_fps(new_val: int) -> void: fps = new_val
func set_root_clip_res(new_val: RootClipRes) -> void: root_clip_res = new_val

func get_timemarkers() -> Dictionary[int, TimeMarkerRes]: return timemarkers
func set_timemarkers(new_val: Dictionary[int, TimeMarkerRes]) -> void: timemarkers = new_val

func add_timemarker(frame: int) -> void:
	if timemarkers.has(frame): return
	var new_one:= TimeMarkerRes.new()
	timemarkers[frame] = new_one
	timemarker_added.emit(frame, new_one)

func remove_timemarker(frame: int) -> void:
	if not timemarkers.has(frame): return
	var timemarker: TimeMarkerRes = timemarkers[frame]
	timemarkers.erase(frame)
	timemarker_removed.emit(frame, timemarker)

func move_timemarker(from_frame: int, to_frame: int) -> void:
	if not timemarkers.has(from_frame) or timemarkers.has(to_frame): return
	var timemarker: TimeMarkerRes = timemarkers[from_frame]
	timemarkers.erase(timemarker)
	timemarkers[to_frame] = timemarker
	timemarker_moved.emit(from_frame, to_frame, timemarker)
