@tool
class_name Text2D extends Node2D

signal text_changed(new_text: String)

class LineData:
	var segments: Array[Segment]
	var max_height: float
	var max_ascent: float
	var max_descent: float
	var text_align: int
	var line_text: String
	var position: Vector2

class Segment:
	var glyphs: Array[Dictionary]
	var slice: TextSliceRes
	var width: float
	var height: float
	var max_ascent: float
	var max_descent: float

@export_tool_button("Redraw") var redraw_tool_button = update_data
@export var text_slices: Array[TextSliceRes] = [TextSliceRes.new()]

@export_group("Text")
@export_multiline var text: String:
	set(val):
		text = val
		update_data()
		text_changed.emit(text)

@export var line_spacing: float = 1.0:
	set(val):
		line_spacing = val
		update_data()

@export var tracking: float = 0.0:
	set(val):
		tracking = val
		update_data()

@export_group("Pivot")
enum PivotPosition {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	CENTER_LEFT,
	CENTER,
	CENTER_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT
}

@export var pivot_position: PivotPosition = PivotPosition.CENTER:
	set(val):
		pivot_position = val
		update_data()

var ts: TextServer
var total_text_size: Vector2 = Vector2.ZERO
var chars_data: Array = []
var shaped_texts: Array = []
var _non_space_map: PackedInt32Array

func _init() -> void:
	ts = TextServerManager.get_primary_interface()
	chars_data = []
	shaped_texts = []

func _ready() -> void:
	update_data()

func _add_new_text_slice() -> void:
	var new_text_slice: TextSliceRes = TextSliceRes.new()
	new_text_slice.text_slice_property_changed.connect(update_data)
	text_slices.append(new_text_slice)

func update_data() -> void:
	chars_data.clear()
	_clear_shaped_textes()
	_build_non_space_map()
	
	var curr_char_index: int = 0
	var lines: PackedStringArray = text.split("\n", true)
	var line_heights: Array = []
	
	var max_line_width: float = 0.0
	var total_height: float = 0.0
	
	for line_index in range(lines.size()):
		var raw_line: String = lines[line_index]
		var line_text: String = raw_line
		if line_text.strip_edges().is_empty():
			line_text = "\n"
		
		var line_data: LineData = _build_line_data(line_text, curr_char_index, line_index, line_heights)
		line_heights.append(line_data.max_height)
		
		var line_width: float = _calculate_total_line_width(line_data.segments)
		max_line_width = max(max_line_width, line_width)
		total_height += line_data.max_height * line_spacing
		
		_build_chars_from_line(line_data, line_text, curr_char_index)
		curr_char_index += line_text.length()
	
	total_text_size = Vector2(max_line_width, total_height)
	
	_apply_pivot_offset()
	
	queue_redraw()

func _build_line_data(line_text: String, line_start_index: int, line_index: int, line_heights: Array) -> LineData:
	var line_data: LineData = _prepare_line_data(line_text, line_start_index)
	var segments: Array[Segment] = line_data.segments
	var line_align: int = line_data.text_align
	
	var max_ascent: float = line_data.max_ascent
	var max_descent: float = line_data.max_descent
	
	var y_offset: float = 0.0
	for i in range(line_index):
		if i < line_heights.size():
			y_offset += line_heights[i] * line_spacing
	
	line_data.position = Vector2(_calculate_x_offset(line_align, _calculate_total_line_width(segments)), y_offset + max_ascent)
	return line_data

func _build_chars_from_line(line_data: LineData, line_text: String, line_start_index: int) -> void:
	var segments: Array[Segment] = line_data.segments
	var current_position: Vector2 = line_data.position
	
	for segment in segments:
		var glyphs: Array = segment.glyphs
		var slice: TextSliceRes = segment.slice
		var slice_font_size: int = slice.font_size if slice != null else 16
		
		for glyph in glyphs:
			var char_start: int = glyph.start
			var char_end: int = glyph.end
			var character: String = ""
			if char_end > char_start:
				character = line_text.substr(char_start, char_end - char_start)
			
			var global_char_index: int = line_start_index + char_start
			
			var glyph_offset: Vector2 = glyph.offset
			var ch_code: int = glyph.index
			var font_rid: RID = glyph.font_rid
			var advance: float = glyph.advance
			
			var character_data: CharacterData = CharacterData.new(
				character,
				ch_code,
				global_char_index,
				current_position + glyph_offset,
				advance,
				font_rid,
				slice
			)
			character_data.character_property_changed.connect(_on_character_property_changed)
			
			chars_data.append(character_data)
			current_position.x += advance + tracking * slice.font_size


