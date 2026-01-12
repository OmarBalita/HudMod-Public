extends Node

var global_path: String = EditorServer.app_data_dir + "global/"
var global_thumbnail_path: String = global_path + "image/thumbnail/"
var global_waveform_path: String = global_path + "image/waveform/"
var global_media_path: String = global_path + "media/"
var global_preset_path: String = global_path + "preset/"
var IMPORT_FILE_SYSTEM_PATH: String = global_path + "file_system_import.res"
var PRESET_FILE_SYSTEM_PATH: String = global_path + "file_system_preset.res"

var import_file_system: DisplayFileSystemRes
var preset_file_system: DisplayFileSystemRes

func _init() -> void:
	make_global_dirs_abs()
	load_global()

func load_global() -> void:
	import_file_system = ResLoadHelper.load_or_save(IMPORT_FILE_SYSTEM_PATH, DisplayFileSystemRes)
	preset_file_system = ResLoadHelper.load_or_save(PRESET_FILE_SYSTEM_PATH, DisplayFileSystemRes)
	MediaCache.load_media_cache_from_file_system(import_file_system, global_thumbnail_path, global_waveform_path)

func save_global() -> void:
	make_global_dirs_abs()
	ResourceSaver.save(import_file_system, IMPORT_FILE_SYSTEM_PATH)
	ResourceSaver.save(preset_file_system, PRESET_FILE_SYSTEM_PATH)

func make_global_dirs_abs() -> void:
	EditorServer.make_dirs_abs(PackedStringArray([
		global_thumbnail_path,
		global_waveform_path,
		global_media_path,
		global_preset_path
	]))
