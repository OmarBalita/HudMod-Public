class_name CompTextMagnet extends Text2DComponentRes

enum EffectType {
	TYPE_1,
	TYPE_2
}

@export var use_clip_as_magnet: bool = false
@export var magnet_pos: Vector2
@export var magnet_clip: MediaClipResPath:
	set(val):
		if val:
			await until_ready()
			val.owner = owner
			val.cond_func = MediaClipResPath.node2d_cond
		magnet_clip = val

@export_group(&"Effect Settings")
@export var effect_type: EffectType = EffectType.TYPE_1
@export var effect_curve: CurveProfile = CurveProfile.preset_linear(.0, 1., .01, .0, 128.):
	set(val):
		if val: val.res_changed.connect(emit_res_changed)
		if effect_curve: effect_curve.res_changed.disconnect(emit_res_changed)
		effect_curve = val
@export var effect_force: float = 1.
@export var effect_min_distance: float = 500.
@export var effect_scale: float = .0

var _magnet_pos: Vector2

func _init() -> void:
	effect_curve.res_changed.connect(emit_res_changed)

func set_owner(new_owner: MediaClipRes) -> void:
	super(new_owner)
	magnet_clip = MediaClipResPath.new()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var use_clip_func: Callable = get.bind(&"use_clip_as_magnet")
	return {
		&"use_clip_as_magnet": export(bool_args(use_clip_as_magnet)),
		&"magnet_pos": export(vec2_args(magnet_pos)),
		&"magnet_clip": export([magnet_clip], [use_clip_func, [true]]),
		&"Effect Settings": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"effect_type": export(options_args(effect_type, EffectType)),
		&"effect_curve": export([effect_curve]),
		&"effect_force": export(float_args(effect_force)),
		&"effect_min_distance": export(float_args(effect_min_distance, -INF, INF, .01, .25, 25.)),
		&"effect_scale": export(float_args(effect_scale)),
		&"_Effect Settings": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	}

func emit_res_changed() -> void:
	super()
	if magnet_clip.is_valid():
		magnet_clip.media_res.process_here()

func _process(frame: int) -> void:
	if magnet_clip.media_res:
		var target_frame: int = await owner.wait_until_media_res_processed(magnet_clip.media_res)
	
	if use_clip_as_magnet and magnet_clip.is_valid():
		_magnet_pos = magnet_clip.get_media_res().get_stacked_values_key_result(&"position")
	else:
		_magnet_pos = magnet_pos
	
	super(frame)

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	
	var dist: float = char.offset.distance_to(_magnet_pos if effect_type else magnet_pos)
	if dist < effect_min_distance:
		var t: float = 1. - dist / effect_min_distance
		var weight: float = effect_curve.sample_func.call(t * 128.) * effect_force
		var scale_time: float = effect_scale * weight
		char.offset = char.offset.lerp(_magnet_pos, weight)
		char.transform.x.x += scale_time
		char.transform.y.y += scale_time




