extends Node

# Constants
# ---------------------------------------------------

const ERR_STRENGTH_COLORS:= [
	Color.WEB_GRAY,
	Color.PALE_GOLDENROD,
	Color.INDIAN_RED
]

# Directory Info
# ---------------------------------------------------

static var app_data_dir: String = OS.get_data_dir() + "/HudMod Video Editor/"

static var editor_path: String = app_data_dir + "editor/"
static var editor_layout_path: String = editor_path + "layout/"

# Resources
# ---------------------------------------------------

var editor_settings:= AppEditorSettings.new()

var media_clips_selection_group:= SelectionGroupRes.new()
var time_markers_selection_group:= SelectionGroupRes.new()

# RealTime Variables
# ---------------------------------------------------

var message_history: Array[Dictionary]

# RealTime Nodes
# ---------------------------------------------------

var main: Control

var player: Player
var time_line2: TimeLine2
var media_explorer: MediaExplorer
var properties: Properties2
var color_correction_editor: ColorCorrectionEditor
var color_scope_editor: ColorScopeEditor

var drawable_rect: DrawableRect
var global_controls: Dictionary[Window, Control]

var usable_ress_controllers: Dictionary[UsableRes, Dictionary]

var graph_editors_focused: Array[CurveController]
var roll_buttons_spawned: Array[Button]

# Background Called Functions
# ---------------------------------------------------

func _ready_editor_server(editors: Dictionary[StringName, EditorControl]) -> void:
	DirAccess.make_dir_absolute(app_data_dir)
	
	main = get_tree().get_current_scene()
	
	player = editors.player
	media_explorer = editors.media_explorer
	properties = editors.properties
	color_correction_editor = editors.color_correction
	color_scope_editor = editors.color_scope
	time_line2 = editors.time_line2
	
	MediaServer.ClipPanel.timeline = time_line2
	Layer2.timeline = time_line2
	
	drawable_rect = get_tree().get_first_node_in_group("drawable_rect")
	
	for editor_name: StringName in editors:
		editors[editor_name]._ready_editor()
	
	var window: Window = get_window()
	window.focus_entered.connect(on_window_focus_entered)
	window.files_dropped.connect(on_window_files_dropped)
	
	scan_media_existent()


# ---------------------------------------------------

func layers_body_shortcut_node_cond_func() -> bool:
	return graph_editors_focused.is_empty()

# Controllers Handling
# ---------------------------------------------------

func set_usable_res_controllers(usable_res: UsableRes, usable_ress: Array[UsableRes], edit_box_container: IS.EditBoxContainer, properties_containers: Dictionary[StringName, Control], ui_profile: UIProfile) -> void:
	usable_ress_controllers[usable_res] = {
		&"usable_ress": usable_ress,
		&"edit_box_container": edit_box_container,
		&"properties_boxes_containers": properties_containers,
		&"ui_profile": ui_profile
	}

func has_usable_res_controllers(usable_res: UsableRes) -> bool:
	if usable_ress_controllers.has(usable_res):
		if usable_ress_controllers[usable_res].edit_box_container:
			return true
		usable_ress_controllers.erase(usable_res)
	return false

func clear_usable_res_controllers(usable_res: UsableRes) -> void:
	usable_ress_controllers.erase(usable_res)

func get_usable_res_shared_ress(usable_res: UsableRes) -> Array[UsableRes]:
	return usable_ress_controllers[usable_res].usable_ress

func get_usable_res_main_edit(usable_res: UsableRes) -> IS.EditBoxContainer:
	return usable_ress_controllers[usable_res].edit_box_container

func get_usable_res_controllers(usable_res: UsableRes) -> Dictionary[StringName, Control]:
	return usable_ress_controllers[usable_res].properties_boxes_containers

func get_usable_res_ui_profile(usable_res: UsableRes) -> UIProfile:
	return usable_ress_controllers[usable_res].ui_profile

func update_usable_res_ui_profile(usable_res: UsableRes) -> void:
	get_usable_res_ui_profile(usable_res).update()

func get_usable_res_property_controller(usable_res: UsableRes, property_key: StringName) -> Control:
	if usable_ress_controllers.has(usable_res):
		var curr_properties_containers: Dictionary = usable_ress_controllers[usable_res].properties_boxes_containers
		var property_container: Variant = curr_properties_containers[property_key]
		if not is_instance_valid(property_container):
			return null
		return property_container
	return null

func update_usable_res_property_controller(usable_res: UsableRes, property_key: StringName, new_val: Variant, has_keyframe: bool) -> void:
	var property_container:= get_usable_res_property_controller(usable_res, property_key)
	if property_container:
		property_container.set_controller_val_manually(new_val)
		property_container.set_keyframe_method(int(has_keyframe))

func set_usable_res_property_controller_keyframe_method(usable_res: UsableRes, property_key: StringName, has_keyframe: bool) -> void:
	var property_container:= get_usable_res_property_controller(usable_res, property_key)
	if property_container: property_container.set_keyframe_method(int(has_keyframe))


