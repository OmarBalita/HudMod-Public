class_name CompTextBackground extends Text2DComponentRes

enum Type {
	TYPE_EACH_LINE,
	TYPE_EACH_CHAR
}

@export var type: Type
@export var color: Color = Color.RED
@export var filled: bool = true
@export var width: int = -1
@export var offset: Vector2
@export var scale: Vector2 = Vector2.ONE
@export var displacement: int

var _font_size: Vector2i

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"Theme": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"type": export(options_args(type, Type)),
		&"color": export(color_args(color)),
		&"filled": export(bool_args(filled)),
		&"width": export(int_args(width, -1, INF)),
		&"_Theme": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Transform": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"offset": export(vec2_args(offset)),
		&"scale": export(vec2_args(scale)),
		&"displacement": export(int_args(displacement), [get.bind(&"type"), [0]]),
		&"_Transform": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	}

func _process(frame: int) -> void:
	_font_size = Vector2i(owner.font_size, 0)
	
	match type:
		0:
			var colors: PackedColorArray = PackedColorArray([color])
			
			for line_data: Text2DClipRes.LineData in owner.get_lines_data():
				
				var glyphs: Array[Dictionary] = line_data.glyphs
				var chars: Array[CharFXTransform] = line_data.chars
				var chars_size: int = chars.size()
				var chars_size_h: int = chars_size / 2
				
				if chars.is_empty():
					continue
				
				var size: Vector2 = Vector2(line_data.width, -line_data.height)
				var y_center: float = line_data.offset.y - line_data.height / 2.
				var y_offset: Vector2 = Vector2(.0, size.y * scale.y / 2.)
				
				var points: PackedVector2Array
				var points_up: PackedVector2Array
				
				for idx: int in chars_size:
					idx = clamp(idx + displacement, 0, chars_size - 1)
					
					var char: CharFXTransform = chars[idx]
					
					var char_ratio: float = float(idx - chars_size_h) / chars_size
					var point_pos: Vector2 = Vector2(char_ratio * size.x * scale.x, y_center)
					
					point_pos += offset + char.transform.origin
					
					points.append(point_pos + y_offset)
					points_up.append(point_pos - y_offset)
				
				points_up.reverse()
				points = points + points_up
				
				submit_polygon_predraw(points, colors)
		1:
			super(frame)

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var size: Vector2 = Text2DClipRes.ts.font_get_glyph_size(char.font, _font_size, char.glyph_index)
	var size_scaled: Vector2 = size * scale
	var pos: Vector2 = offset + char.offset + char.transform.origin + Vector2(.0, -size.y)
	var rect: Rect2 = Rect2(pos - size_scaled / 2. + size / 2., size_scaled)
	submit_rect_predraw(rect, color, filled, width)



