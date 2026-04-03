class_name AppEditorSettings extends UsableRes

signal settings_updated()

enum TimeViewMode {
	TIME_VIEW_FRAME,
	TIME_VIEW_TIME_CODE
}

enum Quality {
	RENDER_QUALITY_25 = 25,
	RENDER_QUALITY_50 = 50,
	RENDER_QUALITY_75 = 75,
	RENDER_QUALITY_100 = 100,
}

@export_group("Work Flow")
@export var media_clip_default_length: float = 5.

@export_group("Viewport Playback")
@export var viewport_effect_quality: Quality = Quality.RENDER_QUALITY_50
@export var video_max_frame_cache: int = 100
@export var video_scale_factor: float = 1.

@export_group("Editor Startup")
@export var timeline_frame_mode: TimeViewMode = 1

@export_group("Theme")
@export_subgroup("Media Explorer", "media_explorer")
@export var media_explorer_waveform_color_a: Color = Color(0.273, 0.463, 1.0, 1.0)
@export var media_explorer_waveform_color_b: Color = Color(0.0, 0.589, 0.872, 1.0)
@export_subgroup("TimeLine", "timeline")
@export_subgroup("Player", "player")
@export var is_replay: bool = true


var media_clip_default_length_f: int
var project_min_length_f: int

var viewport_effect_ratio: float

var media_explorer_waveform_gradient: Gradient


func _init() -> void:
	update_settings()

func update_settings() -> void:
	viewport_effect_ratio = viewport_effect_quality / 100.
	
	media_explorer_waveform_gradient = Gradient.new()
	media_explorer_waveform_gradient.add_point(.0, media_explorer_waveform_color_a)
	media_explorer_waveform_gradient.add_point(.999, media_explorer_waveform_color_b)
	
	settings_updated.emit()

func update_settings_base_on_project() -> void:
	media_clip_default_length_f = media_clip_default_length * ProjectServer2.fps



