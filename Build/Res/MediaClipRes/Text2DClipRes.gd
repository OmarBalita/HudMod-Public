@icon("res://Asset/Icons/Objects/text-2d.png")
class_name Text2DClipRes extends Display2DClipRes

static var ts: TextServer = TextServerManager.get_primary_interface()

enum AlignmentHorizontal {
	LEFT,
	CENTER,
	RIGHT
}

@export var text: String:
	set(val):
		text = val
		dirty_level = 2
		emit_res_changed()

@export var horizontal_alignment: AlignmentHorizontal = 1

@export var font: FontRes = FontRes.new():
	set(val):
		if val: val.res_changed.disconnect(_build)
		if font: font.res_changed.connect(_build)
		font = val

@export var font_size: int = 24
@export var font_color: Color = Color.WHITE

@export var outline_size: int
@export var outline_offset: Vector2
@export var outline_color: Color
@export var multi_outlines: Array

@export var shadow_size: int = 0
@export var shadow_quality: int = 12
@export var shadow_offset: Vector2
@export var shadow_color: Color

var lines_data: Array[LineData] = []
var width: float
var height: float
var offset: Vector2

var predraw: Array[Dictionary]
var postdraw: Array[Dictionary]

var dirty_level: int = 0


static func get_media_clip_info() -> Dictionary[StringName, String]:
	return {
	&"title": "Text2D",
	&"description": ""
}

func set_prop(property_key: StringName, property_val: Variant) -> void:
	if get_prop(property_key) != property_val:
		dirty_level = max(1, dirty_level)
	super(property_key, property_val)

func _init() -> void:
	font.res_changed.connect(_build)

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"text": export(string_args(text, 1)),
		
		&"horizontal_alignment": export(options_args(horizontal_alignment, AlignmentHorizontal)),
		
		&"Font": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"font": export([font]),
		&"font_size": export(int_args(font_size, 1, 1000)),
		&"font_color": export(color_args(font_color)),
		&"_Font": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Outline": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"outline_size": export(int_args(outline_size, 0)),
		&"outline_offset": export(vec2_args(outline_offset)),
		&"outline_color": export(color_args(outline_color)),
		&"multi_outlines": export(list_args(multi_outlines, &"Outline")),
		&"_Outline": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Shadow": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"shadow_size": export(int_args(shadow_size, 0, 1000)),
		&"shadow_quality": export(int_args(shadow_quality, 1, 100)),
		&"shadow_offset": export(vec2_args(shadow_offset)),
		&"shadow_color": export(color_args(shadow_color)),
		&"_Shadow": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	} as Dictionary[StringName, ExportInfo].merged(super())

func init_node(layer_idx: int, frame_in: int) -> Node:
	var text_2d:= Text2D.new()
	text_2d.text_clip_res = self
	return text_2d

func _process_comps(frame: int) -> void:
	
	_update_variants(frame)
	clear_predraw()
	clear_postdraw()
	
	super(frame)
	
	match dirty_level:
		0: pass
		1: _build()
		2: _build_all()
	
	dirty_level = 0
	
	curr_node.queue_redraw()


func get_text() -> String: return text
func set_text(new_val: String) -> void: text = new_val

func get_lines_data() -> Array[LineData]: return lines_data
func set_lines_data(new_val: Array[LineData]) -> void: lines_data = new_val

func _destroy() -> void:
	for line_data: LineData in lines_data:
		line_data._destroy_buffer()

func _build() -> void:
	_destroy()
	var _font: Font = font.get_font()
	for line_data: LineData in lines_data:
		line_data._build_buffer(self, _font)
	_update_variants()

func _destroy_all() -> void:
	lines_data.clear()

func _build_all() -> void:
	_destroy_all()
	
	var _font: Font = font.get_font()
	
	var text_splited: PackedStringArray = text.split("\n")
	
	var start_index: int
	
	for line: String in text_splited:
		var line_data: LineData = _create_line_data(start_index, line)
		line_data._build_buffer(self, _font)
		line_data._build_chars_transforms()
		lines_data.append(line_data)
		start_index += line.length() + 1
	
	_update_variants()

func _update_variants(frame: int = -1) -> void:
	
	var _font: Font = font.get_font()
	
	width = .0
	height = .0
	
	for line_data: LineData in lines_data:
		line_data._ypdate_size(self, _font)
		
		width = max(width, line_data.width)
		height += line_data.height
	
	var width_half: float = width / 2.
	var height_half: float = height / 2.
	
	match horizontal_alignment:
		0: offset.x = -width_half
		1: offset.x = .0
		2: offset.x = width_half
	
	offset.y = -height_half
	
	if lines_data:
		var first_line_data: LineData = lines_data[0]
		offset.y += _font.get_ascent(font_size)
	
	var _offset: Vector2 = offset
	
	for line_idx: int in lines_data.size():
		var line_data: LineData = lines_data[line_idx]
		line_data._update_variants(self, _offset, frame)
		_offset.y += line_data.height


func _create_line_data(start_index: int, line: String) -> LineData:
	var line_data: LineData = LineData.new()
	
	var line_length: int = line.length()
	
	line_data.ts = ts
	line_data.start_index = start_index
	line_data.line = line
	
	return line_data