func _prepare_line_data(line_text: String, line_start_index: int) -> LineData:
	# --- Single-slice ---
	if text_slices.is_empty() or text_slices.size() == 1:
		var slice: TextSliceRes = _get_slice_at_position(line_start_index)
		var font: Font = slice.font
		var font_size: int = slice.font_size
		var font_variations: Array = _get_font_variation_rids(font, slice)
		
		var shaped_line_rid: RID = _create_shaped_line(line_text, font_variations, font_size)
		shaped_texts.append(shaped_line_rid)
		
		var glyphs: Array = ts.shaped_text_get_glyphs(shaped_line_rid)
		var line_width: float = ts.shaped_text_get_size(shaped_line_rid).x
		var ascent: float = font.get_ascent(font_size)
		var descent: float = font.get_descent(font_size)
		var height: float = ascent + descent
		
		var segment: Segment = _create_new_segment(glyphs, slice, line_width, height, ascent, descent)
		return _create_new_line_data([segment], height, ascent, descent, 1, line_text, Vector2.ZERO)
	
	# --- Multi-slice ---
	var line_shape: Dictionary = _shape_multislice_line(line_text, line_start_index)
	var ordered_glyphs: Array = line_shape.ordered_glyphs
	var bidi_rid: RID = line_shape.bidi_rid
	
	var segments_data: Dictionary = _compose_segments_from_glyphs(ordered_glyphs, line_text, line_start_index)
	if bidi_rid.is_valid():
		ts.free_rid(bidi_rid)
	
	return _create_new_line_data(segments_data.segments, segments_data.max_line_height, segments_data.max_ascent, segments_data.max_descent, 1, line_text, Vector2.ZERO)

func _shape_multislice_line(line_text: String, line_start_index: int) -> Dictionary:
	var char_to_slice_map: Array[TextSliceRes] = []
	char_to_slice_map.resize(line_text.length())
	
	for i in range(line_text.length()):
		var global_index: int = line_start_index + i
		char_to_slice_map[i] = _get_slice_at_position_real(global_index)
	
	var main_shaped: RID = ts.create_shaped_text()
	
	var slice_segments: Array[Dictionary] = []
	var current_segment_start: int = 0
	var current_slice: TextSliceRes = char_to_slice_map[0]
	
	for i in range(1, line_text.length()):
		if char_to_slice_map[i] != current_slice:
			slice_segments.append({
				"start": current_segment_start,
				"end": i,
				"slice": current_slice
			})
			current_segment_start = i
			current_slice = char_to_slice_map[i]
	
	slice_segments.append({
		"start": current_segment_start,
		"end": line_text.length(),
		"slice": current_slice
	})
	
	for segment in slice_segments:
		var slice: TextSliceRes = segment.slice
		var segment_start: int = segment.start
		var segment_end: int = segment.end
		var segment_text: String = line_text.substr(segment_start, segment_end - segment_start)
		
		if segment_text.is_empty():
			continue
		
		var fonts: Array = _get_font_variation_rids(slice.font, slice)
		
		ts.shaped_text_add_string(main_shaped, segment_text, fonts, slice.font_size)
	
	ts.shaped_text_shape(main_shaped)
	shaped_texts.append(main_shaped)
	
	var ordered_glyphs: Array[Dictionary] = []
	var glyphs: Array = ts.shaped_text_get_glyphs(main_shaped)
	
	for glyph in glyphs:
		ordered_glyphs.append(glyph.duplicate())
	
	return {
		"ordered_glyphs": ordered_glyphs,
		"bidi_rid": main_shaped
	}

