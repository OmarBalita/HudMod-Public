class_name MediaExplorer extends EditorRect

@export var folder_card_scene: PackedScene
@export var imported_card_scene: PackedScene
@export var object_card_scene: PackedScene
@export var transition_card_scene: PackedScene
@export var preset_card_scene: PackedScene

@export_group("Theme")
@export_subgroup("Texture", "texture")
@export var texture_import: Texture2D = preload("res://Asset/Icons/gallery.png")
@export var texture_object: Texture2D = preload("res://Asset/Icons/object.png")
@export var texture_transition: Texture2D = preload("res://Asset/Icons/transition.png")
@export var texture_preset: Texture2D = preload("res://Asset/Icons/flash.png")
@export var texture__filter: Texture2D = preload("res://Asset/Icons/filter.png")
@export var texture_sort: Texture2D = preload("res://Asset/Icons/arrange.png")
@export var texture_search: Texture2D = preload("res://Asset/Icons/magnifying-glass.png")
@export var texture_file: Texture2D = preload("res://Asset/Icons/add-post.png")
@export var texture_folder: Texture2D = preload("res://Asset/Icons/open-file.png")
@export var texture_undo_path: Texture2D = preload("res://Asset/Icons/up-arrow.png")
@export var texture_reload: Texture = preload("res://Asset/Icons/reload.png")
@export_subgroup("Constant")
@export var card_display_size: Vector2 = Vector2(128, 128)

var curr_media_box: int:
	set(val):
		curr_media_box = val
		for index: int in body.get_child_count():
			var control = body.get_child(index)
			if index != curr_media_box:
				control.hide()
				continue
			control.show()

# RealTime Nodes
var header_menu: Menu
var import_box:= ImportBox.new(self)
var object_box:= ObjectBox.new(self)
var transition_box:= TransitionBox.new(self)
var preset_box:= PresetBox.new(self)



func _ready() -> void:
	super()
	
	header_menu = IS.create_menu([
		MenuOption.new("Import", texture_import),
		MenuOption.new("Object", texture_object),
		MenuOption.new("Transition", texture_transition),
		MenuOption.new("Preset", texture_preset)
	])
	header_menu.focus_index_changed.connect(set_curr_media_box)
	header.add_child(header_menu)
	
	IS.add_childs(body, [
		import_box,
		object_box,
		transition_box,
		preset_box
	])

func set_curr_media_box(new_media_box: int) -> void:
	curr_media_box = new_media_box






func import_media(file_path: String, update: bool = true) -> void:
	import_box.create_file(import_box.curr_display_path, file_path)
	if update: update()

func delete_file_or_folder(path_or_name: String, update: bool = true) -> void:
	import_box.delete_file_or_folder(import_box.curr_display_path, path_or_name)
	if update: update()

func update() -> void:
	import_box.update()


class MediaBox extends Container:
	
	var selection_group: SelectionGroupRes = EditorServer.import_media_cards_selection_group
	
	var categories: Dictionary[String, Category]
	
	var media_explorer: MediaExplorer
	
	var body_container: BoxContainer
	
	var options_container: BoxContainer
	var media_categories_box: BoxContainer
	
	var search_line: LineEdit
	
	func _init(_media_explorer: MediaExplorer) -> void:
		media_explorer = _media_explorer
	
	func _ready() -> void:
		
		body_container = IS.create_box_container(10, true)
		options_container = IS.create_box_container()
		var scroll_container = IS.create_scroll_container(1,1, {size_flags_vertical = Control.PRESET_FULL_RECT})
		media_categories_box = IS.create_box_container(12, true, {})
		IS.expand(media_categories_box, true, true)
		
		scroll_container.add_child(media_categories_box)
		body_container.add_child(options_container)
		body_container.add_child(scroll_container)
		add_child(body_container)
		
		_ready_options()
	
	func _ready_options() -> void:
		search_line = IS.create_line_edit("Search for Media", "", media_explorer.texture_search)
		search_line.text_changed.connect(on_search_line_text_changed)
		options_container.add_child(search_line)
	
	func add_category(category_name: StringName, has_header: bool = true) -> Category:
		var category = IS.create_category(has_header, category_name, Color.BLACK, media_explorer.card_display_size)
		category.has_custom_color = false
		media_categories_box.add_child(category)
		categories[category_name] = category
		return category
	
	func get_category(category_name: StringName) -> Category:
		return categories.get(category_name)
	
	func remove_category(category_name: StringName) -> void:
		categories.get(category_name).queue_free()
		categories.erase(category_name)
	
	func filter_and_sort() -> void:
		var search_text = search_line.text.strip_edges().to_lower()
		#var filter_func: Callable = func(path: String) -> bool:
			#return not curr_filter or MediaServer.get_media_type_from_path(path) == curr_filter - 1
		
		#for index in sorted_media_clips.size():
			#var media_card = sorted_media_clips[index]
			#var contains_search_text = media_card.display_name.to_lower().contains(search_text)
			#var resource_path = media_card.resource_path
			#media_card.visible = (search_text.is_empty() or contains_search_text) and filter_func.call(resource_path)
			#media_container.move_child(media_card, index)
	
	func on_search_line_text_changed() -> void:
		filter_and_sort()


