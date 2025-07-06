class_name MediaExplorer extends EditorRect

@export var header_options: Array[MenuOption]
@export var media_card_scene: PackedScene
@export var folder_card_scene: PackedScene

@export_group("Theme")
@export_subgroup("Texture", "texture")
@export var texture__filter: Texture2D = preload("res://Asset/Icons/filter.png")
@export var texture_sort: Texture2D = preload("res://Asset/Icons/arrange.png")
@export var texture_search: Texture2D = preload("res://Asset/Icons/magnifying-glass.png")
@export var texture_file: Texture2D = preload("res://Asset/Icons/add-post.png")
@export var texture_folder: Texture2D = preload("res://Asset/Icons/open-file.png")
@export var texture_undo_path: Texture2D = preload("res://Asset/Icons/up-arrow.png")
@export var texture_reload: Texture = preload("res://Asset/Icons/reload.png")
@export_subgroup("Constant")
@export var media_display_size: Vector2 = Vector2(150, 120)


var curr_media_box_index: int:
	set(val):
		curr_media_box_index = val
		for index in body.get_child_count():
			var control = body.get_child(index)
			if index != curr_media_box_index:
				control.hide()
				continue
			control.show()



var media_info = {
	files = {filter = true, sort = true, save_path = "media/files.res", file_system_res = null, import_media = true},
	text = {filter = false, sort = false, save_path = "media/text.res", file_system_res = null, import_media = false},
	shapes = {filter = false, sort = false, save_path = "media/shapes.res", file_system_res = null, import_media = false}
}







func _start() -> void:
	super()
	
	# Start Header
	var header_menu = InterfaceServer.create_menu(header_options)
	header_menu.button_pressed.connect(on_header_menu_button_pressed)
	header.add_child(header_menu)
	
	# Start Body
	for media in media_info:
		var media_box = MediaBox.new(self)
		media_box.create(media)
		body.add_child(media_box)










