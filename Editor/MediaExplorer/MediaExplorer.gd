class_name MediaExplorer extends EditorRect

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
	
	func on_search_line_text_changed(new_text: String) -> void:
		filter_and_sort()


class ImportBox extends MediaBox:
	
	@export var texture_folder: Texture2D = preload("res://Asset/Icons/folder.png")
	@export var texture_check: Texture2D = preload("res://Asset/Icons/check.png")
	@export var texture_wait: Texture2D = preload("res://Asset/Icons/hourglass.png")
	
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
	
	var progress_window: Window
	var progress_list: ItemList
	var progress_bar: ProgressBar
	
	
	func _ready() -> void:
		super()
		on_file_dialog_files_selected(PackedStringArray([
			"C:/Users/User/Documents/Godot Projects/edit-app/Asset/Icons/icon.svg",
			"C:/Users/User/Documents/Godot Projects/edit-app/Asset/Icons/App/logo2_512.png",
			"C:/Users/User/Documents/Godot Projects/edit-app/35mm-film-projector-start-99740.mp3"
		]))
		update()
	
	func _ready_options() -> void:
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
		
		if display_file_system == null: return
		var files_and_folders: Dictionary = display_file_system.get_files_and_folders_at(curr_display_path)
		
		for index: int in files_and_folders.size():
			
			var key: String = files_and_folders.keys()[index]
			var info: Dictionary = files_and_folders.values()[index]
			var type: String = info.type
			
			var card: CreatedCard = null
			
			match type:
				"file":
					# the Key be the file path when the type is "file"
					var media_type: int = info.media_type
					var media_cache: Variant = MediaCache.get_from_type(key, media_type)
					var import_card:= ImportCard.new()
					import_card.created_card_type = media_type + 1
					import_card.import_info = {
						&"type": media_type,
						&"path": key,
						&"thumbnail": MediaServer.get_thumbnail(key).texture
					}
					card = import_card
				
				"folder":
					# the key be the folder name when the type is "folder"
					var folder_card:= FolderCard.new()
					folder_card.created_card_type = -1
					folder_card.folder_info = {
						&"type": -1,
						&"name": key,
						&"forward": info.forward
					}
					folder_card.clicked.connect(on_folder_clicked.bind(key))
					card = folder_card
			
			card.create_date = info.date
			card.custom_minimum_size = media_explorer.card_display_size
			import_category.add_content(card)
		
		filter_and_sort()
	
	func filter_and_sort() -> void:
		
		var search_text: String = search_line.text.strip_edges().to_lower()
		var filter_func: Callable = func(type: int) -> bool:
			return not curr_filter or type == curr_filter or type == -1
		
		var sorted_media_clips: Array[Node] = import_category.get_contents()
		var sort_func: Callable
		match curr_sort:
			0:
				sort_func = func(a: CreatedCard, b: CreatedCard) -> bool:
					return a.display_name.to_lower() < b.display_name.to_lower()
			
			1:
				sort_func = func(a: CreatedCard, b:CreatedCard) -> bool:
					if a.created_card_type and not b.created_card_type: return true
					elif not a.created_card_type and b.created_card_type: return false
					else: return a.created_card_type < b.created_card_type
			
			2: sort_func = func(a: CreatedCard, b: CreatedCard) -> bool: return a.create_date > b.create_date
			3: sort_func = func(a: CreatedCard, b: CreatedCard) -> bool: return a.create_date < b.create_date
		
		sorted_media_clips.sort_custom(sort_func)
		
		for index: int in sorted_media_clips.size():
			var card: CreatedCard = sorted_media_clips[index]
			var contains_search_text: bool = card.display_name.to_lower().contains(search_text)
			card.visible = filter_func.call(card.created_card_type) and (search_text.is_empty() or contains_search_text)
			import_category.move_content(card, index)
	
	
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
			get_tree().current_scene,
			FileDialog.FILE_MODE_OPEN_FILES,
			MediaServer.MEDIA_EXTENSIONS
		)
		file_dialog.files_selected.connect(on_file_dialog_files_selected)
		file_dialog.popup_centered()
	
	func on_folder_clicked(folder_name: String) -> void:
		curr_display_path.append(folder_name)
		update()
	
	
	func on_file_dialog_files_selected(paths: PackedStringArray) -> void:
		
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
		var total: int = paths.size()
		for index: int in total:
			var path: String = paths.get(index)
			_report_start.call_deferred(index, path)
			await create_file(curr_display_path, path)
			_report_progress.call_deferred(index, total, path)
	
	func _report_start(index: int, path: String) -> void:
		progress_list.add_item(path, texture_wait)
	
	func _report_progress(index: int, total: int, path: String) -> void:
		
		progress_list.set_item_custom_bg_color(index, Color(Color.GREEN_YELLOW, .1))
		progress_list.set_item_text(index, path.get_file())
		progress_list.set_item_icon(index, texture_check)
		
		var tween: Tween = create_tween()
		var progress_bar_val: float = ((index + 1) / float(total)) * 100.0
		tween.tween_property(progress_bar, "value", progress_bar_val, .2)
		
		await get_tree().process_frame
		var scroll_bar: VScrollBar = progress_list.get_v_scroll_bar()
		scroll_bar.value = scroll_bar.max_value

