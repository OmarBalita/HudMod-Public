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
class_name DisplayFileSystemPath extends UsableRes

enum SYSTEM_TYPE {
	PROJECT,
	GLOBAL
}

@export var import_type: int:
	set(val):
		import_type = val
		_update_media_func()
@export var sys_is_global: bool
@export var sys_path: Array:
	set(val):
		sys_path = val
		update_disk_path()

var disk_path: String
var get_media_func: Callable

func get_disk_path() -> String: return disk_path
func set_disk_path(new_val: String) -> void: disk_path = new_val

func _init() -> void:
	_update_media_func()

static func new_sys_path(_import_type: int = 0, _sys_is_global: bool = false, _sys_path: Array = []) -> DisplayFileSystemPath:
	var new_one:= DisplayFileSystemPath.new()
	new_one.import_type = _import_type
	new_one.sys_is_global = _sys_is_global
	new_one.sys_path = _sys_path
	return new_one

func update_disk_path() -> void:
	disk_path = sys_path.back() if is_valid_file() else ""
	if EditorServer.has_usable_res_controllers(self):
		var ctrlrs: Dictionary[StringName, Control] = EditorServer.get_usable_res_controllers(self)
		ctrlrs[&"disk_path"].set_curr_val(disk_path, true)
		ctrlrs[&"thumbnail"].texture = get_file_thumb()
		EditorServer.update_usable_res_ui_profile(self)

func get_file_sys() -> DisplayFileSystemRes:
	return EditorServer.get_import_file_system(sys_is_global)

func is_valid_file() -> bool:
	var file_sys:= get_file_sys()
	return sys_path and file_sys.path_exists(sys_path) and file_sys.is_file(sys_path)

func get_file_media() -> Variant:
	if get_media_func.is_valid():
		return get_media_func.call(disk_path)
	return null

func get_file_thumb() -> Texture2D:
	return MediaServer.get_thumbnail(disk_path).texture

func _update_media_func() -> void:
	match import_type:
		0: get_media_func = MediaCache.get_texture
		1: get_media_func = Callable()
		2: get_media_func = MediaCache.get_audio_data

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var thumbnail_rect: TextureRect = IS.create_texture_rect(get_file_thumb(), {
		custom_minimum_size = Vector2(.0, 180.),
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE,
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	})
	
	return {
		&"Select File": export_method(
			ExportMethodType.METHOD_CALLABLE,
			method_callable_args(_popup_selection_window)
		),
		&"Clear File": export_method(
			ExportMethodType.METHOD_CALLABLE,
			method_callable_args(
				func(displ_paths: Array[UsableRes]) -> void:
					for displ_path: DisplayFileSystemPath in displ_paths:
						displ_path.sys_is_global = false
						displ_path.sys_path.clear()
						displ_path.update_disk_path(),
				Color.DARK_RED
			),
			[func() -> bool: return disk_path.is_empty(), [false]]
		),
		&"disk_path": export(string_args(disk_path, 0, [], "[NO PATH SELECTED]", false), [], false),
		&"thumbnail": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, [thumbnail_rect])
	}

func _popup_selection_window(displ_paths: Array[UsableRes]) -> void:
	var main_window: Window = WindowManager.get_window()
	
	var update_func: Callable = func(files_tree: Tree, sys_is_global: bool, sys_path: Array) -> void:
		var filter: PackedStringArray = MediaServer.ARR_MEDIA_EXTENSIONS[import_type]
		EditorServer.get_import_file_system(sys_is_global).build_tree(files_tree, "Root", 1, sys_path, filter)
	
	var accept_func: Callable = func(_sys_is_global: bool, _sys_path: Array) -> void:
		var file_sys:= EditorServer.get_import_file_system(sys_is_global)
		if _sys_path and file_sys.is_file(_sys_path):
			for displ_path: DisplayFileSystemPath in displ_paths:
				displ_path.sys_is_global = _sys_is_global
				displ_path.sys_path = _sys_path
				displ_path.update_disk_path()
		else:
			var alert_win_cont: MarginContainer = WindowManager.popup_window(main_window)
			var alert_mess: Label = IS.create_label("Please select a valid file.")
			alert_win_cont.add_child(alert_mess)
	
	var move_optionbutton: OptionController = IS.create_float_edit.callv(["Select from"] + UsableRes.options_args(int(sys_is_global), SYSTEM_TYPE))[0]
	var files_tree: Tree = IS.create_tree()
	
	var cont: BoxContainer = WindowManager.popup_accept_window(
		main_window,
		Vector2(400, 500),
		"Open file",
		func() -> void:
			accept_func.call(
				bool(move_optionbutton.selected_id == 1),
				files_tree.get_selected().get_metadata(0)
			)
	)
	var window: WindowManager.AcceptWindow = cont.get_window()
	window.accept_button.text = "Open"
	
	cont.add_child(move_optionbutton.get_parent())
	cont.add_child(files_tree)
	
	update_func.call(files_tree, sys_is_global, sys_path)
	move_optionbutton.selected_option_changed.connect(
		func(id: int, option: MenuOption) -> void:
			update_func.call(
				files_tree,
				bool(move_optionbutton.selected_id == 1),
				[]
			)
	)

func format_path(paths_for_format: Dictionary[String, String]) -> void:
	if not sys_path:
		return
	var path: String = sys_path.back()
	if paths_for_format.has(path):
		sys_path[-1] = paths_for_format[path]
		#update_disk_path()
