extends Node

# Signals
# ---------------------------------------------------

signal frame_changed(new_frame: int)

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

var frame: int:
	set(val):
		if frame != val:
			frame = val
			frame_changed.emit(val)

var message_history: Array[Dictionary]

# RealTime Nodes
# ---------------------------------------------------

var main: Control

var player: Player
var time_line: TimeLine
var media_explorer: MediaExplorer
var properties: Properties2
var color_correction_editor: ColorCorrectionEditor
var color_scope_editor: ColorScopeEditor

var drawable_rect: DrawableRect
var global_controls: Dictionary[Window, Control]

var usable_ress_controllers: Dictionary[UsableRes, Dictionary]

var media_clips_focused: Array[MediaClip]
var graph_editors_focused: Array[CurveController]
var roll_buttons_spawned: Array[Button]

# Background Called Functions
# ---------------------------------------------------

func _ready_editor_server(editors: Dictionary[StringName, EditorControl]) -> void:
	DirAccess.make_dir_absolute(app_data_dir)
	
	main = get_tree().get_current_scene()
	
	player = editors.player
	time_line = editors.time_line
	media_explorer = editors.media_explorer
	properties = editors.properties
	color_correction_editor = editors.color_correction
	color_scope_editor = editors.color_scope
	
	drawable_rect = get_tree().get_first_node_in_group("drawable_rect")
	
	player._ready_editor()
	time_line._ready_editor()
	media_explorer._ready_editor()
	properties._ready_editor()
	color_correction_editor._ready_editor()
	color_scope_editor._ready_editor()
	
	get_window().files_dropped.connect(on_files_dropped)


# Frame Get Set
# ---------------------------------------------------

func get_frame() -> int:
	return frame

func set_frame(new_frame: int) -> void:
	frame = new_frame

# Controllers Handling
# ---------------------------------------------------

func set_usable_res_controllers(usable_res: UsableRes, usable_ress: Array[UsableRes], edit_box_container: IS.EditBoxContainer, properties_containers: Dictionary[StringName, IS.EditBoxContainer]) -> void:
	usable_ress_controllers[usable_res] = {
		&"usable_ress": usable_ress,
		&"edit_box_container": edit_box_container,
		&"properties_boxes_containers": properties_containers
	}

func clear_usable_res_controllers(usable_res: UsableRes) -> void:
	usable_ress_controllers.erase(usable_res)

func get_usable_res_property_controller(usable_res: UsableRes, property_key: StringName) -> IS.EditBoxContainer:
	if usable_ress_controllers.has(usable_res):
		var curr_properties_containers: Dictionary = usable_ress_controllers[usable_res].properties_boxes_containers
		var property_container: IS.EditBoxContainer = curr_properties_containers[property_key]
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

# Media Clips
# ---------------------------------------------------

func is_timeline_selection_enabled() -> bool:
	return media_clips_focused.is_empty() and\
	graph_editors_focused.is_empty() and\
	roll_buttons_spawned.is_empty()

func is_media_clip_selection_enabled() -> bool:
	return graph_editors_focused.is_empty() and\
	roll_buttons_spawned.is_empty()

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
			id = ProjectServer.generate_new_id(used_ids, 12)
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

func save_presets(presets: Array[MediaClipRes], global: bool = false) -> PackedStringArray:
	var target_path: String = get_presets_path(global)
	make_dir_abs(target_path)
	var used_ids: PackedStringArray = DirAccess.get_files_at(target_path)
	var save_pathes: PackedStringArray
	for preset_media_res: MediaClipRes in presets:
		var id: String = ProjectServer.generate_new_id(used_ids, 12)
		var save_path: String = str(target_path, id, ".res")
		ResourceSaver.save(preset_media_res, save_path, ResourceSaver.FLAG_COMPRESS)
		used_ids.append(id)
		save_pathes.append(save_path)
	return save_pathes

func get_presets_path(global: bool) -> String:
	return GlobalServer.global_preset_path if global else ProjectServer.project_preset_path

func get_ids_from_pathes(pathes: PackedStringArray) -> PackedStringArray:
	var used_ids: PackedStringArray
	for path: String in pathes:
		used_ids.append(path.get_file().split(".")[0])
	return used_ids

# Connections
# ---------------------------------------------------

func on_files_dropped(files_pathes: Array[String]) -> void:
	
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var target_layer: Layer = time_line.get_layer_by_pos(mouse_pos)
	var target_layer_index: int = target_layer.index if target_layer else -1
	var target_frame_index: int = time_line.get_frame_from_display_pos(mouse_pos.x).keys()[0]
	
	var import_func: Callable = func(insert_media: bool = false) -> void:
		for file_path: String in files_pathes:
			media_explorer.import_media(file_path, false)
			if insert_media:
				ProjectServer.add_imported_clip(
					MediaServer.get_media_type_from_path(file_path),
					file_path, target_layer_index, target_frame_index
				)
	
	if media_explorer.get_global_rect().has_point(mouse_pos):
		import_func.call()
	elif time_line.get_global_rect().has_point(mouse_pos):
		import_func.call(true)
	else:
		return
	
	media_explorer.update()
	ProjectServer.emit_media_clips_change()







