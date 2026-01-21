class_name DisplayFileSystemRes extends Resource

@export var files: Dictionary = {}

func get_files() -> Dictionary: return files
func set_files(new_val: Dictionary): return files

func create_folder(display_path: Array, folder_name: String) -> void:
	create_folder_at(get_dir(display_path), folder_name)

func create_folders(display_path: Array, folders_names: PackedStringArray) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	for name: String in folders_names: create_folder_at(curr_dir, name)

func create_folder_at(dir: Dictionary, folder_name: String) -> void:
	dir[folder_name] = {
		&"type": "folder",
		&"forward": {},
		&"date": Time.get_unix_time_from_system()
	}

func create_file(display_path: Array, file_path: String, thumbnail_path: String, waveform_path: String) -> void:
	var used_ids: PackedStringArray = EditorServer.get_ids_from_pathes(DirAccess.get_files_at(thumbnail_path))
	var new_id: String = ProjectServer.generate_new_id(used_ids, 8)
	create_file_at(get_dir(display_path), file_path, used_ids, new_id, thumbnail_path, waveform_path)
	used_ids.append(new_id)

func create_files(display_path: Array, files_pathes: PackedStringArray, thumbnail_path: String, waveform_path: String) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	var used_ids: PackedStringArray = EditorServer.get_ids_from_pathes(DirAccess.get_files_at(thumbnail_path))
	for file_path: String in files_pathes:
		var new_id: String = ProjectServer.generate_new_id(used_ids, 8)
		create_file_at(curr_dir, file_path, used_ids, new_id, thumbnail_path, waveform_path)
		used_ids.append(new_id)

func create_file_at(dir: Dictionary, file_path: String, used_ids: PackedStringArray, file_id: String, thumbnail_path: String, waveform_path: String) -> void:
	var media_type_result: int = MediaCache.register_from_path(file_path, used_ids, file_id, thumbnail_path, waveform_path)
	dir[file_path] = {
		&"type": "file",
		&"media_type": media_type_result,
		&"date": Time.get_unix_time_from_system(),
		&"id": file_id # ID used to find any file information in RealFileSystem
	}

func delete(display_path: Array, path_or_name: String, thumbnail_path: String, waveform_path: String, delete_real_file: bool) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	delete_file_images(curr_dir, path_or_name, thumbnail_path, waveform_path)
	curr_dir.erase(path_or_name)
	if delete_real_file:
		MediaServer.store_not_deleted_resource(path_or_name)

func delete_packed(display_path: Array, pathes_or_names: PackedStringArray, thumbnail_path: String, waveform_path: String, delete_real_file: bool) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	for path_or_name: String in pathes_or_names:
		delete_file_images(curr_dir, path_or_name, thumbnail_path, waveform_path)
		curr_dir.erase(path_or_name)
		if delete_real_file:
			MediaServer.store_not_deleted_resource(path_or_name)

func delete_file_images(dir: Dictionary, media_path: String, thumbnail_path: String, waveform_path: String) -> void:
	var info: Dictionary = dir[media_path]
	if info.type == "file":
		DirAccess.remove_absolute(str(thumbnail_path, info.id, ".png"))
		DirAccessHelper.remove_directory_recursive(str(waveform_path, info.id))

func get_files_and_folders_at(display_path: Array) -> Dictionary:
	return get_dir(display_path)

func get_dir(display_path: Array) -> Dictionary:
	var curr_dir: Dictionary = files
	for index: int in display_path.size():
		var next_dir: String = display_path[index]
		if not curr_dir.has(next_dir):
			break
		curr_dir = curr_dir.get(next_dir).forward
	return curr_dir

func loop_files_deep(info: Dictionary[StringName, Variant], method: Callable) -> Dictionary[StringName, Variant]:
	_loop_files_at(info, method, files)
	return info

func _loop_files_at(info: Dictionary[StringName, Variant], method: Callable, curr_files: Dictionary) -> void:
	for path_or_name: String in curr_files:
		var file_info: Dictionary = curr_files[path_or_name]
		method.call(path_or_name, file_info, info)
		if file_info.type == "folder":
			_loop_files_at(info, method, file_info.forward)
