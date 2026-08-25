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

signal project_opened(project_res: ProjectRes)
signal project_launched(project_path: String)

signal opened_clip_res_changed(old_one: MediaClipRes, new_one: MediaClipRes)

#const EXAMPLE_PATH: String = "res://ExampleProject/"

var project_path: String:
	set(val):
		project_path = val
		project_editor_path = project_path.path_join("editor/")
		project_thumbnail_path = project_path.path_join("image/thumbnail/")
		project_waveform_path = project_path.path_join("image/waveform/")
		project_media_path = project_path.path_join("media/")
		project_preset_path = project_path.path_join("preset/")

var project_editor_path: String:
	set(val):
		project_editor_path = val
		DirAccess.make_dir_absolute(val)
var project_thumbnail_path: String:
	set(val):
		project_thumbnail_path = val
		DirAccess.make_dir_recursive_absolute(val)
var project_waveform_path: String:
	set(val):
		project_waveform_path = val
		DirAccess.make_dir_recursive_absolute(val)
var project_media_path: String:
	set(val):
		project_media_path = val
		DirAccess.make_dir_absolute(val)
var project_preset_path: String:
	set(val):
		project_preset_path = val
		DirAccess.make_dir_absolute(val)

var is_project_loaded: bool = false
var project_res: ProjectRes:
	set(val):
		project_res = val
		if project_res:
			fps = project_res.fps
			delta = project_res.delta

var import_file_system: FileSystem
var preset_file_system: FileSystem

var undo_redo: UndoRedo = UndoRedo.new()
var saved_version: int

var fps: int
var delta: float

var opened_clip_res_path: Array[MediaClipRes]


# Project Management
# ---------------------------------------------------

func _create_project_files(project_res: ProjectRes, dir_path: String) -> String:
	
	project_res.version_name = EditorServer.version_info.version_name
	
	if Renderer.is_working:
		Renderer.cancel()
	
	if DirAccess.dir_exists_absolute(dir_path):
		EditorServer.push_message("There is already a folder or file with the same name; please change the name or path.")
		return ""
	
	var project_path: String = dir_path.simplify_path()
	var paths: Dictionary[StringName, String] = ProjectServer2._get_project_paths(project_path)
	
	if DirAccess.make_dir_recursive_absolute(dir_path) != Error.OK:
		EditorServer.push_message("Problem creating project folder.")
		return ""
	
	project_res.root_clip_res = RootClipRes.new()
	
	if ResourceSaver.save(project_res, paths.project_res) != Error.OK:
		EditorServer.push_message("Problem save project resource.")
		return ""
	
	ResourceSaver.save(FileSystem.new(), paths.import_sys)
	ResourceSaver.save(FileSystem.new(), paths.preset_sys)
	
	return project_path

func new_project(project_res: ProjectRes, dir_path: String, method_post: Callable) -> ProjectRes:
	var project_path: String = _create_project_files(project_res, dir_path)
	if project_path.is_empty():
		return null
	
	method_post.call(project_path)
	return project_res

func launch_project(_project_path: String) -> bool:
	if not _check_for_project_file_exist(_project_path.path_join("project.res")): return false
	
	var pid: int = OS.create_process(OS.get_executable_path(), _get_launch_args(_project_path))
	if pid == -1:
		EditorServer.push_message("Could not launch a new instance for this project.")
		return false
	
	project_launched.emit(_project_path)
	
	return true

func open_project(_project_path: String) -> bool:
	
	var project_paths: Dictionary[StringName, String] = _get_project_paths(_project_path)
	if not _check_for_project_file_exist(project_paths.project_res): return false
	
	var _temp_prj_path:= project_path
	project_path = _project_path
	
	#var _temp_imp_file_sys:= import_file_system
	#var _temp_pre_file_sys:= preset_file_system
	
	var _project_res: Resource = ResourceLoader.load(project_paths.project_res)
	
	_project_res = _project_res as ProjectRes
	
	if _project_res is not ProjectRes:
		#is_project_loaded = true
		project_path = _temp_prj_path#; import_file_system = _temp_imp_file_sys; preset_file_system = _temp_pre_file_sys
		EditorServer.push_message("The project could not be opened.")
		return false
	
	if _project_res.version_name != EditorServer.version_info.version_name:
		#is_project_loaded = true
		project_path = _temp_prj_path#; import_file_system = _temp_imp_file_sys; preset_file_system = _temp_pre_file_sys
		EditorServer.push_message("The project requires version \"%s\" of HudMod, the current version \"%s\"" % [_project_res.version_name, EditorServer.version_info.version_name])
		return false
	
	is_project_loaded = false
	
	import_file_system = ResLoadHelper.load_or_save(project_paths.import_sys, FileSystem)
	preset_file_system = ResLoadHelper.load_or_save(project_paths.preset_sys, FileSystem)
	
	import_file_system.thumbnail_path = project_thumbnail_path
	import_file_system.waveform_path = project_waveform_path
	
	undo_redo.max_steps = 50
	undo_redo.clear_history()
	Scene2.clear_nodes()
	MediaCache.clear_all_cache()
	opened_clip_res_path.clear()
	
	project_res = _project_res
	
	saved_version = undo_redo.get_version()
	
	MediaCache.load_media_cache_from_file_system(import_file_system)
	MediaCache.load_media_cache_from_file_system(preset_file_system)
	GlobalServer.load_global()
	
	project_res.root_clip_res.loop_layers_children_deep(
		{},
		func(layers: Array[LayerRes], layer_idx: int, parent_clip_res: MediaClipRes, layer: LayerRes, frame: int, dupl_info: Dictionary[StringName, Variant]) -> void:
			var clip_res: MediaClipRes = layer.clips[frame]
			clip_res.parent = parent_clip_res
			clip_res.layer_index = layer_idx
			clip_res.clip_pos = frame
			clip_res.loop_components(
				func(comp: ComponentRes) -> void:
					comp.set_owner_from_loader(clip_res)
			)
			clip_res.loop_animations(frame,
				func(usable_res: UsableRes, prop_key: StringName, anim_res, frame: int) -> void:
					anim_res.update_funcs()
			)
			if clip_res is Display2DClipRes:
				clip_res.build_shader_pipeline()
	)
	
	EditorServer.editor_settings.update_internal_props_base_on_project()
	
	project_res.root_clip_res.update_paths_deep()
	project_res.root_clip_res.update_root_length()
	
	is_project_loaded = true
	project_opened.emit(project_res)
	
	open_clip_res(project_res.root_clip_res)
	
	EditorServer.push_message("Project opened: %s" % _project_path, EditorServer.MessageMode.MESSAGE_MODE_IDLE)
	
	return true

