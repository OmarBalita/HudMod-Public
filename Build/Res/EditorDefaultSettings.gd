class_name AppEditorSettings extends UsableRes

@export_group("Layers")
@export var layer_color: Color = Color.GRAY
@export var layer_size: int = 55

@export_group("Media Clips")
@export var clip_default_length: float = 5.0 # as seconds


func _init() -> void:
	set_res_id(&"EditorSettings")
