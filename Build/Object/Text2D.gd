class_name Text2D extends Node2D

var text_clip_res: Text2DClipRes

func get_text_clip_res() -> Text2DClipRes: return text_clip_res
func set_text_clip_res(new_val: Text2DClipRes) -> void: text_clip_res = new_val

func _draw() -> void:
	
	if not text_clip_res:
		return
	
	for predraw: Dictionary in text_clip_res.predraw:
		var method_key: StringName = predraw.keys()[0]
		callv(method_key, predraw[method_key])
	
	var ts: TextServer = Text2DClipRes.ts
	
	var font_color: Color = text_clip_res.font_color
	
	var outline_size: int = text_clip_res.outline_size
	var outline_color: Color = text_clip_res.outline_color
	var outline_offset: Vector2 = text_clip_res.outline_offset
	var multioutlines: Array = text_clip_res.multi_outlines
	
	var shadow_size: int = text_clip_res.shadow_size
	var shadow_quality: int = text_clip_res.shadow_quality
	var shadow_offset: Vector2 = text_clip_res.shadow_offset
	var shadow_color: Color = text_clip_res.shadow_color
	
	var canvas_item: RID = get_canvas_item()
	
	if shadow_size:
		for time: int in shadow_quality:
			var time_ratio: float = (time + 1) / float(shadow_quality)
			
			var size: int = time_ratio * shadow_size
			var color: Color = Color(shadow_color, (1. - time_ratio) * shadow_color.a)
			
			_loop_glyphs(
				func(line_idx: int, line_data: Text2DClipRes.LineData, glyph: Dictionary, char: CharFXTransform) -> void:
					ts.font_draw_glyph_outline(char.font, canvas_item, glyph.font_size, size, char.offset, char.glyph_index, char.color * color)
			)
	
	if outline_size:
		_loop_glyphs(
			func(line_idx: int, line_data: Text2DClipRes.LineData, glyph: Dictionary, char: CharFXTransform) -> void:
				ts.font_draw_glyph_outline(char.font, canvas_item, glyph.font_size, outline_size, char.offset + outline_offset, char.glyph_index, char.color * outline_color)
		)
	
	for outline: Outline in multioutlines:
		if not outline.size:
			continue
		_loop_glyphs(
			func(line_idx: int, line_data: Text2DClipRes.LineData, glyph: Dictionary, char: CharFXTransform) -> void:
				ts.font_draw_glyph_outline(char.font, canvas_item, glyph.font_size, outline.size, char.offset + outline.offset, char.glyph_index, char.color * outline.color)
		)
	
	_loop_glyphs(
		func(line_idx: int, line_data: Text2DClipRes.LineData, glyph: Dictionary, char: CharFXTransform) -> void:
			ts.font_draw_glyph(char.font, canvas_item, glyph.font_size, char.offset, char.glyph_index, char.color * font_color)
	)
	
	draw_set_transform_matrix(Transform2D.IDENTITY)
	
	for postdraw: Dictionary in text_clip_res.postdraw:
		var method_key: StringName = postdraw.keys()[0]
		callv(method_key, postdraw[method_key])


func _loop_glyphs(method: Callable) -> void:
	var lines_data: Array = text_clip_res.lines_data
	
	for line_index: int in lines_data.size():
		var line_data: Text2DClipRes.LineData = lines_data[line_index]
		var glyphs: Array[Dictionary] = line_data.get_glyphs()
		var chars: Array[CharFXTransform] = line_data.get_chars()
		
		for index: int in glyphs.size():
			var glyph: Dictionary = glyphs[index]
			var char: CharFXTransform = chars[index]
			
			if not char.visible:
				continue
			
			var pivot: Vector2 = char.offset + Vector2(glyph.advance / 2., -glyph.font_size / 3.)
			
			var matrix:= Transform2D()
			matrix = matrix.translated_local(pivot)
			matrix = matrix * char.transform
			matrix = matrix.translated_local(-pivot)
			
			draw_set_transform_matrix(matrix)
			method.call(line_index, line_data, glyph, char)



