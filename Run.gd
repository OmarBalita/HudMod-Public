extends Control

@onready var name_label: Label = %NameLabel
@onready var loading_bar: ProgressBar = %LoadingBar

@export var main_path: StringName
@export var delay: float = 1.0

var progress: Array

func _ready() -> void:
	#await get_tree().create_timer(.5).timeout
	#var image: Image = get_window().get_texture().get_image()
	#image.save_png("res://Asset/Images/run_image.png")
	await get_tree().create_timer(delay).timeout
	ResourceLoader.load_threaded_request(main_path)

func _process(delta: float) -> void:
	var load_status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(main_path, progress)
	loading_bar.value = floor(progress[0] * 100.0)
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed_scene: PackedScene = ResourceLoader.load_threaded_get(main_path)
		get_tree().change_scene_to_packed(packed_scene)


