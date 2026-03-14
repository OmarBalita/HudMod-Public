class_name MediaExplorer extends EditorControl

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
@export var card_display_size: Vector2 = Vector2(140, 140)

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


func _ready_editor() -> void:
	
	header_menu = IS.create_menu([
		MenuOption.new("Import", texture_import),
		MenuOption.new("Object", texture_object),
		MenuOption.new("Transition", texture_transition),
		MenuOption.new("Preset", texture_preset)
	])
	header_menu.focus_index_changed.connect(set_curr_media_box)
	header.add_child(header_menu)
	
	IS.add_children(body, [
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
	
	var selection_group:= SelectionGroupRes.new()
	
	var categories: Dictionary[String, Category]
	
	var media_explorer: MediaExplorer
	
	var body_container: BoxContainer
	
	var options_container: BoxContainer
	var media_categories_box: BoxContainer
	
	var search_line: LineEdit
	
	# filter and sort in RealTime
	var curr_filter: int
	var curr_sort: int
	
	func _init(_media_explorer: MediaExplorer) -> void:
		media_explorer = _media_explorer
	
	func _ready() -> void:
		
		body_container = IS.create_box_container(10, true)
		options_container = IS.create_box_container()
		var scroll_container = IS.create_scroll_container(1,1, {size_flags_vertical = Control.PRESET_FULL_RECT})
		var margin_container = IS.create_margin_container(12, 12, 12, 12)
		media_categories_box = IS.create_box_container(12, true, {})
		
		IS.expand(margin_container, true, true)
		IS.expand(media_categories_box, true, true)
		body_container.clip_contents = false
		media_categories_box.clip_contents = false
		
		margin_container.add_child(media_categories_box)
		scroll_container.add_child(margin_container)
		body_container.add_child(options_container)
		body_container.add_child(scroll_container)
		add_child(body_container)
		
		_ready_options()
	
	func _ready_options() -> void:
		search_line = IS.create_line_edit("Search for Media", "", media_explorer.texture_search)
		search_line.text_changed.connect(on_search_line_text_changed)
		options_container.add_child(search_line)
	
	func add_category(category_name: StringName, has_header: bool = true, accent_color: Color = Color.BLACK) -> Category:
		var category = IS.create_category(has_header, category_name, accent_color, media_explorer.card_display_size)
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
		
		var search_query: String = search_line.text.strip_edges().to_lower()
		var filter_func: Callable = _get_filter_func()
		var sort_func: Callable = _get_sort_func()
		
		for cat_name: StringName in categories:
			
			var category: Category = categories[cat_name]
			var cat_sorted_cards:= category.get_contents()
			cat_sorted_cards.sort_custom(sort_func)
			
			for index: int in cat_sorted_cards.size():
				var card: MediaCard = cat_sorted_cards[index]
				var is_finded: bool = StringHelper.fuzzy_search(search_query, card.display_name.to_lower())
				card.visible = filter_func.call(card) and (search_query.is_empty() or is_finded)
				category.move_content(card, index)
	
	func on_search_line_text_changed(new_text: String) -> void:
		filter_and_sort()
	
	func _get_filter_options() -> Array[Dictionary]:
		return []
	
	func _get_filter_func() -> Callable:
		return func(card: MediaCard) -> bool: return true
	
	func _get_sort_options() -> Array[Dictionary]:
		return [
			{text = "Name"},
			{text = "Type"},
			{text = "Latest to Earliest"},
			{text = "Earliest to Latest"},
		]
	
	func _get_sort_func() -> Callable:
		match curr_sort:
			0:
				return func(a: CreatedCard, b: CreatedCard) -> bool:
					return a.display_name.to_lower() < b.display_name.to_lower()
			1:
				return func(a: CreatedCard, b: CreatedCard) -> bool:
					if a.created_card_type == b.created_card_type:
						return a.create_date > b.create_date
					return a.created_card_type < b.created_card_type
			2:
				return func(a: CreatedCard, b: CreatedCard) -> bool: return a.create_date > b.create_date
			3:
				return func(a: CreatedCard, b: CreatedCard) -> bool: return a.create_date < b.create_date
			_:
				return Callable()


class CreatedBox extends MediaBox:
	
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
	
	func get_display_file_system() -> DisplayFileSystemRes:
		return display_file_system
	
	func set_display_file_system(new_val: DisplayFileSystemRes, _update: bool = true) -> void:
		display_file_system = new_val
		if _update: update()
	
	func get_true_file_system(global: bool) -> DisplayFileSystemRes:
		return global_file_system if global else project_file_system
	
	func _init(_media_explorer: MediaExplorer) -> void:
		display_file_system = project_file_system
		super(_media_explorer)
	
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
		undo_path_button = IS.create_texture_button(media_explorer.texture_undo_path)
		reload_button = IS.create_texture_button(media_explorer.texture_reload)
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
		
		folder_button = IS.create_button("", media_explorer.texture_folder)
		folder_button.pressed.connect(_on_folder_button_pressed)
		options_container.add_child(folder_button)
	
	func on_filter_button_selected_option_changed(index: int, option: MenuOption) -> void:
		curr_filter = index
		filter_and_sort()
	
	func on_sort_button_selected_option_changed(index: int, option: MenuOption) -> void:
		curr_sort = index
		filter_and_sort()
	
	func undo(times: int) -> void:
		for time: int in times:
			curr_display_path.resize(curr_display_path.size() - 1)
		update()
	
	func update() -> void:
		selection_group.clear_objects()
		
		path_controller.update(curr_display_path)
		if display_file_system == null: return
		var files_and_folders: Dictionary = display_file_system.get_files_and_folders_at(curr_display_path)
		
		var created_box_cat: Category = _get_created_box_category()
		if created_box_cat == null: return
		created_box_cat.remove_all_contents()
		
		for index: int in files_and_folders.size():
			
			var key: String = files_and_folders.keys()[index]
			var info: Dictionary = files_and_folders.values()[index]
			var type: String = info.type
			
			var card: CreatedCard
			if type == "folder":
				# the key be the folder name when the type is "folder"
				var folder_card:= FolderCard.new()
				folder_card.created_card_type = -1
				folder_card.info = {
					&"type": -1,
					&"length": int(EditorServer.editor_settings.media_clip_default_length * ProjectServer.fps),
					&"name": key,
					&"forward": info.forward
				}
				folder_card.clicked.connect(_on_folder_clicked.bind(key))
				card = folder_card
			else:
				card = _init_card(key, info, type)
			
			card.created_box = self
			card.create_date = info.date
			card.custom_minimum_size = media_explorer.card_display_size
			card.selection_group = selection_group
			created_box_cat.add_content(card)
		
		filter_and_sort()
	
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
	
	func _get_selected_paths_or_names() -> PackedStringArray:
		var paths_or_names: PackedStringArray
		var cards: Array[Node] = _get_created_box_category().get_contents()
		for card: CreatedCard in cards:
			if card.is_selected:
				paths_or_names.append(card._get_created_card_name_or_path())
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
		EditorServer.scan_media_existent()
	
	func delete_selected(delete_real_files: bool = false) -> void:
		var paths_or_names: PackedStringArray = _get_selected_paths_or_names()
		delete_files_or_folders(curr_display_path, paths_or_names, delete_real_files)
	
	func _on_folder_clicked(folder_name: String) -> void:
		curr_display_path.append(folder_name)
		update()
	
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

class ImportBox extends CreatedBox:
	
	@export var texture_folder: Texture2D = preload("res://Asset/Icons/folder.png")
	@export var texture_check: Texture2D = IS.TEXTURE_CHECK
	@export var texture_x_mark: Texture2D = IS.TEXTURE_X_MARK
	@export var texture_wait: Texture2D = preload("res://Asset/Icons/hourglass.png")
	
	var import_button: Button
	
	var import_category: Category
	
	var progress_window: Window
	var progress_list: ItemList
	var progress_bar: ProgressBar
	
	func _init(_media_explorer: MediaExplorer) -> void:
		project_file_system = ProjectServer.import_file_system
		global_file_system = GlobalServer.import_file_system
		super(_media_explorer)
	
	func _ready() -> void:
		super()
		#load_files(PackedStringArray([
			#"C:/Users/User/Documents/Godot Projects/edit-app/Asset/Icons/icon.svg",
			#"C:/Users/User/Documents/Godot Projects/edit-app/Asset/Icons/App/logo2_512.png",
			#"C:/Users/User/Documents/Godot Projects/edit-app/35mm-film-projector-start-99740.mp3"
		#]))
		update()
	
	func _ready_options() -> void:
		super()
		
		import_category = add_category("Import", false)
		
		import_button = IS.create_button("", media_explorer.texture_file, true)
		import_button.pressed.connect(on_import_button_pressed)
		options_container.add_child(import_button)
	
	func _init_card(key: String, info: Dictionary, type: String) -> CreatedCard:
		# the Key be the file path when the type is "file"
		var media_type: int = info.media_type
		var import_card:= ImportCard.new()
		
		import_card.discarded = info.has(&"discard")
		import_card.created_card_type = media_type + 1
		import_card.info = {
			&"type": media_type,
			&"path": key
		}
		return import_card
	
	# move_option: 0 = MOVE_TO_PROJECT, 1 = MOVE_TO_GLOBAL
	func move_selected(move_option: int, move_to_display_path: Array, move_fake_files: bool, move_real_files: bool) -> void:
		
		var is_global: bool = move_option == 1
		var move_from: Dictionary = display_file_system.get_dir(curr_display_path)
		
		var target_file_system: DisplayFileSystemRes = get_true_file_system(is_global)
		
		var paths_or_names: PackedStringArray = _get_selected_paths_or_names()
		
		var files_paths: PackedStringArray
		var folders: Dictionary[String, Dictionary]
		
		for path_or_name: String in paths_or_names:
			if path_or_name.is_absolute_path():
				files_paths.append(path_or_name)
			elif path_or_name.is_valid_filename():
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
			
			display_file_system.delete_packed(curr_display_path, paths_or_names, false)
			target_file_system.create_files(move_to_display_path, files_paths)
			target_file_system.add_folders(move_to_display_path, folders)
			
			display_file_system = target_file_system
			curr_display_path = move_to_display_path
		
		EditorServer.scan_media_existent()
		EditorServer.save()
	
	func replace_selected() -> void:
		var paths_or_names: PackedStringArray = _get_selected_paths_or_names()
		EditorServer.popup_replace_paths_window(paths_or_names, false, true)
	
	func on_import_button_pressed() -> void:
		var file_dialog: FileDialog = WindowManager.create_file_dialog_window(
			get_tree().current_scene,
			FileDialog.FILE_MODE_OPEN_FILES,
			MediaServer.MEDIA_EXTENSIONS
		)
		file_dialog.files_selected.connect(on_file_dialog_files_selected)
		file_dialog.popup_centered()
	
	func on_file_dialog_files_selected(paths: PackedStringArray) -> void:
		load_files(paths)
	
	func load_files(paths: PackedStringArray) -> void:
		var window_margin: MarginContainer = WindowManager.popup_window(get_window(), Vector2i(600, 400))
		var box_container: BoxContainer = IS.create_box_container(12, true)
		
		progress_window = window_margin.get_window()
		progress_list = ItemList.new()
		progress_bar = IS.create_progress_bar(.0, .0, 100.0, .01)
		progress_bar.value_changed.connect(
			func(value: float) -> void:
				if value >= progress_bar.max_value:
					update()
					progress_window.queue_free()
		)
		
		box_container.add_child(progress_list)
		box_container.add_child(progress_bar)
		window_margin.add_child(box_container)
		
		IS.set_base_settings(progress_list)
		IS.expand(progress_list, true, true)
		
		var thread: Thread = Thread.new()
		thread.start(_thread_create_files.bind(paths, curr_display_path))
	
	func _thread_create_files(paths: PackedStringArray, curr_display_path: Array) -> void:
		var load_errs: Array[MediaCache.LOAD_ERR]
		var total: int = paths.size()
		for index: int in total:
			var path: String = paths.get(index)
			_report_start.call_deferred(index, path)
			var load_err: MediaCache.LOAD_ERR = await create_file(curr_display_path, path)
			_report_progress.call_deferred(index, total, path, load_err == 0)
			
			load_errs.append(load_err)
	
	func _report_start(index: int, path: String) -> void:
		progress_list.add_item(path, texture_wait)
	
	func _report_progress(index: int, total: int, path: String, load_success: bool) -> void:
		progress_list.set_item_custom_bg_color(index, Color(Color.GREEN_YELLOW, .1))
		progress_list.set_item_text(index, path.get_file())
		progress_list.set_item_icon(index, texture_check if load_success else texture_x_mark)
		
		var tween: Tween = create_tween()
		var progress_bar_val: float = ((index + 1) / float(total)) * 100.0
		tween.tween_property(progress_bar, "value", progress_bar_val, .2)
		
		await get_tree().process_frame
		var scroll_bar: VScrollBar = progress_list.get_v_scroll_bar()
		scroll_bar.value = scroll_bar.max_value
	
	func _get_filter_options() -> Array[Dictionary]:
		return [
			{text = "All"},
			{text = "Image"},
			{text = "Video"},
			{text = "Audio"},
		]
	
	func _get_filter_func() -> Callable:
		return func(card: MediaCard) -> bool:
			return not curr_filter or card.created_card_type == curr_filter or card.created_card_type == -1
	
	func _get_created_box_category() -> Category:
		return import_category

class ObjectBox extends MediaBox:
	
	func _ready() -> void:
		super()
		add_category(&"Object", true, Color.LIGHT_GRAY)
		add_category(&"Object2D", true, Color("6699ff"))
		add_category(&"Object3D (Coming soon)", true, Color.BLACK)
		
		var clips_ress: Dictionary[StringName, Dictionary] = ClassServer.get_media_clip_classes()
		
		for object_classname: StringName in clips_ress:
			var object_info: Dictionary = clips_ress[object_classname]
			var object_script: Script = object_info.script
			
			if object_script.is_abstract() or not object_script.is_media_clip_spawnable():
				continue
			
			var category_name: StringName = object_script.get_explorer_section()
			
			var category: Category = get_category(category_name)
			var object_card: ObjectCard = ObjectCard.new()
			
			if category == null:
				continue
			
			object_card.info = {
				&"type": -1,
				&"name": object_classname,
				&"thumbnail": object_info.icon,
				&"media_clip_script": object_script,
			}
			object_card.custom_minimum_size = media_explorer.card_display_size
			
			category.add_content(object_card)
			object_card.thumbnail_texture_rect.modulate = Color(category.category_custom_color, .75)
			
			object_card.selection_group = selection_group

class TransitionBox extends MediaBox:
	pass

class PresetBox extends CreatedBox:
	
	var preset_category: Category
	
	func _init(_media_explorer: MediaExplorer) -> void:
		project_file_system = ProjectServer.preset_file_system
		global_file_system = GlobalServer.preset_file_system
		super(_media_explorer)
	
	func _ready() -> void:
		super()
		update()
	
	func _ready_options() -> void:
		super()
		preset_category = add_category(&"Preset", false)
	
	func _init_card(key: String, info: Dictionary, type: String) -> CreatedCard:
		var preset_card:= PresetCard.new()
		var preset_media_res: MediaClipRes = MediaCache.get_preset_media_res(key)
		preset_card.discarded = info.has(&"discard")
		preset_card.info = {
			&"path": key,
			&"preset_media_res": preset_media_res,
			&"length": preset_media_res.length,
		}
		return preset_card
	
	func _get_created_box_category() -> Category:
		return preset_category
	
	func create_presets(preset_media_ress: Array[MediaClipRes], global: bool) -> void:
		var preset_files_pathes: PackedStringArray = EditorServer.create_presets(preset_media_ress, global)
		set_display_file_system(get_true_file_system(global))
		create_files(curr_display_path, preset_files_pathes)
		update()



class MediaCard extends DoubleClickControl:
	
	@onready var name_label: Label
	@onready var add_button: TextureButton
	@onready var thumbnail_texture_rect: TextureRect
	
	@export var display_name: StringName = &"Media Card"
	@export var display_texture: Texture2D
	@export var add_texture: Texture2D = preload("res://Asset/Icons/plus.png")
	
	@export var info: Dictionary[StringName, Variant]
	
	func _init() -> void:
		selectable = true
		draggable = true
		
		draw_select = true
		draw_width = 3.0
	
	func _ready() -> void:
		super()
		drag_started.connect(on_drag_started)
		drag_finished.connect(on_drag_finished)
	
	func _get_dragged_rect() -> Control:
		return
	
	func _double_click() -> void:
		add_media(-1, EditorServer.frame)
		EditorServer.media_clips_selection_group.selected_objects_changed.emit()
		super()
	
	func _setup_media_card(name: StringName, thumbnail_texture: Texture2D) -> void:
		
		name_label = IS.create_label(name)
		add_button = IS.create_texture_button(add_texture)
		thumbnail_texture_rect = IS.create_texture_rect(thumbnail_texture, {})
		
		var panel_container:= IS.create_panel_container(Vector2.ZERO, IS.STYLE_PANEL)
		var margin_container:= IS.create_margin_container()
		var split_container:= IS.create_split_container(2, true)
		var split_container2:= IS.create_split_container()
		
		IS.add_children(split_container2, [add_button, name_label])
		IS.add_children(split_container, [thumbnail_texture_rect, split_container2])
		margin_container.add_child(split_container)
		panel_container.add_child(margin_container)
		add_child(panel_container)
		
		name_label.set_text_overrun_behavior(TextServer.OVERRUN_TRIM_ELLIPSIS)
		panel_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		
		thumbnail_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		IS.expand(thumbnail_texture_rect, true, true)
		
		add_button.pressed.connect(on_add_button_pressed)
		
		display_name = name
		display_texture = thumbnail_texture
	
	func add_media(layer_index: int, frame_in: int) -> void:
		pass
	
	func on_add_button_pressed() -> void:
		add_media(0, EditorServer.frame)
		EditorServer.media_clips_selection_group.selected_objects_changed.emit()
	
	func on_drag_started() -> void:
		if not following_drag:
			selection_group.clear_previously_freed_instances()
			EditorServer.time_line.clips_start_move(
				TimeLine.ClipsMoveMode.MOVE_ADD,
				selection_group.selected_objects.values(),
				selection_group.selected_objects[get_id_key()]
			)
	
	func on_drag_finished() -> void:
		if not following_drag:
			EditorServer.time_line.clips_end_move()

class CreatedCard extends MediaCard:
	enum CreatedCardType {
		TYPE_FOLDER = -1,
		TYPE_IMAGE = 0,
		TYPE_VIDEO = 1,
		TYPE_AUDIO = 2
	}
	
	@export var created_card_type: CreatedCardType
	@export var create_date: float
	
	var created_box: CreatedBox
	var discarded: bool:
		set(val):
			discarded = val
			draggable = not val
	
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				var mouse_pos: Vector2 = get_global_mouse_position()
				if event.is_pressed():
					press_pos = mouse_pos
				else:
					if press_pos.distance_to(mouse_pos) < min_drag_distance:
						select(event.ctrl_pressed, false)
						_popup_created_card_menu()
	
	func _popup_created_card_menu() -> void:
		var options: Array = _get_created_card_menu_options()
		var menu:= IS.popup_menu(options)
	
	func _get_created_card_menu_options() -> Array:
		return [
			MenuOption.new("Copy Path", null, copy_path),
			MenuOption.new("Delete", null, delete),
			MenuOption.new_line(),
			MenuOption.new("Open in External Program", null, open_in_external_program),
			MenuOption.new("Show in File Manager", null, show_in_file_manager)
		]
	
	func copy_path() -> void:
		DisplayServer.clipboard_set(info.path)
	
	func delete() -> void:
		created_box.delete_selected()
		created_box.update()
	
	func open_in_external_program() -> void:
		OS.shell_open(info.path)
	
	func show_in_file_manager() -> void:
		OS.shell_show_in_file_manager(info.path)
	
	func _get_created_card_name_or_path() -> String:
		return info.path

class ImportCard extends CreatedCard:
	
	func _ready() -> void:
		super()
		var thumb: Texture2D
		if discarded: thumb = IS.TEXTURE_X_MARK
		else: thumb = MediaServer.get_thumbnail(info.path).texture
		_setup_media_card(info.path.get_file(), thumb)
		set_metadata(info)
	
	func select(group: bool, remove: bool, is_drag_selection: bool = false, emit_change: bool = true) -> void:
		super(group, remove, is_drag_selection, emit_change)
		
		if discarded:
			EditorServer.properties._clear_controls()
		elif not is_drag_selection:
			var imported_info: Dictionary[StringName, String] = MediaServer.get_imported_file_info(info.path, info.type)
			EditorServer.properties.update_media_properties(imported_info)
	
	func add_media(layer_index: int, frame_in: int) -> void:
		if discarded: return
		var clip_res: MediaClipRes
		match info.type:
			0:
				clip_res = ImageClipRes.new()
				clip_res.image = info.path
			1:
				clip_res = VideoClipRes.new()
				clip_res.video = info.path
			2:
				clip_res = AudioClipRes.new()
				clip_res.stream = info.path
		ProjectServer.add_media_clip(clip_res, EditorServer.editor_settings.media_clip_default_length_f, layer_index, frame_in, false)
	
	func _get_created_card_menu_options() -> Array:
		return [
			MenuOption.new("Move to", null, popup_move_to_window),
			MenuOption.new("Replace", null, created_box.replace_selected),
			MenuOption.new_line()
		] + super()
	
	func popup_move_to_window() -> void:
		var move_optionbutton: OptionController = IS.create_float_edit.callv(["Move to"] + UsableRes.options_args(0, {"PROJECT": 0, "GLOBAL": 1}))[0]
		
		var move_fake_files_checkbutton: CheckButton = IS.create_bool_edit("Move in Embeded file system ", false)[0]
		var tree: Tree = IS.create_tree()
		
		var move_real_file_checkbutton: CheckButton = IS.create_bool_edit("Move in Disk", true)[0]
		var warning_text_edit: CustomTextEdit = IS.create_text_edit()
		warning_text_edit.add_theme_color_override("font_readonly_color", IS.COLOR_WARNING_YELLOW)
		IS.expand(warning_text_edit, true, true)
		warning_text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		warning_text_edit.editable = false
		
		var update_ui_func: Callable = func() -> void:
			var move_to_global: bool = move_optionbutton.selected_id == 1
			
			var text: String = "Warning"
			var target_name: String = "Global" if move_to_global else "Project"
			
			tree.visible = move_fake_files_checkbutton.button_pressed
			var move_to_file_system: DisplayFileSystemRes = created_box.get_true_file_system(move_to_global)
			move_to_file_system.build_tree(tree, "%s (Fake Files)" % target_name)
			tree.set_selected(tree.get_root(), 0)
			
			if move_fake_files_checkbutton.button_pressed:
				text += "\n\n- media will be moved to the specified folder in '%s' within the HudMod custom file system." % target_name
			if move_real_file_checkbutton.button_pressed:
				text += "\n\n- media files will be moved to the '%s' media dir in disk." % target_name
			text += "\n\n- No undo."
			warning_text_edit.text = text
		
		update_ui_func.call()
		move_optionbutton.selected_option_changed.connect(func(id: int, option: MenuOption) -> void: update_ui_func.call())
		move_fake_files_checkbutton.pressed.connect(update_ui_func)
		move_real_file_checkbutton.pressed.connect(update_ui_func)
		
		var box: BoxContainer = WindowManager.popup_accept_window(get_window(), Vector2i(400, 600), "Move to", func() -> void:
			created_box.move_selected(
				move_optionbutton.selected_id,
				tree.get_selected().get_metadata(0),
				move_fake_files_checkbutton.button_pressed,
				move_real_file_checkbutton.button_pressed
			)
		)
		IS.add_children(box, [
			move_optionbutton.get_parent(),
			move_fake_files_checkbutton.get_parent(),
			tree,
			move_real_file_checkbutton.get_parent(),
			warning_text_edit
		])

class FolderCard extends CreatedCard:
	
	func _ready() -> void:
		super()
		_setup_media_card(info.name, IS.TEXTURE_FOLDER)
		set_metadata({&"type": 0})
	
	func _double_click() -> void:
		clicked.emit()
	
	func select(group: bool, remove: bool, is_drag_selection: bool = false, emit_change: bool = true) -> void:
		super(group, remove, is_drag_selection, emit_change)
		EditorServer.properties._clear_controls()
	
	func add_media(layer_index: int, frame_in: int) -> void:
		var forward: Dictionary = info.forward
		for key: String in forward:
			var key_info: Dictionary = forward.get(key)
			if key_info.type == "file":
				var media_type: int = key_info.media_type
				ProjectServer.add_imported_clip(media_type, key, layer_index, frame_in)
		
		ProjectServer.emit_media_clips_change()
	
	func _get_created_card_name_or_path() -> String:
		return info.name
	
	func _get_created_card_menu_options() -> Array:
		return [MenuOption.new("Delete", null, delete)]

class ObjectCard extends MediaCard:
	
	func _ready() -> void:
		super()
		_setup_media_card(info.name, info.thumbnail)
		set_metadata(info)
	
	func select(group: bool, remove: bool, is_drag_selection: bool = false, emit_change: bool = true) -> void:
		super(group, remove, is_drag_selection, emit_change)
		if not is_drag_selection:
			EditorServer.properties.update_media_properties(info.media_clip_script.get_media_clip_info())
	
	func add_media(layer_index: int, frame_in: int) -> void:
		var clip_res: MediaClipRes = info.media_clip_script.new()
		ProjectServer.add_media_clip(clip_res, EditorServer.editor_settings.media_clip_default_length_f, layer_index, frame_in, false)

class TransitionCard extends MediaCard:
	pass

class PresetCard extends CreatedCard:
	
	static var preset_thumbnail: Texture2D = preload("res://Asset/Icons/preset.png")
	
	func _ready() -> void:
		super()
		_setup_media_card(info.preset_media_res.id, IS.TEXTURE_X_MARK if discarded else preset_thumbnail)
		set_metadata(info)
	
	func select(group: bool, remove: bool, is_drag_selection: bool = false, emit_change: bool = true) -> void:
		super(group, remove, is_drag_selection, emit_change)
		EditorServer.properties._clear_controls()
	
	func add_media(layer_index: int, frame_in: int) -> void:
		if discarded: return
		ProjectServer.add_preset_clip(info.preset_media_res, layer_index, frame_in, true)
	
	func delete() -> void:
		created_box.delete_selected(true)
		created_box.update()
