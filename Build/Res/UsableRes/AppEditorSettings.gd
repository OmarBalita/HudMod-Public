class_name AppEditorSettings extends UsableRes

signal settings_updated()

@export var high_quality_for_playback: bool = false

@export var media_explorer_waveform_color_a: Color = Color(0.273, 0.463, 1.0, 1.0)
@export var media_explorer_waveform_color_b: Color = Color(0.0, 0.589, 0.872, 1.0)

@export var edit: AppEditRes = AppEditRes.new()
@export var performance: AppPerformanceRes = AppPerformanceRes.new()
@export var shortcuts: AppShortcutsRes = AppShortcutsRes.new()
@export var theme: AppThemeRes = AppThemeRes.new()


var media_clip_default_length_f: int
var project_min_length_f: int

var media_explorer_waveform_gradient: Gradient


func _init() -> void:
	update_internal_props()

func update_internal_props() -> void:
	
	media_explorer_waveform_gradient = Gradient.new()
	media_explorer_waveform_gradient.add_point(.0, media_explorer_waveform_color_a)
	media_explorer_waveform_gradient.add_point(.999, media_explorer_waveform_color_b)
	
	settings_updated.emit()

func update_internal_props_base_on_project() -> void:
	edit.update_internal_props_base_on_project()



