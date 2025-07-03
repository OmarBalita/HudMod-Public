extends DoubleClickControl


@onready var tweener: TweenerComponent = %TweenerComponent

@onready var display_texture_rect: TextureRect = %DisplayTextureRect
@onready var info_panel: Panel = %InfoPanel
@onready var add_button: TextureButton = %AddButton
@onready var display_name_label: Label = %DisplayNameLabel



@export var is_folder: bool
@export var resource_path: String
@export var preset: PresetResource

var display_name: String


func _ready() -> void:
	super()
	
	display_name_label.text = display_name
	
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)
	add_button.pressed.connect(on_add_button_pressed)







func display_at(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	var extension = resource_path.get_file().get_extension()
	var texture: ImageTexture
	if extension in MediaServer.IMAGE_EXTENSIONS:
		texture = MediaServer.get_image_texture_from_path(resource_path)
	elif extension in MediaServer.VIDEO_EXTENSIONS:
		texture = MediaServer.get_video_display_texture_from_path(resource_path, ProjectServer.thumbnails_path)
	elif extension in MediaServer.AUDIO_EXTENSIONS:
		texture = MediaServer.get_audio_display_texture_from_path(resource_path, ProjectServer.thumbnails_path)
	display_texture_rect.texture = texture









func on_mouse_entered() -> void:
	add_button.show()
	tweener.play(add_button, "modulate:a", [1.0], [.2])

func on_mouse_exited() -> void:
	tweener.play(add_button, "modulate:a", [.0], [.2])
	var tween = tweener.tween
	await tweener.finished
	if tween != tweener.tween: return
	add_button.hide()

func on_add_button_pressed() -> void:
	pass

















