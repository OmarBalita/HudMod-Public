class_name Text2D extends Node2D

var text_res: Text2DRes

func get_text_res() -> Text2DRes: return text_res
func set_text_res(new_val: Text2DRes) -> void: text_res = new_val


func _draw() -> void:
	
	if not text_res:
		return
	
	var ts: TextServer = Text2DRes.ts
	
	var font_color: Color = text_res.font_color
	
	var outline_size: int = text_res.outline_size
	var outline_color: Color = text_res.outline_color
	var outline_offset: Vector2 = text_res.outline_offset
	var multioutlines: Array = text_res.multi_outlines
	
	var shadow_size: int = text_res.shadow_size
	var shadow_quality: int = text_res.shadow_quality
	var shadow_offset: Vector2 = text_res.shadow_offset
	var shadow_color: Color = text_res.shadow_color
	
	var canvas_item: RID = get_canvas_item()
	
	if shadow_size:
		for time: int in shadow_quality:
			var time_ratio: float = (time + 1) / float(shadow_quality)
			
			var size: int = time_ratio * shadow_size
			var color: Color = Color(shadow_color, (1. - time_ratio) * shadow_color.a)
			
			_loop_glyphs(
				func(line_idx: int, line_data: Text2DRes.LineData, glyph: Dictionary, char: CharFXTransform) -> void:
					ts.font_draw_glyph_outline(char.font, canvas_item, glyph.font_size, size, char.offset, char.glyph_index, color)
			)
	
	if outline_size:
		_loop_glyphs(
			func(line_idx: int, line_data: Text2DRes.LineData, glyph: Dictionary, char: CharFXTransform) -> void:
				ts.font_draw_glyph_outline(char.font, canvas_item, glyph.font_size, outline_size, char.offset + outline_offset, char.glyph_index, outline_color)
		)
	
	for outline: Outline in multioutlines:
		if not outline.size:
			continue
		_loop_glyphs(
			func(line_idx: int, line_data: Text2DRes.LineData, glyph: Dictionary, char: CharFXTransform) -> void:
				ts.font_draw_glyph_outline(char.font, canvas_item, glyph.font_size, outline.size, char.offset + outline.offset, char.glyph_index, outline.color)
		)
	
	_loop_glyphs(
		func(line_idx: int, line_data: Text2DRes.LineData, glyph: Dictionary, char: CharFXTransform) -> void:
			ts.font_draw_glyph(char.font, canvas_item, glyph.font_size, char.offset, char.glyph_index, font_color * char.color)
	)
	
	
	#if shadow_size:
		#for time: int in shadow_quality:
			#var time_ratio: float = (time + 1) / float(shadow_quality)
			#
			#var size: int = time_ratio * shadow_size
			#var color: Color = Color(shadow_color, (1. - time_ratio) * shadow_color.a)
			#
			#_loop_lines_data(
				#func(line_idx: int, line_data: Text2DRes.LineData, pos: Vector2) -> void:
					#ts.shaped_text_draw_outline(
						#line_data.get_buffer(),
						#canvas_item,
						#pos + shadow_offset,
						#-1,
						#-1,
						#size,
						#color
					#)
			#)
	#
	#if outline_size:
		#_loop_lines_data(
			#func(line_idx: int, line_data: Text2DRes.LineData, pos: Vector2) -> void:
				#ts.shaped_text_draw_outline(
					#line_data.get_buffer(),
					#canvas_item,
					#pos + outline_offset,
					#-1,
					#-1,
					#outline_size,
					#outline_color
				#)
		#)
	
	#for outline: Outline in multioutlines:
		#if not outline.size:
			#continue
		#
		#_loop_lines_data(
			#func(line_idx: int, line_data: Text2DRes.LineData, pos: Vector2) -> void:
				#ts.shaped_text_draw_outline(
					#line_data.get_buffer(),
					#canvas_item,
					#pos + outline.offset,
					#-1,
					#-1,
					#outline.size,
					#outline.color
				#)
		#)
	
	#_loop_lines_data(
		#func(line_idx: int, line_data: Text2DRes.LineData, pos: Vector2) -> void:
			#ts.shaped_text_draw(
				#line_data.get_buffer(),
				#canvas_item,
				#pos,
				#-1,
				#-1,
				#font_color
			#)
	#)

func _loop_glyphs(method: Callable) -> void:
	
	var lines_data: Array = text_res.lines_data
	
	for line_index: int in lines_data.size():
		var line_data: Text2DRes.LineData = lines_data[line_index]
		var glyphs: Array[Dictionary] = line_data.get_glyphs()
		var chars: Array[CharFXTransform] = line_data.get_chars()
		
		for index: int in glyphs.size():
			var glyph: Dictionary = glyphs[index]
			var char: CharFXTransform = chars[index]
			draw_set_transform_matrix(char.transform)
			method.call(line_index, line_data, glyph, char)

#func _loop_lines_data(method: Callable) -> void:
	#var lines_data: Array = text_res.lines_data
	#
	#var offset: Vector2 = text_res.offset
	#
	#for line_index: int in lines_data.size():
		#var line_data: Text2DRes.LineData = lines_data[line_index]
		#var pos: Vector2 = Vector2(offset.x + line_data.offset.x, offset.y)
		#method.call(line_index, line_data, pos)
		#offset.y += line_data.height











