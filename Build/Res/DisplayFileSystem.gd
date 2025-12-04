class_name DisplayFileSystemRes extends Resource

@export var files: Dictionary = {}

func create_folder(display_path: Array, folder_name: String) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	curr_dir[folder_name] = {
		&"type": "folder",
		&"forward": {},
		&"date": Time.get_unix_time_from_system()
	}

func create_file(display_path: Array, file_path: String) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	var media_type_result: int = MediaCache.register_from_path(file_path)
	curr_dir[file_path] = {
		&"type": "file",
		&"media_type": media_type_result,
		&"date": Time.get_unix_time_from_system()
	}

func delete(display_path: Array, path_or_name: String) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	curr_dir.erase(path_or_name)

func get_files_and_folders_at(display_path: Array) -> Dictionary:
	var curr_dir: Dictionary = get_dir(display_path)
	return curr_dir

func get_dir(display_path: Array) -> Dictionary:
	var curr_dir: Dictionary = files
	for index: int in display_path.size():
		var next_dir: String = display_path[index]
		if not curr_dir.has(next_dir):
			break
		curr_dir = curr_dir.get(next_dir).forward
	return curr_dir