func open_or_launch_project(path: String) -> bool:
	if is_project_loaded and path.simplify_path() == project_path.simplify_path():
		EditorServer.popup_save_option_or_save(open_project.bind(path), "Save & Open")
		return true
	
	if is_project_loaded:
		return launch_project(path)
	
	return open_project(path)

func save() -> void:
	var project_paths: Dictionary[StringName, String] = _get_project_paths(project_path)
	
	ResourceSaver.save(import_file_system, project_paths.import_sys)
	ResourceSaver.save(preset_file_system, project_paths.preset_sys)
	ResourceSaver.save(project_res, project_paths.project_res)
	
	GlobalServer.save_global()
	
	saved_version = undo_redo.get_version()
	
	EditorServer.update_title()
	EditorServer.push_message("Saved", EditorServer.MessageMode.MESSAGE_MODE_IDLE)


func save_as(dir_path: String) -> void:
	
	if DirAccess.dir_exists_absolute(dir_path):
		EditorServer.push_message("There is already a folder with the same name.", EditorServer.MessageMode.MESSAGE_MODE_WARNING)
		return
	
	if not DirAccessHelper.copy_recursive(project_path, dir_path):
		EditorServer.push_message("Error saving as a new version.")
		return
	
	var new_proj_res_path: String = dir_path + "/project.res"
	var new_project_res: ProjectRes = ResourceLoader.load(new_proj_res_path)
	if not new_project_res:
		EditorServer.push_message("Problem opening new Project file.")
		return
	
	new_project_res.project_name = dir_path.get_file()
	ResourceSaver.save(new_project_res, new_proj_res_path)
	
	open_project(dir_path)
	
	EditorServer.push_message("Saved as", EditorServer.MessageMode.MESSAGE_MODE_IDLE)


func undo() -> void:
	if not undo_redo.has_undo(): return
	var action_name: String = undo_redo.get_current_action_name().capitalize()
	undo_redo.undo()
	EditorServer.update_title()
	EditorServer.push_message("Undo %s" % action_name, EditorServer.MessageMode.MESSAGE_MODE_IDLE)

func redo() -> void:
	if not undo_redo.has_redo(): return
	undo_redo.redo()
	EditorServer.update_title()
	EditorServer.push_message("Redo %s" % undo_redo.get_current_action_name().capitalize(), EditorServer.MessageMode.MESSAGE_MODE_IDLE)

func commit_action(action_name: String, do_method: Callable, undo_method: Callable, execute: bool = true) -> void:
	undo_redo.create_action(action_name)
	undo_redo.add_do_method(do_method)
	undo_redo.add_undo_method(undo_method)
	undo_redo.commit_action(execute)
	EditorServer.update_title()

func _get_project_paths(_project_path: String) -> Dictionary[StringName, String]:
	return {
		&"project_res": _project_path.path_join("project.res"),
		&"import_sys": _project_path.path_join("import_file_sys.res"),
		&"preset_sys": _project_path.path_join("preset_file_sys.res")
	}

func _get_launch_args(project_path: String) -> PackedStringArray:
	if OS.has_feature("editor"):
		var godot_project_path: String = ProjectSettings.globalize_path("res://")
		return ["--path", godot_project_path, "--", project_path]
	else:
		return [project_path]

func _check_for_project_file_exist(project_path: String) -> bool:
	if not FileAccess.file_exists(project_path):
		EditorServer.push_message("The project file 'project.res' was not found in the correct path.", EditorServer.MessageMode.MESSAGE_MODE_WARNING)
		return false
	return true


func open_clip_res(clip_res: MediaClipRes) -> void:
	var old_one: MediaClipRes = null if opened_clip_res_path.is_empty() else opened_clip_res_path.back()
	opened_clip_res_path.append(clip_res)
	opened_clip_res_changed.emit(old_one, clip_res)

func try_exit_clip_res(times: int = 1) -> void:
	if times == 0: return
	times = mini(times, opened_clip_res_path.size() - 1)
	var old_one: MediaClipRes = opened_clip_res_path.back()
	for i: int in times:
		opened_clip_res_path.pop_back()
	emit_opened_clip_res_changed(old_one, opened_clip_res_path.back())

func emit_opened_clip_res_changed(old_one: MediaClipRes, new_one: MediaClipRes) -> void:
	opened_clip_res_changed.emit(old_one, new_one)
