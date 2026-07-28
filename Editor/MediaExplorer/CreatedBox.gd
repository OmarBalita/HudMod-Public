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

var project_file_system: FileSystem
var global_file_system: FileSystem

var file_system: FileSystem:
	set(val):
		file_system = val
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

func get_file_system() -> FileSystem:
	return file_system

func set_file_system(new_val: FileSystem, _update: bool = true) -> void:
	file_system = new_val
	if _update: update()

func get_true_file_system(global: bool) -> FileSystem:
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
	
	if file_system == null: return
	
	var files_and_folders: Variant = file_system.navigate_to_dir(curr_display_path)
	
	if files_and_folders is not Dictionary:
		curr_display_path.clear()
		files_and_folders = file_system.navigate_to_dir(curr_display_path)
	
	path_controller.update(curr_display_path)
	
	var created_box_cat: Category = _get_created_box_category()
	if created_box_cat == null: return
	created_box_cat.remove_all_contents()
	
	var idx: int
	
	for key: String in files_and_folders:
		
		var info: Dictionary = files_and_folders[key]
		var type: FileSystem.EntityType = info.t
		
		var card: CreatedCard
		
		if type == FileSystem.EntityType.FOLDER:
			var folder_card:= FolderCard.new(self, 0)
			folder_card.created_card_type = -1
			folder_card.path_or_name = key
			folder_card.display_name = key
			folder_card.contents = info.forward
			card = folder_card
		else:
			card = _init_card(key, info)
		
		card.create_date = info.date
		card.custom_minimum_size = media_explorer.card_display_size
		created_box_cat.add_content(card)
		
		idx += 1
	
	filter_and_sort()
	await get_tree().process_frame
	update_select_container()
	update_cards_selection()

func _init_card(key: String, info: Dictionary) -> CreatedCard:
	return null

func popup_root_menu() -> void:
	var root_button: Button = path_controller.get_child(0)
	IS.popup_menu([
		MenuOption.new("Project", null, set_file_system.bind(project_file_system)),
		MenuOption.new("Global", null, set_file_system.bind(global_file_system)),
	], root_button)

func _get_created_box_category() -> Category:
	return null

func get_selected_pathes_or_names(accept_files: bool = true, accept_folders: bool = true) -> PackedStringArray:
	var pathes_or_names: PackedStringArray
	
	var cats: Array[Category] = categories.values()
	
	var selected: Dictionary[int, Dictionary] = media_select_cont.selected
	
	for port_idx: int in selected:
		
		var cat: Category = cats[port_idx]
		var cards: Array[Node] = cat.get_contents()
		
		var port: Dictionary = selected[port_idx]
		
		for idx: int in port:
			var card: CreatedCard = cards[idx]
			
			if card is FolderCard:
				if accept_folders:
					pathes_or_names.append(card.path_or_name)
			
			elif accept_files:
				pathes_or_names.append(card.path_or_name)
	
	return pathes_or_names

func create_folders(display_path: Array, folders_names: PackedStringArray) -> void:
	var target_file_sys: FileSystem = file_system
	display_path = display_path.duplicate()
	var success: PackedStringArray = target_file_sys.create_folders(display_path, folders_names)
	update()
	ProjectServer2.commit_action(
		"create_folders",
		func() -> void:
			target_file_sys.create_folders(display_path, success)
			update(),
		func() -> void:
			target_file_sys.delete_packet(display_path, success)
			update(),
		false
	)

func create_files(file_system: FileSystem, display_path: Array, files_pathes: PackedStringArray) -> Array[MediaCache.LOAD_ERR]:
	return file_system.create_files(display_path, files_pathes)

