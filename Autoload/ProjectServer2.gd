extends Node

signal project_opened(project_res: ProjectRes)

signal opened_clip_res_changed(old_one: MediaClipRes, new_one: MediaClipRes)

const EXAMPLE_PATH: String = "res://ExampleProject/"

var project_path: String:
	set(val):
		project_path = val
		project_editor_path = project_path + "editor/"
		project_thumbnail_path = project_path + "image/thumbnail/"
		project_waveform_path = project_path + "image/waveform/"
		project_media_path = project_path + "media/"
		project_preset_path = project_path + "preset/"

var project_editor_path: String
var project_thumbnail_path: String
var project_waveform_path: String
var project_media_path: String
var project_preset_path: String

var project_res: ProjectRes:
	set(val):
		project_res = val
		fps = project_res.fps
		delta = project_res.delta
		project_opened.emit(project_res)
var import_file_system: DisplayFileSystemRes
var preset_file_system: DisplayFileSystemRes

var fps: int
var delta: float

var opened_clip_res_path: Array[MediaClipRes]

func _ready() -> void:
	open_project(EXAMPLE_PATH)

func open_project(_project_path: String) -> void:
	
	if not GlobalServer.is_global_cache_loaded:
		await GlobalServer.is_global_cache_loaded
	
	var project_paths: Dictionary[StringName, String] = _get_project_paths(_project_path)
	
	if not FileAccess.file_exists(project_paths.project_res):
		printerr("The project file 'project.res' was not found in the correct path.")
		return
	
	project_path = _project_path
	
	import_file_system = ResLoadHelper.load_or_save(project_paths.import_sys, DisplayFileSystemRes)
	preset_file_system = ResLoadHelper.load_or_save(project_paths.preset_sys, DisplayFileSystemRes)
	
	import_file_system.thumbnail_path = project_thumbnail_path
	import_file_system.waveform_path = project_waveform_path
	
	MediaCache.load_media_cache_from_file_system(import_file_system)
	MediaCache.load_media_cache_from_file_system(preset_file_system)
	
	var _project_res: Resource = ResourceLoader.load(project_paths.project_res)
	if _project_res is not ProjectRes:
		printerr("The project could not be opened.")
		return
	
	project_res = _project_res
	
	project_res.root_clip_res.loop_layers_children_deep(
		{},
		func(layers: Array[LayerRes], layer_idx: int, layer: LayerRes, frame: int, dupl_info: Dictionary[StringName, Variant]) -> void:
			var clip_res: MediaClipRes = layer.clips[frame]
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
	EditorServer.editor_settings.update_settings_base_on_project()
	
	project_res.root_clip_res.update_root_length()
	open_clip_res(project_res.root_clip_res)


func save_project() -> void:
	var project_paths: Dictionary[StringName, String] = _get_project_paths(project_path)
	ResourceSaver.save(import_file_system, project_paths.import_sys)
	ResourceSaver.save(preset_file_system, project_paths.preset_sys)
	ResourceSaver.save(project_res, project_paths.project_res)

func _get_project_paths(_project_path: String) -> Dictionary[StringName, String]:
	return {
		&"project_res": _project_path + "project.res",
		&"import_sys": _project_path + "import_file_sys.res",
		&"preset_sys": _project_path + "preset_file_sys.res"
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






