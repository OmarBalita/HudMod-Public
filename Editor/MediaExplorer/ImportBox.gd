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

var latest_success_pathes: PackedStringArray

func _ready_options() -> void:
	super()
	
	import_category = add_category("Import", false)
	
	import_button = IS.create_button("", media_explorer.texture_file, "Import", true)
	import_button.pressed.connect(on_import_button_pressed)
	options_container.add_child(import_button)

func _init_card(key: String, info: Dictionary) -> CreatedCard:
	var media_type: int = info.import_t
	var import_card:= ImportCard.new(self, 0)
	
	import_card.display_name = key.get_file()
	import_card.display_texture = MediaServer.get_thumbnail(key).texture
	import_card.created_card_type = CreatedCard.CreatedCardType.CARD_TYPE_PRESET
	import_card.type = media_type
	import_card.path_or_name = key
	import_card.disabled = info.has(&"discard")
	
	return import_card

func replace_selected() -> void:
	var paths_or_names: PackedStringArray = get_selected_pathes_or_names(true, false)
	EditorServer.popup_replace_paths(paths_or_names, false, true)

func on_import_button_pressed() -> void:
	var file_dialog: FileDialog = WindowManager.create_file_dialog_window(
		get_window(),
		FileDialog.FILE_MODE_OPEN_FILES,
		MediaServer.MEDIA_EXTENSIONS
	)
	file_dialog.files_selected.connect(on_file_dialog_files_selected)
	file_dialog.popup_file_dialog()

func on_file_dialog_files_selected(pathes: PackedStringArray) -> void:
	load_files(pathes)

func load_files(pathes: PackedStringArray) -> void:
	var window_margin: MarginContainer = WindowManager.popup_window(get_window(), Vector2i(600, 400), "Load files")
	var box_container: BoxContainer = IS.create_box_container(12, true)
	
	window_margin.get_window().borderless = true
	
	progress_window = window_margin.get_window()
	progress_list = ItemList.new()
	progress_bar = IS.create_progress_bar(.0, .0, 100., .01)
	
	box_container.add_child(progress_list)
	box_container.add_child(progress_bar)
	window_margin.add_child(box_container)
	
	IS.set_base_settings(progress_list)
	IS.expand(progress_list, true, true)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var display_path: Array = curr_display_path.duplicate()
	latest_success_pathes = PackedStringArray()
	var success_pathes: PackedStringArray = latest_success_pathes
	
	_create_files(file_system, display_path, pathes, _worker_thread_create_files)
	
	ProjectServer2.commit_action(
		"load_files",
		_create_files.bind(file_system, display_path, success_pathes, _main_thread_create_files),
		delete_files_or_folders.bind(file_system, display_path, success_pathes, false),
		false
	)


func _create_files(file_sys: FileSystem, display_path: Array, pathes: PackedStringArray, method_create_files: Callable) -> void:
	var pathes_size: int = pathes.size()
	const GROUP_SIZE: int = 4
	for start_idx: int in range(0, pathes_size, GROUP_SIZE):
		var curr_group_size: int = mini(GROUP_SIZE, pathes_size - start_idx)
		await method_create_files.call(start_idx, curr_group_size, file_sys, display_path, pathes)
		await get_tree().process_frame
	update()
	if progress_window:
		progress_window.queue_free()

func _worker_thread_create_files(start_idx: int, group_size: int, file_sys: FileSystem, display_path: Array, pathes: PackedStringArray) -> void:
	var group_task_id: int = WorkerThreadPool.add_group_task(_create_file.bind(start_idx, file_sys, display_path, pathes), group_size, -1, true)
	WorkerThreadPool.wait_for_group_task_completion(group_task_id)

func _main_thread_create_files(start_idx: int, group_size: int, file_sys: FileSystem, display_path: Array, pathes: PackedStringArray) -> void:
	for idx: int in range(start_idx, start_idx + group_size):
		create_files(file_sys, display_path, [pathes[idx]])

func _create_file(idx: int, start_idx: int, file_sys: FileSystem, display_path: Array, pathes: PackedStringArray) -> void:
	idx += start_idx
	var path: String = pathes[idx]
	_report_start.call_deferred(idx, path)
	var load_err: MediaCache.LOAD_ERR = create_files(file_sys, display_path, [path])[0]
	var success: bool = load_err == MediaCache.LOAD_ERR.SUCCESS
	if success: latest_success_pathes.append(path)
	_report_progress.call_deferred(idx, pathes, success)

func _report_start(index: int, path: String) -> void:
	progress_list.add_item(path, texture_wait)

func _report_progress(index: int, pathes: PackedStringArray, load_success: bool) -> void:
	progress_list.set_item_custom_bg_color(index, Color(Color.GREEN_YELLOW, .1))
	progress_list.set_item_text(index, pathes[index])
	if load_success:
		progress_list.set_item_icon(index, texture_check)
	else:
		progress_list.set_item_icon(index, texture_x_mark)
		pathes[index] = ""
	
	progress_bar.value += 100. / pathes.size()
	
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
	file_system = project_file_system
	update()



class ImportCard extends CreatedBox.CreatedCard:
	
	@export var type: MediaServer.MediaType
	
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
				clip_res.length = MediaCache.get_video_context(path).duration * ProjectServer2.fps
			2:
				clip_res = AudioClipRes.new()
				clip_res.stream = path
				clip_res.length = MediaCache.get_audio_data(path).get_length() * ProjectServer2.fps
		clip_res._init_clip_res()
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



