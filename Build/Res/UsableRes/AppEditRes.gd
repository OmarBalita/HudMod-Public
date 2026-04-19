class_name AppEditRes extends UsableRes

@export var replay: bool = true

@export var default_clip_duration: float = 5.
@export var default_fade_duration: float = .5
@export var default_transition_duration: float = .5

@export var auto_snap: bool = true
@export var snap_strength: float = 1.

@export var auto_save: bool = true
@export var auto_save_interval: float = 5. # minutes

var default_clip_duration_frame: int

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"replay": export(bool_args(replay)),
		
		&"default_clip_duration": export(float_args(default_clip_duration, .01)),
		&"default_fade_duration": export(float_args(default_fade_duration, .01)),
		#&"default_transition_duration": export(float_args(default_transition_duration, .01)),
		
		&"auto_snap": export(bool_args(auto_snap)),
		&"snap_strength": export(float_args(snap_strength, .1, 4.)),
		
		&"auto_save": export(bool_args(auto_save)),
		&"auto_save_interval": export(float_args(auto_save_interval, 1., 120.))
	}

func set_prop(property_key: StringName, property_val: Variant) -> void:
	super(property_key, property_val)
	update_internal_props_base_on_project()

func update_internal_props_base_on_project() -> void:
	if ProjectServer2: default_clip_duration_frame = default_clip_duration * ProjectServer2.fps




