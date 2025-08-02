extends DoubleClickControl

@onready var tweener: TweenerComponent = %TweenerComponent

@onready var display_texture_rect: TextureRect = %DisplayTextureRect
@onready var info_panel: Panel = %InfoPanel
@onready var add_button: TextureButton = %AddButton
@onready var display_name_label: Label = %DisplayNameLabel

@export var is_folder: bool
@export var resource_path: String
@export var date: float

var display_name: String



func _init() -> void:
	draw_select = true
	
	selectable = true
	draggable = true

func _ready() -> void:
	super()
	
	# Setup
	selection_group = EditorServer.media_cards_selection_group
	display_name_label.text = display_name
	
	# Connections
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)
	add_button.pressed.connect(on_add_button_pressed)
	drag_finished.connect(on_drag_finished)

func _input(event: InputEvent) -> void:
	super(event)
	
	if is_focus:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				if event.is_pressed(): press_pos = event.position
				elif press_pos.distance_to(event.position) <= min_drag_distance:
					popup_menu()




func display_at(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	var media_type = MediaServer.get_media_type_from_path(resource_path)
	var texture: ImageTexture
	
	match media_type:
		0: texture = MediaServer.get_image_texture_from_path(resource_path)
		1: texture = MediaServer.get_video_display_texture_from_path(resource_path, ProjectServer.thumbnails_path)
		2: texture = MediaServer.get_audio_display_texture_from_path(resource_path, ProjectServer.thumbnails_path, "e6e6e6")
	
	display_texture_rect.texture = texture

func popup_menu() -> void:
	var menu = InterfaceServer.create_popuped_menu([MenuOption.new("Delete")])
	menu.menu_button_pressed.connect(on_menu_button_pressed)
	get_tree().get_current_scene().add_child(menu)
	menu.popup()

func get_path_or_name() -> String:
	return display_name if is_folder else resource_path



func on_mouse_entered() -> void:
	if is_folder: return
	add_button.show()
	tweener.play(add_button, "modulate:a", [1.0], [.2])

func on_mouse_exited() -> void:
	if is_folder: return
	tweener.play(add_button, "modulate:a", [.0], [.2])
	var tween = tweener.tween
	await tweener.finished
	if tween != tweener.tween: return
	add_button.hide()

func on_add_button_pressed() -> void:
	if not is_folder:
		ProjectServer.add_media_clip(resource_path, -1, EditorServer.time_line.curr_frame)

func on_drag_finished() -> void:
	
	var timeline = EditorServer.time_line
	var mouse_pos = get_global_mouse_position()
	var target_frame = timeline.get_frame_from_display_pos(mouse_pos.x).keys()[0]
	
	if not timeline.is_focus:
		return
	
	var layer = timeline.get_layer_by_pos(mouse_pos)
	if layer:
		var selected_cards = selection_group.selected_objects
		for key in selected_cards:
			var media_card = selected_cards[key].object
			var resource_path = media_card.resource_path
			ProjectServer.add_media_clip(resource_path, layer.index, target_frame)


func on_menu_button_pressed(index: int) -> void:
	match index:
		0:
			var pathes_or_names: Array
			var selected_objects = EditorServer.media_cards_selection_group.selected_objects
			for key in selected_objects.keys():
				var card = selected_objects.get(key).object
				if not is_instance_valid(card):
					continue
				pathes_or_names.append(card.get_path_or_name())
			EditorServer.media_explorer.delete_files_or_folders(pathes_or_names if pathes_or_names.size() else [get_path_or_name()])