func _compose_segments_from_glyphs(ordered_glyphs: Array, line_text: String, line_start_index: int) -> Dictionary:
	var segments: Array[Segment] = []
	var max_line_height: float = 0.0
	var max_ascent: float = 0.0
	var max_descent: float = 0.0
	
	if ordered_glyphs.is_empty():
		return {
			"segments": segments,
			"max_line_height": max_line_height,
			"max_ascent": max_ascent,
			"max_descent": max_descent
		}
	
	var current_segment: Segment = _create_new_segment()
	var last_slice: TextSliceRes = null
	
	for glyph in ordered_glyphs:
		var char_index: int = line_start_index + glyph.start
		var current_slice: TextSliceRes = _get_slice_at_position_real(char_index)
		
		if last_slice != null and last_slice != current_slice:
			if current_segment.glyphs.size() > 0:
				max_line_height = max(max_line_height, current_segment.height)
				max_ascent = max(max_ascent, current_segment.max_ascent)
				max_descent = max(max_descent, current_segment.max_descent)
				segments.append(current_segment)
			current_segment = _create_new_segment()
		
		if current_segment.slice != current_slice:
			current_segment.slice = current_slice
			var font: Font = current_slice.font
			var font_size: int = current_slice.font_size
			current_segment.height = font.get_height(font_size)
			current_segment.max_ascent = font.get_ascent(font_size)
			current_segment.max_descent = font.get_descent(font_size)
		
		current_segment.glyphs.append(glyph.duplicate())
		current_segment.width += glyph.advance
		last_slice = current_slice
	
	if current_segment.glyphs.size() > 0:
		max_line_height = max(max_line_height, current_segment.height)
		max_ascent = max(max_ascent, current_segment.max_ascent)
		max_descent = max(max_descent, current_segment.max_descent)
		segments.append(current_segment)
	
	return { "segments": segments, "max_line_height": max_line_height, "max_ascent": max_ascent,"max_descent": max_descent }


func _build_non_space_map() -> void:
	_non_space_map.clear()
	_non_space_map.resize(text.length())
	
	var count: int = 0
	for i in range(text.length()):
		var ch = text[i]
		if ch != ' ' and ch != '\t' and ch != '\n':
			_non_space_map[i] = count
			count += 1
		else:
			_non_space_map[i] = count

func _apply_pivot_offset() -> void:
	var offset: Vector2 = _get_pivot_offset()
	
	for char_data: CharacterData in chars_data:
		char_data.position += offset


# create new line data
func _create_new_line_data(p_segments: Array[Segment], p_max_height: float, p_max_ascent: float, p_max_descent: float, p_text_align: int, p_line_text: String, p_position: Vector2) -> LineData:
	var new_line_data: LineData = LineData.new()
	
	new_line_data.segments = p_segments
	new_line_data.max_height = p_max_height
	new_line_data.max_ascent = p_max_ascent
	new_line_data.max_descent = p_max_descent
	new_line_data.text_align = p_text_align
	new_line_data.line_text = p_line_text
	new_line_data.position = p_position
	
	return new_line_data

# create new segment
func _create_new_segment(p_glyphs: Array[Dictionary] = [], p_slice: TextSliceRes = null, p_width: float = 0.0, p_height: float = 0.0, p_max_ascent: float = 0.0, p_max_descent: float = 0.0) -> Segment:
	var new_segment: Segment = Segment.new()
	
	new_segment.glyphs = p_glyphs
	new_segment.slice = p_slice
	new_segment.width = p_width
	new_segment.height = p_height
	new_segment.max_ascent = p_max_ascent
	new_segment.max_descent = p_max_descent
	
	return new_segment

func _create_shaped_line(line: String, fonts: Array, size: int) -> RID:
	var shaped: RID = ts.create_shaped_text()
	ts.shaped_text_add_string(shaped, line, fonts, size)
	ts.shaped_text_shape(shaped)
	return shaped

func _calculate_x_offset(align: int, width: float) -> float:
	match align:
		0: # Left
			return 0.0
		1: # Center
			return -width / 2.0
		2: # Right
			return -width
	return 0.0

func _calculate_total_line_width(segments: Array[Segment]) -> float:
	var total_width: float = 0.0
	for segment in segments:
		total_width += segment.width
	return total_width


func _get_pivot_offset() -> Vector2:
	var offset := Vector2.ZERO
	
	match pivot_position:
		PivotPosition.TOP_LEFT:
			offset = Vector2(total_text_size.x / 2.0, 0)
		PivotPosition.TOP_CENTER:
			offset = Vector2.ZERO
		PivotPosition.TOP_RIGHT:
			offset = Vector2(-total_text_size.x / 2.0, 0)
		PivotPosition.CENTER_LEFT:
			offset = Vector2(total_text_size.x / 2.0, -total_text_size.y / 2.0)
		PivotPosition.CENTER:
			offset = Vector2(0, -total_text_size.y / 2.0)
		PivotPosition.CENTER_RIGHT:
			offset = Vector2(-total_text_size.x / 2.0, -total_text_size.y / 2.0)
		PivotPosition.BOTTOM_LEFT:
			offset = Vector2(-total_text_size.x / 2.0, -total_text_size.y)
		PivotPosition.BOTTOM_CENTER:
			offset = Vector2(0, -total_text_size.y)
		PivotPosition.BOTTOM_RIGHT:
			offset = Vector2(total_text_size.x / 2.0, -total_text_size.y)
	
	return offset


