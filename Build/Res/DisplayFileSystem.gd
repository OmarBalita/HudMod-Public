class_name DisplayFileSystemRes extends Resource

@export var files: Dictionary = {}

var thumbnail_path: String
var waveform_path: String

func get_files() -> Dictionary: return files
func set_files(new_val: Dictionary): return files

func get_used_ids() -> PackedStringArray:
	return EditorServer.get_ids_from_pathes(DirAccess.get_files_at(thumbnail_path))

func create_folder(display_path: Array, folder_name: String) -> void:
	create_folder_at(get_dir(display_path), folder_name)

func create_folders(display_path: Array, folders_names: PackedStringArray) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	for name: String in folders_names: create_folder_at(curr_dir, name)

func add_folders(display_path: Array, folders: Dictionary[String, Dictionary]) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	for name: String in folders:
		if curr_dir.has(name): continue
		curr_dir[name] = folders[name]

func create_folder_at(dir: Dictionary, folder_name: String) -> void:
	if dir.has(folder_name): return
	dir[folder_name.validate_filename()] = {
		&"type": "folder",
		&"forward": {},
		&"date": Time.get_unix_time_from_system()
	}

func create_file(display_path: Array, file_path: String) -> MediaCache.LOAD_ERR:
	var used_ids: PackedStringArray = get_used_ids()
	var new_id: String = StringHelper.generate_new_id(used_ids, 8)
	return create_file_at(get_dir(display_path), file_path, used_ids, new_id)

func create_files(display_path: Array, files_pathes: PackedStringArray) -> Array[MediaCache.LOAD_ERR]:
	var result: Array[MediaCache.LOAD_ERR]
	
	var curr_dir: Dictionary = get_dir(display_path)
	var used_ids: PackedStringArray = get_used_ids()
	
	for file_path: String in files_pathes:
		var new_id: String = StringHelper.generate_new_id(used_ids, 8)
		create_file_at(curr_dir, file_path, used_ids, new_id)
	
	return result


func create_file_at(dir: Dictionary, file_path: String, used_ids: PackedStringArray, file_id: String) -> MediaCache.LOAD_ERR:
	var media_type_result: MediaCache.LOAD_ERR = MediaCache.register_from_path(file_path, used_ids, file_id, thumbnail_path, waveform_path)
	if media_type_result == MediaCache.LOAD_ERR.SUCCESS:
		dir[file_path] = {
			&"type": "file",
			&"media_type": MediaServer.get_media_type_from_path(file_path),
			&"date": Time.get_unix_time_from_system(),
			&"id": file_id # ID used to find any file information like thumb or waveform .. in RealFileSystem
		}
		used_ids.append(file_id)
	return media_type_result

func delete(display_path: Array, path_or_name: String, delete_real_file: bool) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	_delete(curr_dir, path_or_name, delete_real_file)
	curr_dir.erase(path_or_name)

func delete_packed(display_path: Array, pathes_or_names: PackedStringArray, delete_real_file: bool) -> void:
	var curr_dir: Dictionary = get_dir(display_path)
	for path_or_name: String in pathes_or_names:
		_delete(curr_dir, path_or_name, delete_real_file)

func _delete(dir: Dictionary, path_or_name: String, delete_real_file: bool) -> void:
	var info: Dictionary = dir[path_or_name]
	
	if info.type == "file":
		var file_id: String = info.id
		MediaCache.deregister_from_path(path_or_name, file_id, thumbnail_path, waveform_path)
		if delete_real_file: MediaServer.store_not_deleted_resource(path_or_name)
	else:
		_loop_files_at({}, func(_dir: Dictionary, _path_or_name: String, _file_info: Dictionary, _info: Dictionary[StringName, Variant]) -> void:
			if _file_info.type == "file":
				MediaCache.deregister_from_path(_path_or_name, _file_info.type, thumbnail_path, waveform_path)
				if delete_real_file: MediaServer.store_not_deleted_resource(_path_or_name), info.forward
		)
	
	dir.erase(path_or_name)

func replace_file(dir: Dictionary, from: String, to: String, discard_option: bool) -> void:
	var file_info: Dictionary = dir[from]
	if FileAccess.file_exists(to):
		dir[to] = file_info
		dir.erase(from)
		MediaCache.register_from_path(to, [], file_info.id, thumbnail_path, waveform_path)
	elif discard_option:
		discard_file(file_info, from)

func discard_file(file_info: Dictionary, key_as_path: String) -> void:
	file_info.set(&"discard", true)
	MediaCache.deregister_from_path(key_as_path, file_info.id, thumbnail_path, waveform_path)

func replace_paths(paths_for_replace: Dictionary[String, String], discard_option: bool) -> void:
	loop_directories({},
		func(dir: Dictionary, info: Dictionary[StringName, Variant]) -> void:
			var dir_keys: Array = dir.keys()
			for old_key: String in dir_keys:
				if paths_for_replace.has(old_key):
					var new_key: String = paths_for_replace[old_key]
					replace_file(dir, old_key, new_key, discard_option)
	)

func discard_paths(paths: PackedStringArray) -> void:
	loop_directories({}, func(dir: Dictionary, info: Dictionary[StringName, Variant]) -> void:
			for path: String in paths: if dir.has(path): discard_file(dir[path], path)
	)

func check_for_discard_paths() -> void:
	loop_files_deep({}, func(dir: Dictionary, path_or_name: String, file_info: Dictionary, info: Dictionary[StringName, Variant]) -> void:
		if file_info.type == "file":
			if file_info.has(&"discard"):
				if FileAccess.file_exists(path_or_name):
					file_info.erase(&"discard")
					MediaCache.register_from_path(path_or_name, [], file_info.id, thumbnail_path, waveform_path)
	)

