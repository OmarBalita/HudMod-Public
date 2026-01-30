class_name DirAccessHelper extends Object

# written by Gemini
static func remove_directory_recursive(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
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
		printerr("Removed directory: {path}".format(path))
	else:
		printerr("An error occurred when trying to access the path: {path}".format({"path": path}))

static func create_unique_path(path: String) -> String:
	if not FileAccess.file_exists(path):
		return path
	
	var extension: String = path.get_extension()
	var base_path: String = path.get_basename()
	
	var counter: int = 1
	var new_path: String = path
	
	while FileAccess.file_exists(new_path):
		new_path = base_path + "_" + str(counter) + "." + extension
		counter += 1
	
	return new_path