class ImportBox extends MediaBox:
	
	var display_file_system: DisplayFileSystemRes = DisplayFileSystemRes.new()
	var curr_display_path: Array
	
	var curr_filter: int
	var curr_sort: int
	
	var filter_button: OptionController
	var sort_button: OptionController
	var import_button: Button
	var folder_button: Button
	
	var undo_path_button: TextureButton
	var reload_button: TextureButton
	var path_controller: PathController
	
	var import_category: Category
	
	
	func _ready() -> void:
		super()
		
		var path_container = IS.create_box_container()
		
		undo_path_button = IS.create_texture_button(media_explorer.texture_undo_path)
		reload_button = IS.create_texture_button(media_explorer.texture_reload)
		path_controller = PathController.new()
		
		path_controller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		IS.add_childs(path_container, [undo_path_button, reload_button, path_controller])
		body_container.add_child(path_container)
		body_container.move_child(path_container, 1)
		
		undo_path_button.pressed.connect(undo.bind(1))
		reload_button.pressed.connect(update)
		path_controller.undo_requested.connect(undo)
		
		import_category = add_category("Import", false)
		
		update()
	
	func _ready_options() -> void:
		
		filter_button = IS.create_option_controller([
			{text = "All"},
			{text = "Image"},
			{text = "Video"},
			{text = "Audio"},
		], "")
		filter_button.selected_option_changed.connect(on_filter_button_selected_option_changed)
		options_container.add_child(filter_button)
		
		sort_button = IS.create_option_controller([
			{text = "Name"},
			{text = "Type"},
			{text = "Latest to Earliest"},
			{text = "Earliest to Latest"},
		], "")
		sort_button.selected_option_changed.connect(on_sort_button_selected_option_changed)
		options_container.add_child(sort_button)
		
		super()
		
		import_button = IS.create_button("", media_explorer.texture_file, true)
		import_button.pressed.connect(on_import_button_pressed)
		options_container.add_child(import_button)
		
		folder_button = IS.create_button("", media_explorer.texture_folder)
		folder_button.pressed.connect(on_folder_button_pressed)
		options_container.add_child(folder_button)
	
	func create_folder(display_path: Array, folder_name: String) -> void:
		display_file_system.create_folder(display_path, folder_name)
		update()
	
	func create_file(display_path: Array, file_path: String) -> void:
		display_file_system.create_file(display_path, file_path)
	
	func delete_file_or_folder(display_path: Array, path_or_name: String) -> void:
		display_file_system.delete(display_path, path_or_name)
	
	func undo(times: int) -> void:
		for time: int in times:
			curr_display_path.resize(curr_display_path.size() - 1)
		update()
	
	func update() -> void:
		
		selection_group.clear_objects()
		
		path_controller.update(curr_display_path)
		import_category.remove_all_contents()
		
		if display_file_system == null:
			return
		var files_and_folders: Dictionary = display_file_system.get_files_and_folders_at(curr_display_path)
		
		for index: int in files_and_folders.keys().size():
			
			var i: String = files_and_folders.keys()[index]
			var info: Dictionary = files_and_folders.get(i)
			
			var card: DoubleClickControl = null
			if info.type == "file":
				card = media_explorer.imported_card_scene.instantiate()
				card.resource_path = i
				card.display_name = i.get_file()
			else:
				card = media_explorer.folder_card_scene.instantiate()
				card.clicked.connect(on_folder_clicked.bind(i))
				card.display_name = i
			card.date = info.date
			
			card.selection_group = selection_group
			card.custom_minimum_size = media_explorer.card_display_size
			import_category.add_content(card)
			
			if info.type == "file":
				card.display_imported_media_at(index * .02)
		
		filter_and_sort()
	
	func filter_and_sort() -> void:
		
		if not search_line:
			return
		
		var search_text: String = search_line.text.strip_edges().to_lower()
		var filter_func: Callable = func(path: String) -> bool:
			return not curr_filter or MediaServer.get_media_type_from_path(path) == curr_filter - 1
		
		var sorted_media_clips: Array[Node] = import_category.get_contents()
		var sort_func: Callable
		match curr_sort:
			0:
				sort_func = func(a, b) -> bool: return a.display_name.to_lower() < b.display_name.to_lower()
			1:
				sort_func = func(a, b) -> bool:
					if a.card_type and not b.card_type:
						return true
					elif not a.card_type and b.card_type:
						return false
					else:
						var type_a: int = MediaServer.get_media_type_from_path(a.resource_path)
						var type_b: int = MediaServer.get_media_type_from_path(b.resource_path)
						return type_a < type_b
			2: sort_func = func(a, b) -> bool: return a.date > b.date
			3: sort_func = func(a, b) -> bool: return a.date < b.date
		
		sorted_media_clips.sort_custom(sort_func)
		
		for index: int in sorted_media_clips.size():
			var media_card: DoubleClickControl = sorted_media_clips[index]
			var contains_search_text: bool = media_card.display_name.to_lower().contains(search_text)
			var resource_path: String = media_card.resource_path
			media_card.visible = (search_text.is_empty() or contains_search_text) and filter_func.call(resource_path)
			import_category.move_content(media_card, index)
	
	
	func on_filter_button_selected_option_changed(index: int, option: MenuOption) -> void:
		curr_filter = index
		filter_and_sort()
	
	func on_sort_button_selected_option_changed(index: int, option: MenuOption) -> void:
		curr_sort = index
		filter_and_sort()
	
	func on_folder_button_pressed() -> void:
		var name_line: LineEdit = IS.create_line_edit("Type Folder Name", "New Folder")
		var box: BoxContainer = WindowManager.popup_accept_window(
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
		var file_dialog: FileDialog = WindowManager.create_file_dialog_window(
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



class ObjectBox extends MediaBox:
	
	func _ready() -> void:
		super()
		
		var cat_object_2d: Category = add_category("Object2D")
		var cat_object_3d: Category = add_category("Object3D")
		
		for object: Dictionary in TypeServer.objects:
			var card: DoubleClickControl = media_explorer.object_card_scene.instantiate()
			ObjectServer.describe(card, {
				object_res_id = object.type_id,
				display_name = object.text,
				display_image = object.thumbnail,
				custom_minimum_size = media_explorer.card_display_size,
				selection_group = selection_group
			})
			get_category(object.category).add_content(card)



class TransitionBox extends MediaBox:
	pass


class PresetBox extends MediaBox:
	pass





























#class MediaBox extends Container:
	#
	#var filter_save_path = EditorServer.editor_path + "explorer_filter.tres"
	#var sort_save_path = EditorServer.editor_path + "explorer_sort.tres"
	#
	#var media_box_info: Dictionary
	#var curr_display_path: Array
	#var curr_filter: int
	#var curr_sort: int
	#
	#var media_explorer: MediaExplorer
	#
	#var filter_button: Button
	#var sort_button: Button
	#var search_line: LineEdit
	#var import_button: Button
	#var folder_button: Button
	#
	#var undo_path_button: TextureButton
	#var reload_button: TextureButton
	#var path_container: BoxContainer
	#
	#var media_container: FlexGridContainer
	#
	#
	#
	#func _init(_media_explorer: MediaExplorer) -> void:
		#media_explorer = _media_explorer
	#
	#func _ready() -> void:
		## Base Settings
		#IS.set_base_container_settings(self)
		## Update Filter and Sort
		#var filter_group = ResourceLoader.load(media_explorer.filter_group_path)
		#var sort_group = ResourceLoader.load(media_explorer.sort_group_path)
		#if filter_group: curr_filter = filter_group.checked_index
		#if sort_group: curr_sort = sort_group.checked_index
	#
	#
	#func create(media: String) -> void:
		#
		#media_box_info = media_explorer.media_info.get(media)
		#
		#media_box_info.file_system_res = ProjectServer.get_res_file(media_box_info.save_path, DisplayFileSystemRes.new())
		#
		#var body_container = IS.create_box_container(10, true)
		#
		#var options_container = IS.create_box_container()
		#search_line = IS.create_line_edit("Search for Media", "", media_explorer.texture_search)
		#folder_button = IS.create_button("", media_explorer.texture_folder)
		#search_line.text_changed.connect(func(new_text: String): filter_and_sort())
		#folder_button.pressed.connect(on_folder_button_pressed)
		#
		#if media_box_info.filter:
			#filter_button = IS.create_button("Filter", media_explorer.texture__filter)
			#filter_button.pressed.connect(on_filter_button_pressed)
			#options_container.add_child(filter_button)
		#
		#if media_box_info.sort:
			#sort_button = IS.create_button("Sort", media_explorer.texture_sort)
			#sort_button.pressed.connect(on_sort_button_pressed)
			#options_container.add_child(sort_button)
		#
		#options_container.add_child(search_line)
		#
		#if media_box_info.import_media:
			#import_button = IS.create_button("", media_explorer.texture_file, true)
			#import_button.pressed.connect(on_import_button_pressed)
			#options_container.add_child(import_button)
		#options_container.add_child(folder_button)
		#
		#var head_path_container = IS.create_box_container()
		#undo_path_button = IS.create_texture_button(media_explorer.texture_undo_path)
		#reload_button = IS.create_texture_button(media_explorer.texture_reload)
		#path_container = IS.create_box_container(10, false, {alignment = BoxContainer.ALIGNMENT_BEGIN})
		#undo_path_button.pressed.connect(undo.bind(1))
		#reload_button.pressed.connect(update)
		#path_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		#head_path_container.add_child(undo_path_button)
		#head_path_container.add_child(reload_button)
		#head_path_container.add_child(path_container)
		#
		#var scroll_container = IS.create_scroll_container(1,1, {size_flags_vertical = Control.PRESET_FULL_RECT})
		#media_container = IS.create_grid_container(media_explorer.media_display_size)
		#media_container.control_size = media_explorer.media_display_size
		#
		#body_container.add_child(options_container)
		#body_container.add_child(head_path_container)
		#body_container.add_child(scroll_container)
		#scroll_container.add_child(media_container)
		#add_child(body_container)
		#
		#update()
	#
	#func create_folder(display_path: Array, folder_name: String) -> void:
		#media_box_info.file_system_res.create_folder(display_path, folder_name)
		#update()
	#
	#func create_file(display_path: Array, file_path: String) -> void:
		#media_box_info.file_system_res.create_file(display_path, file_path)
	#
	#func delete_file_or_folder(display_path: Array, path_or_name: String) -> void:
		#media_box_info.file_system_res.delete(display_path, path_or_name)
	#
	#func undo(times: int) -> void:
		#for time in times:
			#curr_display_path.pop_back()
		#update()
	#
	#func update() -> void:
		#
		#for i in path_container.get_children(): i.queue_free()
		#for i in media_container.get_children(): i.queue_free()
		#
		#for time in curr_display_path.size() + 1:
			#time -= 1
			#
			#var button = IS.create_button("", null, false, false, {flat = true})
			#var folder_name = "Project"
			#
			#if time > -1:
				#folder_name = curr_display_path[time]
			#
			#var undo_times = curr_display_path.size() - time - 1
			#button.pressed.connect(undo.bind(undo_times))
			#
			#button.text = folder_name
			#path_container.add_child(button)
			#path_container.add_child(IS.create_label("/"))
		#
		#var file_system_res = media_box_info.file_system_res
		#if file_system_res == null:
			#return
		#var files_and_folders = file_system_res.get_files_and_folders_at(curr_display_path)
		#
		#for index in files_and_folders.keys().size():
			#
			#var i = files_and_folders.keys()[index]
			#var info = files_and_folders.get(i)
			#
			#var card = null
			#if info.type == "file":
				#card = media_explorer.media_card_scene.instantiate()
				#card.clicked.connect(on_file_clicked.bind(i))
				#card.resource_path = i
				#card.display_name = i.get_file()
			#else:
				#card = media_explorer.folder_card_scene.instantiate()
				#card.clicked.connect(on_folder_clicked.bind(i))
				#card.display_name = i
			#card.date = info.date
			#
			#card.custom_minimum_size = media_explorer.media_display_size
			#media_container.add_child(card)
			#
			#if info.type == "file":
				#card.display_at(index * .02)
		#
		#filter_and_sort()
	#
	#func filter_and_sort() -> void:
		#var search_text = search_line.text.strip_edges().to_lower()
		#var filter_func: Callable = func(path: String) -> bool:
			#return not curr_filter or MediaServer.get_media_type_from_path(path) == curr_filter - 1
		#
		#var sorted_media_clips: Array[Node] = media_container.get_children()
		#var sort_func: Callable
		#match curr_sort:
			#0:
				#sort_func = func(a, b): return a.display_name.to_lower() < b.display_name.to_lower()
			#1:
				#sort_func = func(a, b):
					#if a.is_folder and not b.is_folder:
						#return true
					#elif not a.is_folder and b.is_folder:
						#return false
					#else:
						#var type_a = MediaServer.get_media_type_from_path(a.resource_path)
						#var type_b = MediaServer.get_media_type_from_path(b.resource_path)
						#return type_a < type_b
			#2:
				#sort_func = func(a, b): return a.date > b.date
			#3:
				#sort_func = func(a, b): return a.date < b.date
		#
		#sorted_media_clips.sort_custom(sort_func)
		#
		#for index in sorted_media_clips.size():
			#var media_card = sorted_media_clips[index]
			#var contains_search_text = media_card.display_name.to_lower().contains(search_text)
			#var resource_path = media_card.resource_path
			#media_card.visible = (search_text.is_empty() or contains_search_text) and filter_func.call(resource_path)
			#media_container.move_child(media_card, index)
	#
	#
	#
	#func on_filter_button_pressed() -> void:
		#var filter_menu = IS.create_popuped_menu(media_box_info.filter)
		#filter_menu.menu_button_pressed.connect(on_filter_menu_button_pressed)
		#get_tree().get_current_scene().add_child(filter_menu)
		#filter_menu.popup()
	#
	#func on_sort_button_pressed() -> void:
		#var sort_menu = IS.create_popuped_menu(media_box_info.sort)
		#sort_menu.menu_button_pressed.connect(on_sort_menu_button_pressed)
		#get_tree().get_current_scene().add_child(sort_menu)
		#sort_menu.popup()
	#
	#func on_folder_button_pressed() -> void:
		#var name_line = IS.create_line_edit("Type Folder Name", "New Folder")
		#var box = WindowManager.popup_accept_window(
			#get_tree().current_scene,
			#Vector2(400, 150),
			#"Create Folder",
			#func(): create_folder(curr_display_path, name_line.text)
		#)
		#box.add_child(name_line)
		#box.move_child(name_line, 0)
		#name_line.select()
		#name_line.grab_focus()
	#
	#func on_import_button_pressed() -> void:
		#var file_dialog = WindowManager.create_file_dialog_window(
			#get_tree().current_scene, FileDialog.FILE_MODE_OPEN_FILES, MediaServer.MEDIA_EXTENSIONS
		#)
		#file_dialog.files_selected.connect(func(paths: PackedStringArray):
			#for path: String in paths:
				#create_file(curr_display_path, path)
			#update()
		#)
		#file_dialog.popup_centered()
	#
	#func on_folder_clicked(folder_name: String) -> void:
		#curr_display_path.append(folder_name)
		#update()
	#
	#func on_file_clicked(file_path: String) -> void:
		#ProjectServer.add_media_clip(file_path, -1, EditorServer.time_line.curr_frame)
	#
	#func on_filter_menu_button_pressed(index: int) -> void:
		#curr_filter = index
		#filter_and_sort()
	#
	#func on_sort_menu_button_pressed(index: int) -> void:
		#curr_sort = index
		#filter_and_sort()



#func _start() -> void:
	#super()
	#
	## Start Header
	#var header_menu = IS.create_menu(media_options)
	#header_menu.focus_index_changed.connect(on_header_menu_focus_index_changed)
	#header.add_child(header_menu)
	#
	## Start Body
	#for media in media_info:
		#var media_box = MediaBox.new(self)
		#media_box.create(media)
		#body.add_child(media_box)

#func delete_files_or_folders(pathes_or_names: Array) -> void:
	#for path_or_name in pathes_or_names:
		#delete_file_or_folder(path_or_name, false)
	#get_media_box(0).update()
#
#
#func get_media_box(index: int) -> MediaBox:
	#return body.get_child(index)
