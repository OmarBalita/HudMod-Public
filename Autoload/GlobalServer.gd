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
extends Node

signal global_cache_loaded()

var global_path: String = EditorServer.app_data_dir + "global/"
var global_thumbnail_path: String = global_path + "image/thumbnail/"
var global_waveform_path: String = global_path + "image/waveform/"
var global_media_path: String = global_path + "media/"
var global_preset_path: String = global_path + "preset/"

var import_file_system_path: String = global_path + "file_system_import.res"
var preset_file_system_path: String = global_path + "file_system_preset.res"
var global_usable_res_path: String = global_path + "global_usable_res.res"

var import_file_system: DisplayFileSystemRes
var preset_file_system: DisplayFileSystemRes
var global_usable_res: GlobalUsableRes:
	set(val):
		global_usable_res = val

var is_global_cache_loaded: bool = false

func _ready() -> void:
	make_global_dirs_abs()

func load_global() -> void:
	
	is_global_cache_loaded = false
	
	import_file_system = ResLoadHelper.load_or_save(import_file_system_path, DisplayFileSystemRes)
	preset_file_system = ResLoadHelper.load_or_save(preset_file_system_path, DisplayFileSystemRes)
	global_usable_res = ResLoadHelper.load_or_save(global_usable_res_path, GlobalUsableRes)
	
	import_file_system.thumbnail_path = global_thumbnail_path
	import_file_system.waveform_path = global_waveform_path
	
	MediaCache.load_media_cache_from_file_system(import_file_system)
	MediaCache.load_media_cache_from_file_system(preset_file_system)
	
	is_global_cache_loaded = true
	global_cache_loaded.emit()

func save_global() -> void:
	make_global_dirs_abs()
	ResourceSaver.save(import_file_system, import_file_system_path)
	ResourceSaver.save(preset_file_system, preset_file_system_path)
	ResourceSaver.save(global_usable_res, global_usable_res_path)

func make_global_dirs_abs() -> void:
	EditorServer.make_dirs_abs(PackedStringArray([
		global_thumbnail_path,
		global_waveform_path,
		global_media_path,
		global_preset_path
	]))

func until_load() -> void:
	if not is_global_cache_loaded:
		await global_cache_loaded

