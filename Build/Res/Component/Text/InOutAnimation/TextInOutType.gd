class_name CompTextInOutType extends InOutText2DComponentRes

@export var show_caret: bool
@export var caret_offset: Vector2
@export var caret_height_scalar: float = .5
@export var caret_width: float = 10.
@export var caret_color: Color = Color.WHITE
@export var caret_blink_weight: int = 0

var text_length: float
var caret_pos: Vector2

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return super().merged({
		&"Caret": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"show_caret": export(bool_args(show_caret)),
		&"caret_offset": export(vec2_args(caret_offset)),
		&"caret_height_scalar": export(float_args(caret_height_scalar)),
		&"caret_width": export(float_args(caret_width, .0)),
		&"caret_color": export(color_args(caret_color)),
		&"caret_blink_weight": export(int_args(caret_blink_weight, 0, INF)),
		&"_Caret": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	})

func _process(frame: int) -> void:
	
	text_length = float(owner.text.length())
	super(frame)
	
	var caret_is_visible: bool = caret_blink_weight == 0 or (frame / caret_blink_weight) % 2
	
	if show_caret and caret_is_visible:
		
		var caret_pos: Vector2 = caret_offset
		var caret_height: float
		
		var lines_data: Array[Text2DClipRes.LineData] = owner.lines_data
		
		var target_char_idx: int = text_length * t_ratio
		
		var curr_char_idx: int
		
		for line_idx: int in lines_data.size():
			var line_data: Text2DClipRes.LineData = lines_data[line_idx]
			var line_length: int = line_data.line.length()
			curr_char_idx += line_length
			
			if curr_char_idx > target_char_idx:
				var local_char_idx: int = min(target_char_idx - curr_char_idx + line_length + 1, line_length - 1)
				var char: CharFXTransform = line_data.chars[local_char_idx]
				caret_pos += char.offset
				caret_height = -line_data.height
				break
		
		if target_char_idx == text_length:
			var line_data: Text2DClipRes.LineData = lines_data[-1]
			caret_pos += line_data.chars[-1].offset + Vector2(line_data.glyphs[-1].advance, .0)
			caret_height = -line_data.height
		
		caret_height *= caret_height_scalar
		
		submit_rect_postdraw(Rect2(caret_pos, Vector2(caret_width, caret_height)), caret_color)

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var char_ratio: float = global_idx / text_length
	char.visible = char_ratio < t_ratio

