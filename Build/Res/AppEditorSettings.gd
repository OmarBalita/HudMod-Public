class_name AppEditorSettings extends UsableRes

enum TimeViewMode {
	TIME_VIEW_FRAME,
	TIME_VIEW_TIME_CODE
}

@export_group("General")
@export var is_replay: bool

@export_group("TimeLine")
@export var timeline_frame_mode: TimeViewMode = 1

@export_group("Layers")
@export var layer_color: Color = Color.GRAY
@export_range(35, 200, 5) var layer_size: int = 45

@export_group("Media Clips")
@export var clip_default_length: float = 5.0 # as seconds

func _init() -> void:
	set_res_id(&"EditorSettings")
