class_name ImportBox extends CreatedBox

@export var texture_folder: Texture2D = preload("res://Asset/Icons/folder.png")
@export var texture_check: Texture2D = IS.TEXTURE_CHECK
@export var texture_x_mark: Texture2D = IS.TEXTURE_X_MARK
@export var texture_wait: Texture2D = preload("res://Asset/Icons/hourglass.png")

var import_button: Button

var import_category: Category

var progress_window: Window
var progress_list: ItemList
var progress_bar: ProgressBar

func _ready_options() -> void:
	super()
	
	import_category = add_category("Import", false)
	
	import_button = IS.create_button("", media_explorer.texture_file, true)
	import_button.pressed.connect(on_import_button_pressed)
	options_container.add_child(import_button)

func _init_card(key: String, info: Dictionary, type: String) -> CreatedCard:
	var media_type: int = info.media_type
	var import_card:= ImportCard.new(self, 0)
	
	import_card.display_name = key.get_file()
	import_card.display_texture = MediaServer.get_thumbnail(key).texture
	import_card.created_card_type = CreatedCard.CreatedCardType.CARD_TYPE_PRESET
	import_card.type = media_type
	import_card.path_or_name = key
	import_card.disabled = info.has(&"discard")
	
	return import_card

func replace_selected() -> void:
	var paths_or_names: PackedStringArray = get_selected_paths_or_names(true, false)
	EditorServer.popup_replace_paths(paths_or_names, false, true)

func on_import_button_pressed() -> void:
	var file_dialog: FileDialog = WindowManager.create_file_dialog_window(
		get_window(),
		FileDialog.FILE_MODE_OPEN_FILES,
		MediaServer.MEDIA_EXTENSIONS
	)
	file_dialog.files_selected.connect(on_file_dialog_files_selected)
	file_dialog.popup_file_dialog()

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
	
	MediaCache.update_videos_cache_max_cache_size()

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

func _on_project_server_project_opened(project_res: ProjectRes) -> void:
	super(project_res)
	await get_tree().process_frame
	project_file_system = ProjectServer2.import_file_system
	global_file_system = GlobalServer.import_file_system
	display_file_system = project_file_system
	update()



class ImportCard extends CreatedBox.CreatedCard:
	
	@export var type: MediaServer.MediaTypes
	
	static func get_imported_res_from_type(type: int, path: String) -> MediaClipRes:
		var clip_res: MediaClipRes
		match type:
			0:
				clip_res = ImageClipRes.new()
				clip_res.image = path
				clip_res.length = EditorServer.editor_settings.edit.default_clip_duration_frame
			1:
				clip_res = VideoClipRes.new()
				clip_res.video = path
				clip_res.length = MediaCache.get_video_info(path).duration * ProjectServer2.fps
			2:
				clip_res = AudioClipRes.new()
				clip_res.stream = path
				clip_res.length = MediaCache.get_audio_data(path).get_length() * ProjectServer2.fps
		return clip_res
	
	func get_media_ress() -> Array[MediaClipRes]:
		return [get_imported_res_from_type(type, path_or_name)]
	
	func _get_context_menu_options() -> Array[Dictionary]:
		return [
			{text = "Copy path"},
			{text = "Delete"},
			{text = "Move to"},
			{text = "Replace"},
			{text = "", as_separator = true},
			{text = "Open in external program"},
			{text = "Show in file manager"}
		] as Array[Dictionary]
	
	func popup_replace_paths_window() -> void:
		media_box.replace_selected()
	
	func _on_context_menu_id_pressed(id: int) -> void:
		match id:
			0: copy_path()
			1: delete()
			2: popup_move_to_window()
			3: popup_replace_paths_window()
			5: open_in_external_program()
			6: show_in_file_manager()



