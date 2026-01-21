class_name Text2D extends Node2D

var text_res: Text2DRes

func _draw() -> void:
	
	var ts: TextServer = Text2DRes.ts
	var canvas_item_rid: RID = get_canvas_item()
	
	var lines_data: Array = text_res.lines_data
	for line_index: int in lines_data.size():
		
		var line_data: LineData = lines_data[line_index]
		for segment: TextSegmentRes in line_data.segments:
			
			var theme: TextThemeRes = segment.theme
			var glyphs: Array[Dictionary] = segment.glyphs
			var chars_data: Array[CharacterData] = segment.chars_data
			
			for char_index: int in glyphs.size():
				var glyph: Dictionary = glyphs[char_index]
				var char_data: CharacterData = chars_data[char_index]
				
				var font_size: int = theme.font_size
				
				draw_set_transform_matrix(char_data.transform)
				
				var shadow_delta: float = 1. / float(theme.shadow_size)
				var shadow_color_alpha: float = theme.shadow_color.a
				for shadow_time: int in theme.shadow_size:
					var shadow_opacity: float = (1. - (shadow_time * shadow_delta)) * shadow_color_alpha
					ts.font_draw_glyph_outline(glyph.font_rid, canvas_item_rid, theme.font_size, (shadow_time + 1) * theme.shadow_spread, theme.shadow_offset, glyph.index, Color(theme.shadow_color, shadow_opacity))
				
				ts.font_draw_glyph_outline(glyph.font_rid, canvas_item_rid, theme.font_size, theme.outline_size, Vector2.ZERO, glyph.index, theme.outline_color)
			
			if !theme.outlines.is_empty():
				for outline: TextOutlineRes in theme.outlines:
					for char_index: int in glyphs.size():
						var glyph: Dictionary = glyphs[char_index]
						var char_data: CharacterData = chars_data[char_index]
						
						draw_set_transform_matrix(char_data.transform)
						ts.font_draw_glyph_outline(glyph.font_rid, canvas_item_rid, theme.font_size, outline.size, outline.offset, glyph.index, outline.color)
			
			for char_index: int in glyphs.size():
				var glyph: Dictionary = glyphs[char_index]
				var char_data: CharacterData = chars_data[char_index]
				
				draw_set_transform_matrix(char_data.transform)
				ts.font_draw_glyph(glyph.font_rid, canvas_item_rid, theme.font_size, Vector2.ZERO, glyph.index, theme.font_color * char_data.color)
	
	draw_set_transform_matrix(Transform2D())
