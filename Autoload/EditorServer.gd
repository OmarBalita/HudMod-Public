extends Node


const ERR_STRENGTH_COLORS:= [
	Color.WEB_GRAY,
	Color.PALE_GOLDENROD,
	Color.INDIAN_RED
]


# Save Info
# ---------------------------------------------------

var app_data_dir = OS.get_data_dir() + "/Edit App"
var editor_path = app_data_dir + "/editor/"


# RealTime Variables
# ---------------------------------------------------

var media_cards_selection_group:= SelectionGroupRes.new()
var media_clips_selection_group:= SelectionGroupRes.new()
var time_markers_selection_group:= SelectionGroupRes.new()
var media_clips_focused: Array[MediaClip]

var message_history: Array[Dictionary]


# RealTime Nodes
# ---------------------------------------------------

var player: Player
var time_line: TimeLine
var media_explorer: MediaExplorer
var clip_nodes_explorer: ClipNodesExplorer
var properties: Properties

var editor_default_settings:= EditorDefaultSettings.new()



# Background Called Functions
# ---------------------------------------------------

func _ready() -> void:
	
	DirAccess.make_dir_absolute(app_data_dir)
	DirAccess.make_dir_absolute(editor_path)
	
	player = get_tree().get_first_node_in_group("player")
	time_line = get_tree().get_first_node_in_group("time_line")
	media_explorer = get_tree().get_first_node_in_group("media_explorer")
	clip_nodes_explorer = get_tree().get_first_node_in_group("clip_nodes_explorer")
	properties = get_tree().get_first_node_in_group("properties")
	
	push_guides()
	
	get_tree().get_root()
	get_tree().get_root().files_dropped.connect(on_files_dropped)


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
	
	var import_func = func(insert_media: bool = false) -> void:
		for file_path in files_pathes:
			media_explorer.import_media(file_path)
			if insert_media:
				ProjectServer.add_media_clip(file_path)
	
	var mouse_pos = get_viewport().get_mouse_position()
	for control: Control in [media_explorer, time_line]:
		if control.get_global_rect().has_point(mouse_pos):
			var groups = control.get_groups()
			if groups.has("media_explorer"):
				import_func.call()
			elif groups.has("time_line"):
				import_func.call(true)
			break










