@abstract class_name InOutComponentRes extends ComponentRes

@export var apply_in: bool = true
@export var apply_out: bool = true
# time as seconds
@export_range(.0, INF) var in_duration: float = 1.
@export_range(.0, INF) var out_duration: float = 1.

@export var curve: CurveProfile = CurveProfile.preset_linear():
	set(val):
		if curve: curve.res_changed.disconnect(emit_res_changed)
		if val: val.res_changed.connect(emit_res_changed)
		curve = val

var in_dur_f: float
var out_dur_f: float

var out_frame: float

var t_ratio: float

func _init() -> void:
	method_type = MethodType.ADD
	
	in_duration = EditorServer.editor_settings.edit.default_fade_duration
	out_duration = in_duration
	
	curve.res_changed.connect(emit_res_changed)

func has_method_type() -> bool: return false

func _set_owner(new_owner: MediaClipRes) -> void:
	super(new_owner)
	_update_inout_durs_f()

func emit_res_changed() -> void:
	t_ratio = .0
	_update_inout_durs_f()
	super()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"In": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"apply_in": export(bool_args(apply_in)),
		&"in_duration": export(float_args(in_duration, .0, INF)),
		&"_In": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		&"Out": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"apply_out": export(bool_args(apply_out)),
		&"out_duration": export(float_args(out_duration, .0, INF)),
		&"_Out": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		&"Curve": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"curve": export([curve]),
		&"_Curve": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	}

func _process(frame: int) -> void:
	
	if apply_in and frame <= in_dur_f:
		t_ratio = frame / in_dur_f
	elif apply_out and frame >= out_frame:
		t_ratio = 1. - (frame - out_frame) / out_dur_f
	elif t_ratio != 1.:
		t_ratio = 1.
	else:
		return
	
	t_ratio = curve.sample_func.call(t_ratio * 256.)
	_inout(frame)

func _inout(frame: int) -> void:
	pass

func _update_inout_durs_f() -> void:
	in_dur_f = maxf(1., int(ProjectServer2.fps * in_duration))
	out_dur_f = maxf(1., int(ProjectServer2.fps * out_duration))
	out_frame = owner.length - out_dur_f



