class_name AppEditorSettings extends UsableRes

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

@export_group("General")
@export var is_replay: bool
@export var media_clip_default_length: float = 5. # as seconds
@export_subgroup("Scene Viewer")
var update_video_viewers_on_drag: bool = false
var update_video_viewers_rate: float = .5

@export_group("Viewport", "viewport")
@export var viewport_resolution_scale: Quality = Quality.RENDER_QUALITY_75
@export var viewport_effect_quality: Quality = Quality.RENDER_QUALITY_50
@export var viewport_effect_max_resolution: Vector2i = Vector2i(2048, 2048)

@export_group("Render", "render")
@export var render_effect_quality: Quality = Quality.RENDER_QUALITY_100
@export var render_effect_max_resolution: Vector2i = Vector2i(8192, 8192)

@export_group("Theme")
@export_subgroup("Media Explorer", "media_explorer")
@export var media_explorer_waveform_color_a: Color = Color(.33, .53, 1., 1.)
@export var media_explorer_waveform_color_b: Color = Color(.0, .82, .84, 1.)
@export_subgroup("TimeLine", "timeline")
@export var timeline_frame_mode: TimeViewMode = 1
@export_subgroup("Layers", "layer")
@export var layer_color: Color = Color.GRAY
@export_range(35, 200, 5) var layer_size: int = 45
@export_subgroup("Media Clips", "media_clip")
@export var media_clip_waveform_low_color: Color = Color(Color.LIGHT_GRAY, .5)
@export var media_clip_waveform_medium_color: Color = Color(Color.GOLDENROD, .5)
@export var media_clip_waveform_high_color: Color = Color(Color.CRIMSON, .5)

var viewport_resolution_ratio: float
var viewport_effect_ratio: float
var render_effect_ratio: float

var media_explorer_waveform_gradient: Gradient

func _init() -> void:
	update_app_editor_settings()

func update_app_editor_settings() -> void:
	viewport_resolution_ratio = viewport_resolution_scale / 100.
	viewport_effect_ratio = viewport_effect_quality / 100.
	render_effect_ratio = render_effect_quality / 100.
	
	media_explorer_waveform_gradient = Gradient.new()
	media_explorer_waveform_gradient.add_point(.0, media_explorer_waveform_color_a)
	media_explorer_waveform_gradient.add_point(.999, media_explorer_waveform_color_b)

