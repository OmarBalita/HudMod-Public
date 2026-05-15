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
class_name CreatedBox extends MediaBox

var project_file_system: DisplayFileSystemRes
var global_file_system: DisplayFileSystemRes

var display_file_system: DisplayFileSystemRes:
	set(val):
		display_file_system = val
		if path_controller:
			var root_name: String
			match val:
				project_file_system: root_name = &"Project"
				global_file_system: root_name = &"Global"
			path_controller.set_root_name(root_name)

# Backround FileSystem
var curr_display_path: Array

# Filter and Sort
var filter_button: OptionController
var sort_button: OptionController
var folder_button: Button

# Path Handling Nodes
var path_container: BoxContainer
var undo_path_button: TextureButton
var reload_button: TextureButton
var path_controller: PathController

func _ready() -> void:
	super()
	ProjectServer2.project_opened.connect(_on_project_server_project_opened)

func _init_media_select_cont() -> MediaBox.MediaSelectContainer:
	return CreatedSelectContainer.new(self)

func get_display_file_system() -> DisplayFileSystemRes:
	return display_file_system

func set_display_file_system(new_val: DisplayFileSystemRes, _update: bool = true) -> void:
	display_file_system = new_val
	if _update: update()

func get_true_file_system(global: bool) -> DisplayFileSystemRes:
	return global_file_system if global else project_file_system

func _ready_options() -> void:
	
	var filter_options: Array[Dictionary] = _get_filter_options()
	var sort_options: Array[Dictionary] = _get_sort_options()
	
	if filter_options:
		filter_button = IS.create_option_controller(filter_options)
		filter_button.selected_option_changed.connect(on_filter_button_selected_option_changed)
		options_container.add_child(filter_button)
	
	if sort_options:
		sort_button = IS.create_option_controller(sort_options)
		sort_button.selected_option_changed.connect(on_sort_button_selected_option_changed)
		options_container.add_child(sort_button)
	
	path_container = IS.create_box_container(8)
	undo_path_button = IS.create_texture_button(media_explorer.texture_undo_path, null, null, "Undo")
	reload_button = IS.create_texture_button(media_explorer.texture_reload, null, null, "Reload")
	path_controller = PathController.new()
	
	path_controller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	IS.add_children(path_container, [undo_path_button, reload_button, path_controller])
	body_container.add_child(path_container)
	body_container.move_child(path_container, 1)
	
	undo_path_button.pressed.connect(undo.bind(1))
	reload_button.pressed.connect(update)
	path_controller.root_requested.connect(popup_root_menu)
	path_controller.undo_requested.connect(undo)
	
	super()
	
	folder_button = IS.create_button("", media_explorer.texture_folder, "New folder")
	folder_button.pressed.connect(_on_folder_button_pressed)
	options_container.add_child(folder_button)

func on_filter_button_selected_option_changed(index: int, option: MenuOption) -> void:
	curr_filter = index
	filter_and_sort()

func on_sort_button_selected_option_changed(index: int, option: MenuOption) -> void:
	curr_sort = index
	filter_and_sort()

func open(folder_name: String) -> void:
	curr_display_path.append(folder_name)
	update()

func undo(times: int) -> void:
	for time: int in times:
		curr_display_path.resize(curr_display_path.size() - 1)
	update()

func update() -> void:
	
	path_controller.update(curr_display_path)
	if display_file_system == null: return
	var files_and_folders: Dictionary = display_file_system.get_files_and_folders_at(curr_display_path)
	
	var created_box_cat: Category = _get_created_box_category()
	if created_box_cat == null: return
	created_box_cat.remove_all_contents()
	
	var idx: int
	
	for key: String in files_and_folders:
		
		var info: Dictionary = files_and_folders[key]
		var type: String = info.type
		
		var card: CreatedCard
		
		if type == "folder":
			var folder_card:= FolderCard.new(self, 0)
			folder_card.created_card_type = -1
			folder_card.path_or_name = key
			folder_card.display_name = key
			folder_card.contents = info.forward
			card = folder_card
		else:
			card = _init_card(key, info, type)
		
		card.create_date = info.date
		card.custom_minimum_size = media_explorer.card_display_size
		created_box_cat.add_content(card)
		
		idx += 1
	
	filter_and_sort()
	await get_tree().process_frame
	update_select_container()
	update_cards_selection()

func _init_card(key: String, info: Dictionary, type: String) -> CreatedCard:
	return null

func popup_root_menu() -> void:
	var root_button: Button = path_controller.get_child(0)
	IS.popup_menu([
		MenuOption.new("Project", null, set_display_file_system.bind(project_file_system)),
		MenuOption.new("Global", null, set_display_file_system.bind(global_file_system)),
	], root_button)

func _get_created_box_category() -> Category:
	return null