class ObjectBox extends MediaBox:
	
	func _ready() -> void:
		super()
		var cat_object_2d: Category = add_category("Object2D")
		var cat_object_3d: Category = add_category("Object3D")
		
		var objects: Dictionary[StringName, Dictionary] = TypeServer.objects
		
		for object_key: StringName in objects:
			var object_info: Dictionary = objects[object_key]
			var object_card: ObjectCard = ObjectCard.new()
			object_card.object_info = {
				&"type": -1,
				&"name": object_key,
				&"thumbnail": object_info.icon,
				&"object_id": object_info.type_id
			}
			object_card.custom_minimum_size = media_explorer.card_display_size
			get_category(object_info.category).add_content(object_card)

class TransitionBox extends MediaBox:
	pass

class PresetBox extends MediaBox:
	pass




class MediaCard extends DoubleClickControl:
	
	@onready var name_label: Label
	@onready var add_button: TextureButton
	@onready var thumbnail_texture_rect: TextureRect
	
	@export var display_name: StringName = &"Media Card"
	@export var display_texture: Texture2D = preload("res://Asset/icons/icon.svg")
	@export var add_texture: Texture2D = preload("res://Asset/Icons/plus.png")
	
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
		super()
	
	func _setup_media_card(name: StringName, thumbnail_texture: Texture2D) -> void:
		
		name_label = IS.create_label(name)
		add_button = IS.create_texture_button(add_texture)
		thumbnail_texture_rect = IS.create_texture_rect(thumbnail_texture, {})
		
		var panel_container:= IS.create_panel_container(Vector2.ZERO, IS.STYLE_PANEL)
		var margin_container:= IS.create_margin_container()
		var split_container:= IS.create_split_container(2, true)
		var split_container2:= IS.create_split_container()
		
		IS.add_childs(split_container2, [add_button, name_label])
		IS.add_childs(split_container, [thumbnail_texture_rect, split_container2])
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

class ImportCard extends CreatedCard:
	
	@export var import_info: Dictionary[StringName, Variant]
	
	func _ready() -> void:
		super()
		selection_group = EditorServer.object_media_cards_selection_group
		_setup_media_card(import_info.path.get_file(), import_info.thumbnail)
		set_metadata(import_info)
	
	func add_media(layer_index: int, frame_in: int) -> void:
		ProjectServer.add_imported_clip(import_info.type, import_info.path, layer_index, frame_in, true)


class FolderCard extends CreatedCard:
	
	@export var folder_texture: Texture2D = preload("res://Asset/Icons/folder.png")
	
	var folder_info: Dictionary[StringName, Variant]
	
	func _ready() -> void:
		super()
		selection_group = EditorServer.import_media_cards_selection_group
		_setup_media_card(folder_info.name, folder_texture)
		set_metadata({&"type": 0})
	
	func _double_click() -> void:
		clicked.emit()
	
	func add_media(layer_index: int, frame_in: int) -> void:
		var forward: Dictionary = folder_info.forward
		for key: String in forward:
			var key_info: Dictionary = forward.get(key)
			if key_info.type == "file":
				var media_type: int = key_info.media_type
				ProjectServer.add_imported_clip(media_type, key, layer_index, frame_in)
		ProjectServer.emit_media_clips_change()


class ObjectCard extends MediaCard:
	
	@export var object_info: Dictionary[StringName, Variant]
	
	func _ready() -> void:
		super()
		selection_group = EditorServer.object_media_cards_selection_group
		_setup_media_card(object_info.name, object_info.thumbnail)
		set_metadata(object_info)
	
	func add_media(layer_index: int, frame_in: int) -> void:
		var object_res: ObjectRes = object_info.object_id.new()
		ProjectServer.add_object_clip(object_res, layer_index, frame_in, true)

class TransitionCard extends MediaCard:
	pass

class PresetCard extends MediaCard:
	pass



