func get_files_and_folders_at(display_path: Array) -> Dictionary:
	return get_dir(display_path)

func get_dir(display_path: Array) -> Variant:
	var curr_dir: Dictionary = files
	for index: int in display_path.size():
		var next_dir: String = display_path[index]
		if not curr_dir.has(next_dir):
			return null
		curr_dir = curr_dir.get(next_dir).forward
	return curr_dir

func get_file(display_path: Array) -> Variant:
	display_path = display_path.duplicate()
	var filename: String = display_path.pop_back()
	var parent_dir: Variant = get_dir(display_path)
	return parent_dir.get(filename)

func path_exists(path: Array) -> bool: return get_file(path) != null
func is_file(path: Array) -> bool: return get_file(path).type == "file"
func is_folder(path: Array) -> bool: return get_file(path).type == "folder"

func loop_files_deep(info: Dictionary[StringName, Variant], method: Callable) -> Dictionary[StringName, Variant]:
	_loop_files_at(info, method, files)
	return info

func _loop_files_at(info: Dictionary[StringName, Variant], method: Callable, dir: Dictionary) -> void:
	for path_or_name: String in dir:
		var file_info: Dictionary = dir[path_or_name]
		method.call(dir, path_or_name, file_info, info)
		if file_info.type == "folder":
			_loop_files_at(info, method, file_info.forward)

func get_directories() -> Array[Dictionary]:
	return get_directories_at(files)

func get_directories_at(dir: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = [dir]
	for path_or_name: String in dir:
		var info: Dictionary = dir[path_or_name]
		if info.type == "folder":
			result += get_directories_at(info.forward)
	return result

func loop_directories(info: Dictionary[StringName, Variant], method: Callable) -> Dictionary[StringName, Variant]:
	var dirs: Array[Dictionary] = get_directories()
	for dir: Dictionary in dirs: method.call(dir, info)
	return info

func get_files_paths() -> PackedStringArray:
	return loop_files_deep({&"files_paths": PackedStringArray()}, func(dir: Dictionary, path_or_name: String, file_info: Dictionary, info: Dictionary[StringName, Variant]) -> void:
		if file_info.type == "file":
			if not file_info.has(&"discard"):
				info.files_paths.append(path_or_name)
	).files_paths


func preset_media_ress_check_for_paths(paths: PackedStringArray) -> PackedStringArray:
	var preset_ress: Dictionary[StringName, MediaClipRes] = MediaCache.preset_media_ress
	return loop_files_deep({&"unexistent": PackedStringArray()}, func(dir: Dictionary, path: String, file_info: Dictionary, info: Dictionary[StringName, Variant]) -> void:
		path = StringName(path)
		if file_info.type == "file":
			if preset_ress.has(path):
				info.unexistent.append_array(preset_ress[path].check_children_for_paths_deep(paths))
	).unexistent

func preset_media_ress_format_paths(paths_for_format: Dictionary[String, String]) -> void:
	var preset_ress: Dictionary[StringName, MediaClipRes] = MediaCache.preset_media_ress
	loop_files_deep({}, func(dir: Dictionary, path: String, file_info: Dictionary, info: Dictionary[StringName, Variant]) -> void:
		path = StringName(path)
		if file_info.type == "file":
			if preset_ress.has(path):
				preset_ress[path].format_children_paths_deep(paths_for_format)
	)

# 0 = FOLDER_TREE, 1 = FILE_TREE
func build_tree(tree: Tree, root_name: StringName = "Fake Filesystem", tree_type: int = 0, selected_path: Array = [], filter: PackedStringArray = []) -> void:
	tree.clear()
	var root_item: TreeItem = tree.create_item()
	root_item.set_text(0, root_name)
	root_item.set_icon(0, IS.TEXTURE_FOLDER)
	root_item.set_metadata(0, [])
	_continue_tree(files, tree, root_item, [], tree_type, selected_path, filter)
	
	if selected_path.is_empty(): root_item.select(0)

func _continue_tree(files: Dictionary, tree: Tree, parent_item: TreeItem, display_path: Array = [], tree_type: int = 0, selected_path: Array = [], filter: PackedStringArray = []) -> void:
	for path_or_name: String in files:
		var file_info: Dictionary = files[path_or_name]
		
		if file_info.type == "folder":
			var folder_displ_path: Array = display_path + [path_or_name]
			var forward: Dictionary = file_info.forward
			
			var tree_item: TreeItem = _create_tree_item(tree, parent_item, path_or_name, IS.TEXTURE_FOLDER, folder_displ_path)
			_continue_tree(forward, tree, tree_item, folder_displ_path)
			if folder_displ_path == selected_path: tree_item.select(0)
		
		elif tree_type == 1:
			if filter.has(path_or_name.get_extension()):
				var file_displ_path: Array = display_path + [path_or_name]
				var tree_item: TreeItem = _create_tree_item(tree, parent_item, path_or_name.get_file(), MediaServer.get_thumbnail(path_or_name).texture, file_displ_path)
				if file_displ_path == selected_path: tree_item.select(0)

func _create_tree_item(tree: Tree, parent_item: TreeItem, text: String, icon: Texture2D, display_path: Array) -> TreeItem:
	var tree_item: TreeItem = tree.create_item(parent_item)
	tree_item.set_text(0, text)
	tree_item.set_icon(0, icon)
	tree_item.set_metadata(0, display_path)
	return tree_item

