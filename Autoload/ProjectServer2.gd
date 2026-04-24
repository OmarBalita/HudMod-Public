extends Node

signal project_opened(project_res: ProjectRes)
signal open_project_finished()

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
var import_file_system: DisplayFileSystemRes
var preset_file_system: DisplayFileSystemRes

var fps: int
var delta: float

var opened_clip_res_path: Array[MediaClipRes]


# Project Management
# ---------------------------------------------------

func new_project(project_res: ProjectRes, dir_path: String) -> ProjectRes:
	
	if Renderer.is_working:
		Renderer.cancel()
	
	if DirAccess.dir_exists_absolute(dir_path):
		printerr("There is already a folder or file with the same name; please change the name or path.")
		return null
	
	var project_path: String = dir_path.simplify_path()
	var paths: Dictionary[StringName, String] = ProjectServer2._get_project_paths(project_path)
	
	if DirAccess.make_dir_recursive_absolute(dir_path) != Error.OK:
		printerr("Problem creating project folder.")
		return null
	
	project_res.root_clip_res = RootClipRes.new()
	
	if ResourceSaver.save(project_res, paths.project_res) != Error.OK:
		printerr("Problem save project resource.")
		return null
	
	ResourceSaver.save(DisplayFileSystemRes.new(), paths.import_sys)
	ResourceSaver.save(DisplayFileSystemRes.new(), paths.preset_sys)
	
	EditorServer.popup_save_option_or_save(open_project.bind(project_path), "Save & Open")
	
	return project_res

func open_project(_project_path: String) -> bool:
	
	var project_paths: Dictionary[StringName, String] = _get_project_paths(_project_path)
	
	if not FileAccess.file_exists(project_paths.project_res):
		printerr("The project file 'project.res' was not found in the correct path.")
		return false
	
	var _temp_prj_path:= project_path
	var _temp_imp_file_sys:= import_file_system
	var _temp_pre_file_sys:= preset_file_system
	
	project_path = _project_path
	
	import_file_system = ResLoadHelper.load_or_save(project_paths.import_sys, DisplayFileSystemRes)
	preset_file_system = ResLoadHelper.load_or_save(project_paths.preset_sys, DisplayFileSystemRes)
	
	import_file_system.thumbnail_path = project_thumbnail_path
	import_file_system.waveform_path = project_waveform_path
	
	is_project_loaded = false
	
	var _project_res: Resource = ResourceLoader.load(project_paths.project_res)
	if _project_res is not ProjectRes:
		project_path = _temp_prj_path
		import_file_system = _temp_imp_file_sys
		preset_file_system = _temp_pre_file_sys
		is_project_loaded = true
		printerr("The project could not be opened.")
		return false
	
	Scene2.clear_nodes()
	MediaCache.clear_all_cache()
	
	opened_clip_res_path.clear()
	
	project_res = _project_res
	
	MediaCache.load_media_cache_from_file_system(import_file_system)
	MediaCache.load_media_cache_from_file_system(preset_file_system)
	GlobalServer.load_global()
	
	project_res.root_clip_res.loop_layers_children_deep(
		{},
		func(layers: Array[LayerRes], layer_idx: int, layer: LayerRes, frame: int, dupl_info: Dictionary[StringName, Variant]) -> void:
			var clip_res: MediaClipRes = layer.clips[frame]
			clip_res.layer_index = layer_idx
			clip_res.clip_pos = frame
			clip_res.loop_components(
				func(comp: ComponentRes) -> void:
					comp.set_owner_from_loader(clip_res)
					comp.loop_animations(frame,
						func(usable_res: UsableRes, anim_res: AnimationRes, property_key: StringName, frame: int) -> void:
							anim_res.update_funcs()
					)
			)
			if clip_res is Display2DClipRes:
				clip_res.build_shader_pipeline()
	)
	
	PlaybackServer.position = -INF
	
	EditorServer.editor_settings.update_internal_props_base_on_project()
	
	project_res.root_clip_res.update_paths_deep()
	project_res.root_clip_res.update_root_length()
	
	is_project_loaded = true
	project_opened.emit(project_res)
	
	open_clip_res(project_res.root_clip_res)
	
	PlaybackServer.position = 0
	
	return true


func save() -> void:
	var project_paths: Dictionary[StringName, String] = _get_project_paths(project_path)
	ResourceSaver.save(import_file_system, project_paths.import_sys)
	ResourceSaver.save(preset_file_system, project_paths.preset_sys)
	ResourceSaver.save(project_res, project_paths.project_res)
	GlobalServer.save_global()
	MediaServer.save_not_saved_yet()
	MediaServer.delete_not_deleted_yet()

func save_as(dir_path: String) -> void:
	
	if DirAccess.dir_exists_absolute(dir_path):
		printerr("There is already a folder with the same name")
		return
	
	if not DirAccessHelper.copy_recursive(project_path, dir_path):
		printerr("Error saving as a new version")
		return
	
	var new_proj_res_path: String = dir_path + "/project.res"
	var new_project_res: ProjectRes = ResourceLoader.load(new_proj_res_path)
	if not new_project_res:
		printerr("Problem opening new Project file")
		return
	
	new_project_res.project_name = dir_path.get_file()
	ResourceSaver.save(new_project_res, new_proj_res_path)
	
	open_project(dir_path)


func undo() -> void:
	pass

func redo() -> void:
	pass



func _get_project_paths(_project_path: String) -> Dictionary[StringName, String]:
	return {
		&"project_res": _project_path + "/project.res",
		&"import_sys": _project_path + "/import_file_sys.res",
		&"preset_sys": _project_path + "/preset_file_sys.res"
	}

func open_clip_res(clip_res: MediaClipRes) -> void:
	var old_one: MediaClipRes = null if opened_clip_res_path.is_empty() else opened_clip_res_path.back()
	opened_clip_res_path.append(clip_res)
	opened_clip_res_changed.emit(old_one, clip_res)

func try_exit_clip_res(times: int = 1) -> void:
	if times == 0: return
	times = min(times, opened_clip_res_path.size() - 1)
	var old_one: MediaClipRes = opened_clip_res_path.back()
	for i: int in times:
		opened_clip_res_path.pop_back()
	emit_opened_clip_res_changed(old_one, opened_clip_res_path.back())

func emit_opened_clip_res_changed(old_one: MediaClipRes, new_one: MediaClipRes) -> void:
	opened_clip_res_changed.emit(old_one, new_one)