# Directories: Save Load Handling
# ---------------------------------------------------

func make_dir_abs(path: String) -> Error:
	return DirAccess.make_dir_recursive_absolute(path)

func make_dirs_abs(paths: PackedStringArray) -> Array[Error]:
	var errors: Array[Error]
	for path: String in paths:
		errors.append(DirAccess.make_dir_recursive_absolute(path))
	return errors

func remove_abs(path: String) -> Error:
	return DirAccess.remove_absolute(path)

func load_custom_layouts() -> Array[LayoutRootInfo]:
	make_dir_abs(editor_layout_path)
	
	var result: Array[LayoutRootInfo]
	for file_name: StringName in DirAccess.get_files_at(editor_layout_path):
		var layout: LayoutRootInfo = ResourceLoader.load(editor_layout_path + file_name)
		layout.set_meta(&"id", file_name.get_file().trim_suffix(&".res"))
		result.append(layout)
	return result

func save_custom_layouts(custom_layouts: Array[LayoutRootInfo], clear_old: bool = false, generate_ids: bool = true) -> void:
	make_dir_abs(editor_layout_path)
	
	var used_ids: PackedStringArray
	if clear_old: clear_custom_layouts()
	else: used_ids = DirAccess.get_files_at(editor_layout_path)
	
	for layout: LayoutRootInfo in custom_layouts:
		var id: String
		if generate_ids:
			id = StringHelper.generate_new_id(used_ids, 12)
		else:
			id = layout.get_meta(&"id")
		ResourceSaver.save(layout, str(editor_layout_path, id, ".res"), ResourceSaver.FLAG_COMPRESS)
		layout.set_meta(&"id", id)
		used_ids.append(id)

func remove_custom_layouts(custom_layouts: Array[LayoutRootInfo]) -> void:
	for layout: LayoutRootInfo in custom_layouts:
		var file_name: String = layout.get_meta(&"id") + ".res"
		remove_abs(editor_layout_path + file_name)

func clear_custom_layouts() -> void:
	for file_name: StringName in DirAccess.get_files_at(editor_layout_path):
		remove_abs(editor_layout_path + file_name)

func load_presets(global: bool = false) -> Array[MediaClipRes]:
	var target_dir: String = get_presets_path(global)
	make_dir_abs(target_dir)
	var result: Array[MediaClipRes]
	for file_name: StringName in DirAccess.get_files_at(target_dir):
		var media_res: Resource = ResourceLoader.load(editor_layout_path + file_name)
		if media_res is MediaClipRes:
			result.append(media_res)
	return result

func create_presets(presets: Array[MediaClipRes], global: bool = false) -> PackedStringArray:
	var target_path: String = get_presets_path(global)
	make_dir_abs(target_path)
	var used_ids: PackedStringArray = DirAccess.get_files_at(target_path)
	var save_pathes: PackedStringArray
	for preset_media_res: MediaClipRes in presets:
		var id: String = StringHelper.generate_new_id(used_ids, 12)
		var save_path: String = str(target_path, id, ".res")
		MediaServer.store_not_saved_resource(save_path, preset_media_res)
		used_ids.append(id)
		save_pathes.append(save_path)
	return save_pathes

func get_presets_path(global: bool) -> String:
	return GlobalServer.global_preset_path if global else ProjectServer2.project_preset_path

func get_media_path(global: bool) -> String:
	return GlobalServer.global_media_path if global else ProjectServer2.project_media_path

func get_ids_from_pathes(pathes: PackedStringArray) -> PackedStringArray:
	var used_ids: PackedStringArray
	for path: String in pathes:
		used_ids.append(path.get_file().split(".")[0])
	return used_ids

func save() -> void:
	ProjectServer2.save_project()
	GlobalServer.save_global()
	MediaServer.save_not_saved_yet()
	MediaServer.delete_not_deleted_yet()

func scan_media_existent() -> void:
	var project_imp_sys:= ProjectServer2.import_file_system
	var project_pres_sys:= ProjectServer2.preset_file_system
	var global_imp_sys:= GlobalServer.import_file_system
	var global_pres_sys:= GlobalServer.preset_file_system
	
	project_imp_sys.check_for_discard_paths()
	global_imp_sys.check_for_discard_paths()
	
	var project_import_paths: PackedStringArray = project_imp_sys.get_files_paths()
	var project_preset_paths: PackedStringArray = project_pres_sys.get_files_paths()
	
	var global_import_paths: PackedStringArray = global_imp_sys.get_files_paths()
	var global_preset_paths: PackedStringArray = global_pres_sys.get_files_paths()
	
	var all_import_paths: PackedStringArray = project_import_paths + global_import_paths
	var all_preset_paths: PackedStringArray = project_preset_paths + global_preset_paths
	
	var disk_paths_not_exists: PackedStringArray
	for import_path: String in all_import_paths:
		if not FileAccess.file_exists(import_path):
			disk_paths_not_exists.append(import_path)
	
	if disk_paths_not_exists:
		if not replace_paths_window:
			popup_replace_paths_window(disk_paths_not_exists)
		return
	elif replace_paths_window:
		replace_paths_window.queue_free()
	
	var global_paths_needed: PackedStringArray = global_pres_sys.preset_media_ress_check_for_paths(global_import_paths)
	
	media_explorer.import_box.update()
	media_explorer.preset_box.update()

