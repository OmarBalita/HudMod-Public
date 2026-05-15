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
class_name DirAccessHelper extends Object

# written by Gemini
static func remove_directory_recursive(path: String) -> bool:
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
		return true
	else:
		EditorServer.push_message("An error occurred when trying to access the path: {path}".format({"path": path}))
		return false

# Written by Gemini
static func copy_recursive(from_dir: String, to_dir: String) -> bool:
	var dir: DirAccess = DirAccess.open(from_dir)
	
	if not dir:
		EditorServer.push_message("Can't open source folder: " + from_dir)
		return false
	
	if not DirAccess.dir_exists_absolute(to_dir):
		DirAccess.make_dir_recursive_absolute(to_dir)
	
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while not file_name.is_empty():
		if file_name != "." and file_name != "..":
			var old_path: String = from_dir.path_join(file_name)
			var new_path: String = to_dir.path_join(file_name)
			
			if dir.current_is_dir():
				copy_recursive(old_path, new_path)
			else:
				DirAccess.copy_absolute(old_path, new_path)
		
		file_name = dir.get_next()
	
	return true

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

static func get_files_names_at(dir_path: String) -> PackedStringArray:
	var files_names: PackedStringArray
	for path: String in DirAccess.get_files_at(dir_path):
		files_names.append(path.get_file().split(".")[0])
	return files_names