func delete_files_or_folders(file_sys: FileSystem, display_path: Array, pathes_or_names: PackedStringArray, undo_redo: bool = true) -> void:
	
	display_path = display_path.duplicate()
	
	var do_method: Callable = func() -> void:
		file_system.delete_packet(display_path, pathes_or_names)
		MediaCache.video_contexts_update_max_cache_size()
		EditorServer.scan_media_existent()
		update()
	
	if undo_redo:
		
		var internal_dir: Dictionary = file_sys.navigate_to_dir(display_path)
		var files_and_folders: Dictionary[StringName, PackedStringArray] = _separate_files_and_folders(pathes_or_names)
		var folders_names: PackedStringArray = files_and_folders.folders
		
		var folders: Dictionary[String, Dictionary]
		for folder_name: String in folders_names:
			folders[folder_name] = internal_dir[folder_name].duplicate(true)
		
		var undo_method: Callable = func() -> void:
			file_sys.create_files(display_path, files_and_folders.files)
			file_sys.add_precreated_folders(display_path, folders)
			MediaCache.video_contexts_update_max_cache_size()
			EditorServer.scan_media_existent()
			update()
		
		ProjectServer2.commit_action("delete_files", do_method, undo_method)
	
	else:
		do_method.call()


func delete_selected() -> void:
	var pathes_or_names: PackedStringArray = get_selected_pathes_or_names()
	delete_files_or_folders(file_system, curr_display_path, pathes_or_names)

# move_option: 0 = MOVE_TO_PROJECT, 1 = MOVE_TO_GLOBAL
func move_selected(move_option: int, move_to_display_path: Array) -> void:
	
	var before_path: Array = curr_display_path.duplicate()
	
	var before_file_sys: FileSystem = file_system
	var after_file_sys: FileSystem = get_true_file_system(move_option == 1)
	
	var move_from: Dictionary = before_file_sys.navigate_to_dir(before_path)
	var move_to: Dictionary = after_file_sys.navigate_to_dir(move_to_display_path)
	
	var pathes_or_names: PackedStringArray = get_selected_pathes_or_names()
	var files_and_folders: Dictionary[StringName, PackedStringArray] = _separate_files_and_folders(pathes_or_names)
	var files_pathes: PackedStringArray = files_and_folders.files
	var folders_names: PackedStringArray = files_and_folders.folders
	var folders: Dictionary[String, Dictionary]
	
	if before_file_sys == after_file_sys:
		for folder_name: String in folders_names:
			var folder_path: Array = before_path + [folder_name]
			if folder_path == move_to_display_path:
				continue
			folders[folder_name] = move_from[folder_name]
	else:
		for folder_name: String in folders_names:
			folders[folder_name] = move_from[folder_name]
	
	var move_method: Callable = func(from_file_sys: FileSystem, to_file_sys: FileSystem, from_path: Array, to_path: Array) -> void:
		
		var _files_pathes:= files_pathes.duplicate()
		var _folders:= folders.duplicate()
		
		from_file_sys.delete_packet(from_path, _files_pathes)
		to_file_sys.create_files(to_path, _files_pathes)
		var success_folders: PackedStringArray = to_file_sys.add_precreated_folders(to_path, _folders)
		from_file_sys.delete_packet(from_path, success_folders)
		
		file_system = to_file_sys
		curr_display_path = to_path
		
		EditorServer.scan_media_existent()
		update()
	
	ProjectServer2.commit_action(
		"move_files",
		move_method.bind(before_file_sys, after_file_sys, before_path, move_to_display_path),
		move_method.bind(after_file_sys, before_file_sys, move_to_display_path, before_path)
	)


func _separate_files_and_folders(pathes_or_names: PackedStringArray) -> Dictionary[StringName, PackedStringArray]:
	var files_pathes: PackedStringArray
	var folders: PackedStringArray
	
	for path_or_name: String in pathes_or_names:
		if path_or_name.is_absolute_path(): files_pathes.append(path_or_name)
		elif path_or_name.is_valid_filename(): folders.append(path_or_name)
	
	return {
		&"files": files_pathes,
		&"folders": folders
	}

func _on_folder_button_pressed() -> void:
	var name_line: LineEdit = IS.create_line_edit("Type Folder Name", "New Folder")
	var box: BoxContainer = WindowManager.popup_accept_window(
		get_tree().current_scene,
		Vector2(400, 150),
		"Create Folder",
		create_folders.bind(curr_display_path, [name_line.text])
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
			var move_to_file_system: FileSystem = media_box.get_true_file_system(move_to_global)
			move_to_file_system.build_tree(tree, target_name)
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
			(media_box as CreatedBox).move_selected(
				move_optionbutton.selected_id,
				tree.get_selected().get_metadata(0).duplicate(),
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