class LineData extends RefCounted:
	
	var ts: TextServerAdvanced
	
	var start_index: int
	var line: String
	
	var buffer: RID
	var glyphs: Array[Dictionary]
	var chars: Array[CharFXTransform]
	
	var ascent: float
	var width: float
	var height: float
	var offset: Vector2
	var global_displ: float
	
	func get_line() -> String: return line
	func set_line(new_val: String) -> void: line = new_val
	
	func get_buffer() -> RID: return buffer
	func set_buffer(new_val: RID) -> void: buffer = new_val
	
	func get_glyphs() -> Array[Dictionary]: return glyphs
	func set_glyphs(new_val: Array[Dictionary]) -> void: glyphs = new_val
	
	func get_chars() -> Array[CharFXTransform]: return chars
	func set_chars(new_val: Array[CharFXTransform]) -> void: chars = new_val
	
	func _destroy_buffer() -> void:
		if buffer.is_valid():
			ts.free_rid(buffer)
	
	func _build_buffer(text_res: Text2DClipRes, font: Font) -> void:
		var font_rids: Array[RID] = font.get_rids()
		var font_size: int = text_res.font_size
		buffer = ts.create_shaped_text()
		ts.shaped_text_add_string(buffer, line, font_rids, font_size)
		glyphs = ts.shaped_text_get_glyphs(buffer)
	
	func _build_chars_transforms() -> void:
		chars.clear()
		
		for glyph: Dictionary in glyphs:
			var char:= CharFXTransform.new()
			
			char.font = glyph.font_rid
			char.glyph_count = glyph.count
			char.glyph_flags = glyph.flags
			char.glyph_index = glyph.index
			char.env = {&"offset_ratio": .0}
			
			char.range = Vector2i(glyph.start, glyph.end)
			
			chars.append(char)
	
	func _ypdate_size(text_res: Text2DClipRes, font: Font) -> void:
		var font_size: int = text_res.font_size
		ascent = font.get_ascent(font_size)
		width = ts.shaped_text_get_width(buffer)
		height = ascent + font.get_descent(text_res.font_size)
	
	func _update_variants(text_res: Text2DClipRes, parent_offset: Vector2, frame: int) -> void:
		
		match text_res.horizontal_alignment:
			0:
				offset.x = .0
				global_displ = .0
			1:
				offset.x = -width / 2.
				global_displ = (text_res.width - width) / 2.
			2:
				offset.x = -width
				global_displ = (text_res.width - width)
		
		offset.y = parent_offset.y
		
		var pos: Vector2 = Vector2(parent_offset.x + offset.x, parent_offset.y)
		
		for idx: int in glyphs.size():
			
			var glyph: Dictionary = glyphs[idx]
			var char: CharFXTransform = chars[idx]
			
			char.offset = pos
			char.env.offset_ratio = (pos.x - offset.x - text_res.offset.x + global_displ) / text_res.width
			char.transform = Transform2D.IDENTITY
			char.color = text_res.font_color
			char.elapsed_time = frame
			
			pos.x += glyph.advance
	
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			if buffer.is_valid(): ts.free_rid(buffer)


func clear_predraw() -> void:
	predraw.clear()

func add_line_predraw(from: Vector2, to: Vector2, color: Color, width: int, antialized: bool) -> int:
	predraw.append({&"draw_line": [from, to, color, width, antialized]})
	return predraw.size()

func add_rect_predraw(rect: Rect2, color: Color, filled: bool, width: int, antialized: bool) -> int:
	predraw.append({&"draw_rect": [rect, color, filled, width, antialized]})
	return predraw.size()

func add_circle_predraw(position: Vector2, radius: float, color: Color, width: int, antialized: bool) -> int:
	predraw.append({&"draw_circle": [position, radius, color, width, antialized]})
	return predraw.size()

func add_polyline_predraw(points: PackedVector2Array, color: Color, width: int, antialized: bool) -> int:
	predraw.append({&"draw_polyline": [points, color, width, antialized]})
	return predraw.size()

func add_polygon_predraw(points: PackedVector2Array, colors: PackedColorArray, uvs: PackedVector2Array, texture: Texture2D) -> int:
	predraw.append({&"draw_polygon": [points, colors, uvs, texture]})
	return predraw.size()

func remove_predraw(idx: int) -> void:
	predraw.erase(idx)

func clear_postdraw() -> void:
	postdraw.clear()

func add_line_postdraw(from: Vector2, to: Vector2, color: Color, width: int, antialized: bool) -> int:
	postdraw.append({&"draw_line": [from, to, color, width, antialized]})
	return postdraw.size()

func add_rect_postdraw(rect: Rect2, color: Color, filled: bool, width: int, antialized: bool) -> int:
	postdraw.append({&"draw_rect": [rect, color, filled, width, antialized]})
	return postdraw.size()

func add_circle_postdraw(position: Vector2, radius: float, color: Color, width: int, antialized: bool) -> int:
	postdraw.append({&"draw_circle": [position, radius, color, width, antialized]})
	return postdraw.size()

func add_polyline_postdraw(points: PackedVector2Array, color: Color, width: int, antialized: bool) -> int:
	postdraw.append({&"draw_polyline": [points, color, width, antialized]})
	return postdraw.size()

func add_polygon_postdraw(points: PackedVector2Array, colors: PackedColorArray, uvs: PackedVector2Array, texture: Texture2D) -> int:
	postdraw.append({&"draw_polygon": [points, colors, uvs, texture]})
	return postdraw.size()

func remove_postdraw(idx: int) -> void:
	postdraw.erase(idx)