func _get_font_variation_rids(font: Font, text_slice: TextSliceRes) -> Array[RID]:
	var fonts = font.get_rids()
	var index: int = clampi(text_slice.font_variation, 0, fonts.size() - 1)
	return [fonts[index]]

func _get_slice_at_position(pos: int) -> TextSliceRes:
	for index in range(text_slices.size() - 1, -1, -1):
		if pos >= text_slices[index].start_char_index:
			return text_slices[index]
	return text_slices[0]

func _get_slice_at_position_real(real_index: int) -> TextSliceRes:
	var non_space_index: int = _get_non_space_index(real_index)
	for i in range(text_slices.size() - 1, -1, -1):
		if non_space_index >= text_slices[i].start_char_index:
			return text_slices[i]
	return text_slices[0] if text_slices.size() > 0 else TextSliceRes.new()

func _get_non_space_index(global_index: int) -> int:
	if global_index >= _non_space_map.size():
		return _non_space_map[_non_space_map.size() - 1] if _non_space_map.size() > 0 else 0
	return _non_space_map[global_index]

func _get_global_index(index: int) -> int:
	var count: int = 0
	for char_index: int in text.length():
		var char = text[char_index]
		if char != ' ' and char != '\t' and char != '\n':
			if count == index:
				return char_index
			count += 1
	return text.length()



func _draw() -> void:
	var slice_groups: Dictionary = {}
	
	for char_data: CharacterData in chars_data:
		var slice: TextSliceRes = char_data.text_slice
		if slice == null:
			continue
			
		if not slice_groups.has(slice):
			slice_groups[slice] = []
		slice_groups[slice].append(char_data)
	
	for slice in slice_groups.keys():
		if slice.shadow_color.a > 0:
			var chars_in_slice: Array = slice_groups[slice]
			
			if slice.shadow_size > 0:
				for char_data: CharacterData in chars_in_slice:
					var xf: Transform2D = char_data.get_transform()
					draw_set_transform_matrix(xf)
					
					if char_data.font_rid.is_valid():
						ts.font_draw_glyph_outline(
							char_data.font_rid,
							get_canvas_item(),
							slice.font_size,
							slice.shadow_size,
							slice.shadow_offset,
							char_data.code,
							slice.shadow_color
						)
			
			for char_data: CharacterData in chars_in_slice:
				var xf: Transform2D = char_data.get_transform()
				draw_set_transform_matrix(xf)
				
				if char_data.font_rid.is_valid():
					ts.font_draw_glyph(
						char_data.font_rid,
						get_canvas_item(),
						slice.font_size,
						slice.shadow_offset,
						char_data.code,
						slice.shadow_color
					)
	
	for char_data: CharacterData in chars_data:
		var xf: Transform2D = char_data.get_transform()
		draw_set_transform_matrix(xf)
		
		if char_data.font_rid.is_valid():
			var slice: TextSliceRes = char_data.text_slice
			
			# Multi outlines
			if slice != null and !slice.outlines.is_empty():
				for outline: TextOutlineRes in slice.outlines:
					ts.font_draw_glyph_outline(
						char_data.font_rid,
						get_canvas_item(),
						slice.font_size,
						outline.size,
						outline.offset,
						char_data.code,
						outline.color
					)
			
			# Main outline
			ts.font_draw_glyph_outline(
				char_data.font_rid,
				get_canvas_item(),
				slice.font_size,
				slice.outline_size,
				Vector2.ZERO,
				char_data.code,
				slice.outline_color
			)
			
			# Fill
			ts.font_draw_glyph(
				char_data.font_rid,
				get_canvas_item(),
				slice.font_size,
				Vector2.ZERO,
				char_data.code,
				slice.font_color
			)
	
	draw_set_transform_matrix(Transform2D())



func _clear_shaped_textes() -> void:
	for shaped in shaped_texts:
		if shaped.is_valid():
			ts.free_rid(shaped)
	shaped_texts.clear()

func _exit_tree() -> void:
	_clear_shaped_textes()

func _on_character_property_changed() -> void:
	queue_redraw()
