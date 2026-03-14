class_name CompTextGradient extends Text2DComponentRes

@export var global_ratio: bool:
	set(val):
		global_ratio = val
		_process_func = _process_global_idx if val else _process_offset_ratio

@export var gradient:= ColorRangeRes.new():
	set(val):
		if gradient: gradient.res_changed.disconnect(emit_res_changed)
		if val: val.res_changed.connect(emit_res_changed)
		gradient = val

var _process_func: Callable = _process_offset_ratio

func _init() -> void:
	gradient.res_changed.connect(emit_res_changed)

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"global_ratio": export([global_ratio]),
		&"gradient": export([gradient])
	}

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	_process_func.call(line_idx, line_data, idx, global_idx, glyph, char)

func _process_global_idx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	char.color *= gradient.sample(global_idx / float(owner.object_res.text.length()))

func _process_offset_ratio(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	char.color *= gradient.sample(char.env.offset_ratio)


