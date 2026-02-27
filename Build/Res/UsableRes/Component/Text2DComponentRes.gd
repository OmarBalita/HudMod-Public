@abstract class_name Text2DComponentRes extends ComponentRes

func has_method_type() -> bool: return false

func _process(frame: int) -> void:
	var lines_data: Array[Text2DRes.LineData] = owner.object_res.lines_data
	
	for line_idx: int in lines_data.size():
		var line_data: Text2DRes.LineData = lines_data[line_idx]
		var glyphs: Array[Dictionary] = line_data.glyphs
		var chars: Array[CharFXTransform] = line_data.chars
		for idx: int in glyphs.size():
			var glyph: Dictionary = glyphs[idx]
			var char: CharFXTransform = chars[idx]
			_process_char_fx(line_idx, line_data, idx, glyph, char)

func _process_char_fx(line_idx: int, line_data: Text2DRes.LineData, idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	pass