class MediaBox extends Container:
	
	
	
	var media_box_info: Dictionary
	var curr_display_path: Array
	
	var media_explorer: MediaExplorer
	
	var filter_button: Button
	var sort_button: Button
	var search_line: LineEdit
	var import_button: Button
	var folder_button: Button
	
	var undo_path_button: TextureButton
	var reload_button: TextureButton
	var path_container: BoxContainer
	
	var media_container: FlexGridContainer
	
	
	
	func _init(_media_explorer: MediaExplorer) -> void:
		media_explorer = _media_explorer
	
	func _ready() -> void:
		InterfaceServer.set_base_container_settings(self)
	
	func create(media: String) -> void:
		
		media_box_info = media_explorer.media_info.get(media)
		
		media_box_info.file_system_res = ProjectServer.get_res_file(media_box_info.save_path, DisplayFileSystemRes.new())
		
		var body_container = InterfaceServer.create_box_container(10, true)
		
		var options_container = InterfaceServer.create_box_container()
		search_line = InterfaceServer.create_line_edit("Search for Media", "", media_explorer.texture_search)
		folder_button = InterfaceServer.create_button("Create Folder", media_explorer.texture_folder)
		search_line.text_changed.connect(func(new_text: String): filter())
		folder_button.pressed.connect(on_folder_button_pressed)
		if media_box_info.filter:
			filter_button = InterfaceServer.create_button("Filter", media_explorer.texture__filter)
			options_container.add_child(filter_button)
		if media_box_info.sort:
			sort_button = InterfaceServer.create_button("Sort", media_explorer.texture_sort)
			options_container.add_child(sort_button)
		options_container.add_child(search_line)
		if media_box_info.import_media:
			import_button = InterfaceServer.create_button("Import", media_explorer.texture_file)
			import_button.pressed.connect(on_import_button_pressed)
			options_container.add_child(import_button)
		options_container.add_child(folder_button)
		
		var head_path_container = InterfaceServer.create_box_container()
		undo_path_button = InterfaceServer.create_texture_button(media_explorer.texture_undo_path)
		reload_button = InterfaceServer.create_texture_button(media_explorer.texture_reload)
		path_container = InterfaceServer.create_box_container(10, false, {alignment = BoxContainer.ALIGNMENT_BEGIN})
		undo_path_button.pressed.connect(undo.bind(1))
		reload_button.pressed.connect(update)
		path_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head_path_container.add_child(undo_path_button)
		head_path_container.add_child(reload_button)
		head_path_container.add_child(path_container)
		
		var scroll_container = InterfaceServer.create_scroll_container(1,1, {size_flags_vertical = Control.PRESET_FULL_RECT})
		media_container = InterfaceServer.create_grid_container(media_explorer.media_display_size)
		media_container.control_size = media_explorer.media_display_size
		
		body_container.add_child(options_container)
		body_container.add_child(head_path_container)
		body_container.add_child(scroll_container)
		scroll_container.add_child(media_container)
		add_child(body_container)
		
		update()
	
	
	func create_folder(display_path: Array, folder_name: String) -> void:
		media_box_info.file_system_res.create_folder(display_path, folder_name)
		update()
	
	func create_file(display_path: Array, file_path: String) -> void:
		media_box_info.file_system_res.create_file(display_path, file_path)
	
	func undo(times: int) -> void:
		for time in times:
			curr_display_path.pop_back()
		update()
	
	func update() -> void:
		
		for i in path_container.get_children(): i.queue_free()
		for i in media_container.get_children(): i.queue_free()
		
		for time in curr_display_path.size() + 1:
			time -= 1
			
			var button = InterfaceServer.create_button("", null, {flat = true})
			var folder_name = "Project"
			
			if time > -1:
				folder_name = curr_display_path[time]
			
			var undo_times = curr_display_path.size() - time - 1
			button.pressed.connect(undo.bind(undo_times))
			
			button.text = folder_name
			path_container.add_child(button)
			path_container.add_child(InterfaceServer.create_label("/"))
		
		var files_and_folders = media_box_info.file_system_res.get_files_and_folders_at(curr_display_path)
		for index in files_and_folders.keys().size():
			
			var i = files_and_folders.keys()[index]
			var info = files_and_folders.get(i)
			
			var card = null
			if info.type == "file":
				card = media_explorer.media_card_scene.instantiate()
				card.clicked.connect(on_file_clicked.bind(i))
				card.resource_path = i
				card.display_name = i.get_file()
			else:
				card = media_explorer.folder_card_scene.instantiate()
				card.clicked.connect(on_folder_clicked.bind(i))
				card.display_name = i
			
			card.custom_minimum_size = media_explorer.media_display_size
			media_container.add_child(card)
			
			if info.type == "file":
				card.display_at(index * .02)
		
		filter()
	
	func filter() -> void:
		var search_text = search_line.text.strip_edges().to_lower()
		for media in media_container.get_children():
			var contains_search_text = media.display_name.to_lower().contains(search_text)
			media.visible = search_text.is_empty() or contains_search_text
	
	
	
	func on_folder_button_pressed() -> void:
		var name_line = InterfaceServer.create_line_edit("Type Folder Name", "New Folder")
		var box = WindowManager.popup_accept_window(
			get_tree().current_scene,
			Vector2(400, 150),
			"Create Folder",
			func(): create_folder(curr_display_path, name_line.text)
		)
		box.add_child(name_line)
		box.move_child(name_line, 0)
		name_line.select()
		name_line.grab_focus()
	
	func on_import_button_pressed() -> void:
		var file_dialog = WindowManager.create_file_dialog_window(
			get_tree().current_scene, FileDialog.FILE_MODE_OPEN_FILES, MediaServer.MEDIA_EXTENSIONS
		)
		file_dialog.files_selected.connect(func(paths: PackedStringArray):
			for path: String in paths:
				create_file(curr_display_path, path)
			update()
		)
		file_dialog.popup_centered()
	
	func on_folder_clicked(folder_name: String) -> void:
		curr_display_path.append(folder_name)
		update()
	
	func on_file_clicked(file_path: String) -> void:
		ProjectServer.add_media_clip(file_path, -1, EditorServer.time_line.curr_frame)








func on_header_menu_button_pressed(index: int) -> void:
	curr_media_box_index = index





