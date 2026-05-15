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
class_name FileSystem extends Resource

enum EntityType {
	FILE = 0,
	FOLDER = 1
}

@export var root: Dictionary

var thumbnail_path: String: set = _set_thumbnail_path
var waveform_path: String

var already_exists_ids: PackedStringArray

func _set_thumbnail_path(new_val: String) -> void:
	thumbnail_path = new_val
	_update_already_exists_ids()

func _update_already_exists_ids() -> void:
	already_exists_ids = get_already_exists_ids_by_collect()

func get_root() -> Dictionary: return root
func set_root(new_root: Dictionary) -> void: root = new_root

func get_already_exists_ids_by_collect() -> PackedStringArray:
	var result: PackedStringArray
	
	return result

func navigate_to_dir(dir_path: PackedStringArray) -> Variant:
	var curr_dir: Dictionary = root
	for index: int in dir_path.size():
		var next_dir: String = dir_path[index]
		if not curr_dir.has(next_dir):
			return null
		curr_dir = curr_dir.get(next_dir).forward
	return curr_dir

func create_files(target_dir: PackedStringArray, files_paths: PackedStringArray) -> Array[MediaCache.LOAD_ERR]:
	var result: Array[MediaCache.LOAD_ERR]
	
	var dir: Dictionary = navigate_to_dir(target_dir)
	
	for file_path: String in files_paths:
		result.append(_create_file(dir, file_path))
	
	return result


func _create_file(dir: Dictionary, file_path: String) -> MediaCache.LOAD_ERR:
	var new_id: String = StringHelper.generate_new_id(already_exists_ids)
	var expected_media_type: int = MediaServer.get_media_type_from_path(file_path)
	var register_or_load_err: MediaCache.LOAD_ERR = MediaCache.register_from_path(file_path, already_exists_ids, new_id, expected_media_type, thumbnail_path, waveform_path)
	
	if register_or_load_err == MediaCache.LOAD_ERR.SUCCESS:
		dir[file_path] = {
			&"t": EntityType.FILE,
			&"import_t": expected_media_type,
			&"id": new_id,
			&"data": Time.get_unix_time_from_system()
		}
		already_exists_ids.append(new_id)
	
	return register_or_load_err


func create_folders(target_dir: PackedStringArray, folders_names: PackedStringArray) -> void:
	var dir: Dictionary = navigate_to_dir(target_dir)
	
	for folder_name: String in folders_names:
		
		if dir.has(folder_name):
			continue
		
		dir[folder_name.validate_filename()] = {
			&"t": EntityType.FOLDER,
			&"forward": {},
			&"date": Time.get_unix_time_from_system()
		}

func delete_packet(target_dir: PackedStringArray, paths_or_names: PackedStringArray) -> void:
	var dir: Dictionary = navigate_to_dir(target_dir)
	
	for path_or_name: String in paths_or_names:
		_delete(dir, path_or_name)

func _delete(dir: Dictionary, path_or_name: StringName) -> void:
	var entity_info: Dictionary = dir[path_or_name]
	
	if entity_info.t == EntityType:
		var file_id: String = entity_info.id
		MediaCache.deregister_from_path(path_or_name, file_id, thumbnail_path, waveform_path, false)
	
	else:
		
		var forward: Dictionary = entity_info.forward
		var keys_for_delete: PackedStringArray = forward.keys()
		
		for _path_or_name: String in keys_for_delete:
			_delete(forward, _path_or_name)
	
	dir.erase(path_or_name)


func replace_paths(paths_for_replace: Dictionary[String, String], discard_option: bool) -> void:
	
	loop_directories_deep_at(root,
		func(dir: Dictionary, metadata: Dictionary[StringName, Variant]) -> void:
			
			for main_path_or_name: String in dir:
				if paths_for_replace.has(main_path_or_name):
					var new_path_or_name: String = paths_for_replace[main_path_or_name]
					
					if FileAccess.file_exists(new_path_or_name):
						_delete(dir, main_path_or_name)
						_create_file(dir, new_path_or_name)
					
					elif discard_option:
						_discard_file(dir, main_path_or_name)
	)

