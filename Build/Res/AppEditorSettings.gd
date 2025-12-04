class_name AppEditorSettings extends UsableRes

enum TimeViewMode {
	TIME_VIEW_FRAME,
	TIME_VIEW_TIME_CODE
}

@export_group("General")
@export var is_replay: bool
@export var media_clip_default_length: float = 5.0 # as seconds
@export_subgroup("Scene Viewer")
var update_video_viewers_on_drag: bool = false
var update_video_viewers_rate: float = .5

@export_group("Theme")
@export_subgroup("Media Explorer", "media_explorer")
@export var media_explorer_waveform_color_a: Color = Color(0.4, 0.6, 1.0)
@export var media_explorer_waveform_color_b: Color = Color(0.611, 0.527, 1.0)
@export var media_explorer_waveform_gradient: Gradient
@export_subgroup("TimeLine", "timeline")
@export var timeline_frame_mode: TimeViewMode = 1
@export_subgroup("Layers", "layer")
@export var layer_color: Color = Color.GRAY
@export_range(35, 200, 5) var layer_size: int = 45
@export_subgroup("Media Clips", "media_clip")
@export var media_clip_waveform_low_color: Color = Color(Color.LIGHT_GRAY, .5)
@export var media_clip_waveform_medium_color: Color = Color(Color.GOLDENROD, .5)
@export var media_clip_waveform_high_color: Color = Color(Color.CRIMSON, .5)

func _init() -> void:
	set_res_id(&"EditorSettings")
	_setup_test_editor_settings()

func _setup_test_editor_settings() -> void:
	media_explorer_waveform_gradient = Gradient.new()
	media_explorer_waveform_gradient.add_point(.0, media_explorer_waveform_color_a)
	media_explorer_waveform_gradient.add_point(.999, media_explorer_waveform_color_b)









