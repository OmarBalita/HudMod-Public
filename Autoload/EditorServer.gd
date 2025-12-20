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

# Save Info
# ---------------------------------------------------

var app_data_dir = OS.get_data_dir() + "/Edit App"
var editor_path = app_data_dir + "/editor/"

# Resources
# ---------------------------------------------------

var editor_settings:= AppEditorSettings.new()

var import_media_cards_selection_group:= SelectionGroupRes.new()
var object_media_cards_selection_group:= SelectionGroupRes.new()
var media_clips_selection_group:= SelectionGroupRes.new()
var time_markers_selection_group:= SelectionGroupRes.new()

# RealTime Variables
# ---------------------------------------------------

var frame: int:
	set(val): frame = val; frame_changed.emit(val)

var message_history: Array[Dictionary]

# RealTime Nodes
# ---------------------------------------------------

var player: Player
var time_line: TimeLine
var media_explorer: MediaExplorer
var clip_nodes_explorer: ClipNodesExplorer
var properties: Properties2
var drawable_rect: DrawableRect

var usable_ress_controllers: Dictionary[UsableRes, Dictionary]

var media_clips_focused: Array[MediaClip]
var roll_buttons_spawned: Array[Button]

# Background Called Functions
# ---------------------------------------------------

func _ready_editor_server() -> void:
	DirAccess.make_dir_absolute(app_data_dir)
	DirAccess.make_dir_absolute(editor_path)
	
	player = get_tree().get_first_node_in_group("player")
	time_line = get_tree().get_first_node_in_group("time_line")
	media_explorer = get_tree().get_first_node_in_group("media_explorer")
	clip_nodes_explorer = get_tree().get_first_node_in_group("clip_nodes_explorer")
	properties = get_tree().get_first_node_in_group("properties")
	drawable_rect = get_tree().get_first_node_in_group("drawable_rect")
	
	player._ready_editor()
	time_line._ready_editor()
	media_explorer._ready_editor()
	clip_nodes_explorer._ready_editor()
	properties._ready_editor()
	
	get_window().files_dropped.connect(on_files_dropped)
	
	push_guides()



# Frame
# ---------------------------------------------------

func get_frame() -> int:
	return frame

func set_frame(new_frame: int) -> void:
	frame = new_frame

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

func is_any_media_clip_focused() -> bool:
	return media_clips_focused.size() > 0

# Guides Functions
# ---------------------------------------------------

func push_guides(guides: Array[Dictionary] = []) -> void:
	if not guides:
		guides = [
			{"": "Lazy-Edit is a very simple and lightweight video editing program."}
		]
	var result_guide: String
	var guide_labels = get_tree().get_nodes_in_group("guide_label")
	for index in guides.size():
		var guide = guides[index]
		var guide_key = guide.keys()[0]
		var guide_val = guide.values()[0]
		if index:
			result_guide += "   |   "
		if guide_key:
			result_guide += str(guide_key, " : ")
		result_guide += guide_val
	set_labels_text(guide_labels, result_guide, 0)

func push_notification(message: String, error_strength: int = 0) -> void:
	var notification_labels = get_tree().get_nodes_in_group("notification_label")
	message_history.append({
		"message": message,
		"error_strength": error_strength
	})
	set_labels_text(notification_labels, message, error_strength)


func set_labels_text(labels: Array, text: String, color_index: int, while_loop = null) -> void:
	for label: Label in labels:
		if label is NotificationLabel:
			label.set_notification_text(text)
		else:
			label.set_text(text)
		label.add_theme_color_override("font_color", ERR_STRENGTH_COLORS[color_index])
		if while_loop:
			while_loop.call(label)


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