func discard_paths(paths_for_discard: PackedStringArray) -> void:
	loop_directories_deep_at(root,
		func(dir: Dictionary, info: Dictionary[StringName, Variant]) -> void:
			for path: String in paths_for_discard:
				if dir.has(path): _discard_file(dir, path)
	)

func _discard_file(dir: Dictionary, file_path: String) -> void:
	var entity_info: Dictionary = dir[file_path]
	if entity_info.t == EntityType.FILE:
		entity_info.set(&"discard", true)
		MediaCache.deregister_from_path(file_path, entity_info.id, thumbnail_path, waveform_path)


func check_for_discard_paths() -> void:
	
	loop_directories_deep_at(root,
		func(dir: Dictionary, metadata: Dictionary[StringName, Variant]) -> void:
			for path_or_name: String in dir:
				var entity_info: Dictionary = dir[path_or_name]
				if entity_info.t != EntityType.FILE:
					continue
				if not FileAccess.file_exists(path_or_name):
					continue
				entity_info.erase(&"discard")
				MediaCache.register_from_path(path_or_name, already_exists_ids, entity_info.id, entity_info.import_t, thumbnail_path, waveform_path)
	)


func get_directories_deep_at(dir: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = [dir]
	for path_or_name: String in dir:
		var entity_info: Dictionary = dir[path_or_name]
		if entity_info.t == EntityType.FOLDER:
			result += get_directories_deep_at(entity_info.forward)
	return result

func loop_directories_deep_at(dir: Dictionary, method: Callable, metadata: Dictionary[StringName, Variant] = {}) -> Dictionary[StringName, Variant]:
	var directories_deep: Array[Dictionary]
	for _dir: Dictionary in directories_deep:
		method.call(_dir, metadata)
	return metadata


func build_tree(tree: Tree, root_name: StringName = &"Fake Filesystem", tree_type: int = 0, selected_path: Array = [], filter: PackedStringArray = []) -> void:
	tree.clear()
	var root_item: TreeItem = tree.create_item()
	root_item.set_text(0, root_name)
	root_item.set_icon(0, IS.TEXTURE_FOLDER)
	root_item.set_metadata(0, [])
	_continue_tree(root, tree, root_item, [], tree_type, selected_path, filter)
	if selected_path.is_empty(): root_item.select(0)

func _continue_tree(files: Dictionary, tree: Tree, parent_item: TreeItem, display_path: Array = [], tree_type: int = 0, selected_path: Array = [], filter: PackedStringArray = []) -> void:
	for path_or_name: String in files:
		var entity_info: Dictionary = files[path_or_name]
		
		if entity_info.t == EntityType.FOLDER:
			var folder_displ_path: Array = display_path + [path_or_name]
			var forward: Dictionary = entity_info.forward
			var tree_item: TreeItem = _create_tree_item(tree, parent_item, path_or_name, IS.TEXTURE_FOLDER, folder_displ_path)
			_continue_tree(forward, tree, tree_item, folder_displ_path)
			
			if folder_displ_path == selected_path:
				tree_item.select(0)
		
		elif tree_type == 1:
			
			if filter.has(path_or_name.get_extension()):
				var file_displ_path: Array = display_path + [path_or_name]
				var tree_item: TreeItem = _create_tree_item(tree, parent_item, path_or_name.get_file(), MediaServer.get_thumbnail(path_or_name).texture, file_displ_path)
				
				if file_displ_path == selected_path:
					tree_item.select(0)

func _create_tree_item(tree: Tree, parent_item: TreeItem, text: String, icon: Texture2D, display_path: Array) -> TreeItem:
	var tree_item: TreeItem = tree.create_item(parent_item)
	tree_item.set_text(0, text)
	tree_item.set_icon(0, icon)
	tree_item.set_metadata(0, display_path)
	return tree_item



