extends DoubleClickControl

@onready var tweener: TweenerComponent = %TweenerComponent

@onready var display_texture_rect: TextureRect = %DisplayTextureRect
@onready var info_panel: Panel = %InfoPanel
@onready var add_button: TextureButton = %AddButton
@onready var display_name_label: Label = %DisplayNameLabel

enum CardTypes {
	FOLDER,
	IMPORTED_MEDIA,
	OBJECT_MEDIA,
	TRANSITION,
	PRESET
}

@export var card_type: CardTypes
@export var resource_path: String
@export var display_image: Texture2D
@export var display_name: String
@export var date: float

var object_res_id: Variant = null



func _init() -> void:
	draw_select = true
	
	selectable = true
	draggable = true

func _ready() -> void:
	super()
	
	# Setup
	display_name_label.text = display_name
	if card_type in [2, 3, 4]: display_texture_rect.texture = display_image
	
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
				if event.is_pressed():
					press_pos = event.position
				elif press_pos.distance_to(event.position) <= min_drag_distance:
					popup_menu()



func display_imported_media_at(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	var media_type = MediaServer.get_media_type_from_path(resource_path)
	var texture: ImageTexture
	
	match media_type:
		0: texture = MediaServer.get_image_texture_from_path(resource_path)
		1: texture = MediaServer.get_video_display_texture_from_path(resource_path, ProjectServer.explorer_thumbnails_path)
		2: texture = MediaServer.get_audio_display_texture_from_path(resource_path, ProjectServer.explorer_thumbnails_path, "e6e6e6")
	
	display_texture_rect.texture = texture

func popup_menu() -> void:
	var menu = IS.popup_menu([
		MenuOption.new("Delete"),
	])
	menu.menu_button_pressed.connect(on_menu_button_pressed)

func get_path_or_name() -> String:
	return display_name if not card_type else resource_path

func add_my_clip(layer: int = -1, frame: Variant = null) -> void:
	if not card_type: return
	ProjectServer.add_media_clip(resource_path, layer, EditorServer.time_line.curr_frame if frame == null else frame, get_my_object_res())

func get_my_object_res() -> Variant:
	return null if object_res_id == null else object_res_id.new()




func on_mouse_entered() -> void:
	if not card_type: return
	add_button.show()
	tweener.play(add_button, "modulate:a", [1.0], [.2])

func on_mouse_exited() -> void:
	if not card_type: return
	tweener.play(add_button, "modulate:a", [.0], [.2])
	var tween = tweener.tween
	await tweener.finished
	if tween != tweener.tween: return
	add_button.hide()


func on_clicked() -> void:
	add_my_clip()

func on_add_button_pressed() -> void:
	add_my_clip()

func on_drag_finished() -> void:
	
	var timeline: TimeLine = EditorServer.time_line
	var mouse_pos: Vector2 = get_global_mouse_position()
	var target_frame: int = timeline.get_frame_from_display_pos(mouse_pos.x).keys()[0]
	
	if not timeline.is_focus:
		return
	
	var layer: Layer = timeline.get_layer_by_pos(mouse_pos)
	if layer:
		var selected_cards: Dictionary[String, Dictionary] = selection_group.selected_objects
		for key: String in selected_cards.keys():
			var media_card: FocusControl = selected_cards[key].object
			var resource_path: String = media_card.resource_path
			ProjectServer.add_media_clip(media_card.resource_path, layer.index, target_frame, media_card.get_my_object_res())

func on_menu_button_pressed(index: int) -> void:
	match index:
		0:
			var pathes_or_names: Array
			var selected_objects = selection_group.selected_objects
			for key in selected_objects.keys():
				var card = selected_objects.get(key).object
				if not is_instance_valid(card):
					continue
				pathes_or_names.append(card.get_path_or_name())
			EditorServer.media_explorer.delete_files_or_folders(pathes_or_names if pathes_or_names.size() else [get_path_or_name()])