func replace_paths(paths_for_replace: Dictionary[String, String], discard_option: bool) -> void:
	ProjectServer2.import_file_system.replace_paths(paths_for_replace, discard_option)
	GlobalServer.import_file_system.replace_paths(paths_for_replace, discard_option)
	format_paths(paths_for_replace)

func discard_paths(paths: PackedStringArray) -> void:
	ProjectServer2.import_file_system.discard_paths(paths)
	GlobalServer.import_file_system.discard_paths(paths)

func format_paths(paths_for_format: Dictionary[String, String]) -> void:
	#ProjectServer2.format_media_clips_paths(paths_for_format)
	ProjectServer2.preset_file_system.preset_media_ress_format_paths(paths_for_format)
	GlobalServer.preset_file_system.preset_media_ress_format_paths(paths_for_format)


func get_import_file_system(global: bool) -> DisplayFileSystemRes: return GlobalServer.import_file_system if global else ProjectServer2.import_file_system
func get_preset_file_system(global: bool) -> DisplayFileSystemRes: return GlobalServer.preset_file_system if global else ProjectServer2.preset_file_system


# Popup Windows
# ---------------------------------------------------

var replace_paths_window: Window

func popup_replace_paths_window(paths: PackedStringArray, discard_option: bool = true, custom_popup: bool = false) -> WindowManager.AcceptWindow:
	var paths_for_replace: Dictionary[String, String] = {}
	
	var window_cont: BoxContainer = WindowManager.popup_accept_window(
		get_window(),
		Vector2(900, 500),
		"Replace unexistent paths",
		replace_paths.bind(paths_for_replace, discard_option),
		func() -> void: if discard_option: discard_paths(paths)
	)
	
	var window: WindowManager.AcceptWindow = window_cont.get_window()
	window.accept_button.text = "Replace"
	window.cancel_button.text = "Discard"
	
	for path: String in paths:
		
		if paths_for_replace.has(path):
			continue
		
		var new_path: String = ""
		
		var type: int = MediaServer.get_media_type_from_path(path)
		var type_info: Dictionary = MediaServer.imported_clip_info[type]
		
		var path_edit: Control = IS.create_string_edit(path, new_path, "Choose a New path", 2, MediaServer.MEDIA_EXTENSIONS)[0]
		var edit_box: IS.EditBoxContainer = path_edit.get_parent()
		
		var icon_rect: TextureRect = IS.create_texture_rect(type_info.icon, {modulate = type_info.color, custom_minimum_size = Vector2(24., .0), stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED})
		var valid_path_rect: TextureRect = IS.create_texture_rect(null, {custom_minimum_size = Vector2(24., .0), stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED})
		
		var on_update_path_func: Callable = func(usable_res: UsableRes, key: StringName, val: Variant) -> void:
			paths_for_replace[path] = val
			
			var cond1: bool = FileAccess.file_exists(val)
			var cond2: bool = MediaServer.get_media_type_from_path(val) == type
			valid_path_rect.texture = IS.TEXTURE_CHECK if cond1 and cond2 else IS.TEXTURE_X_MARK
		
		on_update_path_func.call(null, &"", new_path)
		
		edit_box.header.add_child(icon_rect)
		edit_box.header.add_child(valid_path_rect)
		edit_box.val_changed.connect(on_update_path_func)
		
		window_cont.add_child(edit_box)
		
		paths_for_replace[path] = new_path
	
	if not custom_popup:
		replace_paths_window = window
	
	return window


# Connections
# ---------------------------------------------------

func on_window_focus_entered() -> void:
	scan_media_existent()

func on_window_files_dropped(files_pathes: Array[String]) -> void:
	#var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	#var target_layer: Layer = time_line.get_layer_by_pos(mouse_pos)
	#var target_layer_index: int = target_layer.index if target_layer else -1
	#var target_frame_index: int = time_line.get_frame_from_display_pos(mouse_pos.x).keys()[0]
	#
	#var import_func: Callable = func(insert_media: bool = false) -> void:
		#for file_path: String in files_pathes:
			#media_explorer.import_media(file_path, false)
			#if insert_media:
				#ProjectServer.add_imported_clip(
					#MediaServer.get_media_type_from_path(file_path),
					#file_path, target_layer_index, target_frame_index
				#)
	#
	#if media_explorer.get_global_rect().has_point(mouse_pos):
		#import_func.call()
	#elif time_line.get_global_rect().has_point(mouse_pos):
		#import_func.call(true)
	#else:
		#return
	#
	#media_explorer.update()
	#ProjectServer.emit_media_clips_change()
	pass