func get_selected_paths_or_names(accept_files: bool = true, accept_folders: bool = true) -> PackedStringArray:
	var paths_or_names: PackedStringArray
	
	var cats: Array[Category] = categories.values()
	
	var selected: Dictionary[int, Dictionary] = media_select_cont.selected
	
	for port_idx: int in selected:
		
		var cat: Category = cats[port_idx]
		var cards: Array[Node] = cat.get_contents()
		
		var port: Dictionary = selected[port_idx]
		
		for idx: int in port:
			var card: CreatedCard = cards[idx]
			
			if (card is ImportBox.ImportCard or card is PresetBox.PresetCard) and accept_files:
				paths_or_names.append(card.path_or_name)
			
			elif card is FolderCard and accept_folders:
				paths_or_names.append(card.path_or_name)
	
	return paths_or_names

func create_folder(display_path: Array, folder_name: String) -> void:
	display_file_system.create_folder(display_path, folder_name)

func create_folders(display_path: Array, folders_names: PackedStringArray) -> void:
	display_file_system.create_folders(display_path, folders_names)

func create_file(display_path: Array, file_path: String) -> MediaCache.LOAD_ERR:
	return display_file_system.create_file(display_path, file_path)

func create_files(display_path: Array, files_pathes: PackedStringArray) -> Array[MediaCache.LOAD_ERR]:
	return display_file_system.create_files(display_path, files_pathes)

func delete_file_or_folder(display_path: Array, path_or_name: String, delete_real_file: bool = false) -> void:
	display_file_system.delete(display_path, path_or_name, delete_real_file)
	EditorServer.scan_media_existent()

func delete_files_or_folders(display_path: Array, pathes_or_names: PackedStringArray, delete_real_file: bool = false) -> void:
	display_file_system.delete_packed(display_path, pathes_or_names, delete_real_file)
	MediaCache.video_contexts_update_max_cache_size()
	EditorServer.scan_media_existent()

func delete_selected(delete_real_files: bool = false) -> void:
	var paths_or_names: PackedStringArray = get_selected_paths_or_names()
	delete_files_or_folders(curr_display_path, paths_or_names, delete_real_files)
	update()

# move_option: 0 = MOVE_TO_PROJECT, 1 = MOVE_TO_GLOBAL
func move_selected(move_option: int, move_to_display_path: Array, move_fake_files: bool, move_real_files: bool) -> void:
	
	var move_from: Dictionary = display_file_system.get_dir(curr_display_path)
	
	var is_global: bool = move_option == 1
	var target_file_system: DisplayFileSystemRes = get_true_file_system(is_global)
	
	var paths_or_names: PackedStringArray = get_selected_paths_or_names()
	
	var files_paths: PackedStringArray
	var folders: Dictionary[String, Dictionary]
	
	for path_or_name: String in paths_or_names:
		if path_or_name.is_absolute_path():
			files_paths.append(path_or_name)
		elif path_or_name.is_valid_filename():
			var folder_display_path: Array = curr_display_path + [path_or_name]
			if display_file_system == target_file_system and folder_display_path == move_to_display_path:
				continue
			folders[path_or_name] = move_from[path_or_name]
	
	if move_real_files:
		
		var paths_for_format: Dictionary[String, String] = {}
		var media_dir_path: String = EditorServer.get_media_path(is_global)
		
		for index: int in files_paths.size():
			
			var from: String = files_paths[index]
			var to: String = DirAccessHelper.create_unique_path(str(media_dir_path, from.get_file()))
			
			files_paths.set(index, to)
			move_from[to] = move_from[from]
			move_from.erase(from)
			
			paths_for_format[from] = to
			
			DirAccess.rename_absolute(from, to)
			
			MediaCache.replace_path(from, to)
		
		EditorServer.format_paths(paths_for_format)
	
	if move_fake_files:
		
		display_file_system.delete_packed(curr_display_path, files_paths, false)
		target_file_system.create_files(move_to_display_path, files_paths)
		display_file_system.delete_packed(curr_display_path, folders.keys(), false)
		target_file_system.add_folders(move_to_display_path, folders)
		
		display_file_system = target_file_system
		curr_display_path = move_to_display_path
	
	update()
	EditorServer.scan_media_existent()
	ProjectServer2.save()

func _on_folder_button_pressed() -> void:
	var name_line: LineEdit = IS.create_line_edit("Type Folder Name", "New Folder")
	var box: BoxContainer = WindowManager.popup_accept_window(
		get_tree().current_scene,
		Vector2(400, 150),
		"Create Folder",
		func():
			create_folder(curr_display_path, name_line.text)
			update()
	)
	box.add_child(name_line)
	box.move_child(name_line, 0)
	name_line.select()
	name_line.grab_focus()

func _on_project_server_project_opened(project_res: ProjectRes) -> void:
	curr_display_path = []


class CreatedSelectContainer extends MediaBox.MediaSelectContainer:
	
	func _init(_media_box: MediaBox) -> void:
		super(_media_box)
		control_enable_delete = true
	
	func delete_selected_vals() -> void:
		(media_box as CreatedBox).delete_selected()


