class_name DirAccessHelper extends Object

# written by Gemini
static func remove_directory_recursive(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue

			var file_path = path.path_join(file_name)
			if dir.current_is_dir():
				remove_directory_recursive(file_path)
			else:
				DirAccess.remove_absolute(file_path)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		DirAccess.remove_absolute(path)
		print("Removed directory: {path}")
	else:
		print("An error occurred when trying to access the path: {path}")