class CreatedCard extends MediaBox.MediaCard:
	
	enum CreatedCardType {
		CARD_TYPE_FOLDER = -1,
		CARD_TYPE_IMAGE,
		CARD_TYPE_VIDEO,
		CARD_TYPE_AUDIO,
		CARD_TYPE_PRESET
	}
	
	@export var created_card_type: CreatedCardType
	@export var create_date: float
	@export var path_or_name: String
	
	func popup_context_menu() -> void:
		var options: Array[Dictionary] = _get_context_menu_options()
		
		var context_menu: PopupMenu = IS.create_popup_menu(options)
		
		var popup_pos:= Vector2i(get_global_mouse_position() * get_window().content_scale_factor) + get_window().position
		
		get_tree().get_current_scene().add_child(context_menu)
		context_menu.popup(Rect2i(popup_pos, Vector2i.ZERO))
		context_menu.id_pressed.connect(_on_context_menu_id_pressed)
		context_menu.popup_hide.connect(context_menu.queue_free)
	
	func popup_move_to_window() -> void:
		var move_edit: EditContainer = IS.create_float_edit.callv(["Move to"] + UsableRes.options_args(0, {"PROJECT": 0, "GLOBAL": 1}))
		var move_optionbutton: OptionController = move_edit.controller
		
		#var move_fake_files_checkbutton: CheckButton = IS.create_bool_edit("Move in Embeded file system ", true)[0]
		var tree: Tree = IS.create_tree()
		
		#var move_real_file_checkbutton: CheckButton = IS.create_bool_edit("Move in Disk", false)[0]
		#var warning_text_edit: CustomTextEdit = IS.create_text_edit()
		#warning_text_edit.add_theme_color_override("font_readonly_color", Color(Color.YELLOW, .7))
		#IS.expand(warning_text_edit, true, true)
		#warning_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		#warning_text_edit.editable = false
		
		var update_ui_func: Callable = func() -> void:
			var move_to_global: bool = move_optionbutton.selected_id == 1
			
			var text: String = "Warning"
			var target_name: String = "Global" if move_to_global else "Project"
			
			#tree.visible = move_fake_files_checkbutton.button_pressed
			var move_to_file_system: DisplayFileSystemRes = media_box.get_true_file_system(move_to_global)
			move_to_file_system.build_tree(tree, "%s (Fake Files)" % target_name)
			tree.set_selected(tree.get_root(), 0)
			
			#if move_fake_files_checkbutton.button_pressed:
				#text += "\n\n- media will be moved to the specified folder in '%s' within the HudMod custom file system." % target_name
			#if move_real_file_checkbutton.button_pressed:
				#text += "\n\n- media files will be moved to the '%s' media dir in disk." % target_name
			#text += "\n\n- No undo."
			#warning_text_edit.text = text
		
		update_ui_func.call()
		move_optionbutton.selected_option_changed.connect(func(id: int, option: MenuOption) -> void: update_ui_func.call())
		#move_fake_files_checkbutton.pressed.connect(update_ui_func)
		#move_real_file_checkbutton.pressed.connect(update_ui_func)
		
		var box: BoxContainer = WindowManager.popup_accept_window(get_window(), Vector2i(400, 600), "Move to", func() -> void:
			media_box.move_selected(
				move_optionbutton.selected_id,
				tree.get_selected().get_metadata(0),
				true,
				false
				#move_fake_files_checkbutton.button_pressed,
				#move_real_file_checkbutton.button_pressed
			)
		)
		IS.add_children(box, [
			move_edit,
			#move_fake_files_checkbutton.get_parent(),
			tree,
			#move_real_file_checkbutton.get_parent(),
			#warning_text_edit
		])
	
	func copy_path() -> void:
		DisplayServer.clipboard_set(path_or_name)
	
	func delete() -> void:
		media_box.delete_selected()
	
	func open_in_external_program() -> void:
		OS.shell_open(path_or_name)
	
	func show_in_file_manager() -> void:
		OS.shell_show_in_file_manager(path_or_name)


class FolderCard extends CreatedCard:
	
	static var texture_folder: CompressedTexture2D = preload("res://Asset/Icons/folder.png")
	
	@export var contents: Dictionary
	
	func _init(_media_box: MediaBox, port: int) -> void:
		super(_media_box, port)
		display_texture = texture_folder
	
	func _activate() -> void:
		media_box.open(path_or_name)
	
	func get_media_ress() -> Array[MediaClipRes]:
		var result: Array[MediaClipRes] = []
		for key: String in contents:
			var key_info: Dictionary = contents.get(key)
			if key_info.type == "file" and not key_info.has(&"discard"):
				var media_type: int = key_info.media_type
				result.append(ImportBox.ImportCard.get_imported_res_from_type(media_type, key))
		return result
	
	func _get_context_menu_options() -> Array[Dictionary]:
		return [
			{text = "Delete"},
			{text = "Move to"}
		]
	
	func _on_context_menu_id_pressed(id: int) -> void:
		match id:
			0: delete()
			1: popup_move_to_window()

