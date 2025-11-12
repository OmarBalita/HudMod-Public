@tool
class_name Text2D extends Node2D

signal text_changed(new_text: String)
signal font_changed(new_font: Font)

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

@export var tracking: float = 1.0:
	set(val):
			tracking = val
			update_data()

var ts: TextServer
var chars_data: Array[CharData]
var shaped_texts: Array[RID]

func _init() -> void:
	ts = TextServerManager.get_primary_interface()

func _ready() -> void:
	update_data()

func update_data() -> void:
	chars_data.clear()
	_clear_shaped_textes()
	
	var curr_char_index: int = 0
	var lines: PackedStringArray = text.split("\n")
	
	for line_index in lines.size():
		var line_text: String = lines[line_index]
		var line_start_index: int = curr_char_index
		if line_text.is_empty(): line_text = "\n"; continue
		
		var line_data: Dictionary = _prepare_line_data(line_text, line_start_index)
		var segments: Array = line_data.segments
		var max_line_height: float = line_data.max_height
		
		var total_line_width: float = 0.0
		for segment in segments:
			total_line_width += segment.width
		
		var y_offset: float = line_index * max_line_height * line_spacing
		
		var first_slice: TextSliceRes = segments[0].slice if segments.size() > 0 else TextSliceRes.new()
		var x_offset: float = _calculate_x_offset(first_slice.text_align, total_line_width)
		var current_position: Vector2 = Vector2(x_offset, y_offset)
		
		for segment in segments:
			var glyphs: Array = segment.glyphs
			
			for glyph in glyphs:
				var char_start: int = glyph.start
				var char_end: int = glyph.end
				var character: String = line_text.substr(char_start, char_end - char_start)
				var global_char_index: int = line_start_index + char_start
				
				var glyph_offset: Vector2 = glyph.get("offset", Vector2.ZERO)
				var character_data: CharData = CharData.new(
					character,
					glyph.index,
					global_char_index,
					current_position + glyph_offset,
					glyph.advance,
					glyph.font_rid
				)
				character_data.character_property_changed.connect(func(): queue_redraw())
				
				chars_data.append(character_data)
				current_position.x += glyph.advance * tracking
		
		curr_char_index += line_text.length() + 1
	
	queue_redraw()


func _prepare_line_data(line_text: String, line_start_index: int) -> Dictionary:
	var segments: Array[Dictionary] = []
	var max_line_height: float = 0.0
	
	## Build line segments (If the text has only one TextSliceRes (or no slices))
	if text_slices.is_empty() or text_slices.size() == 1:
		var slice: TextSliceRes = _get_slice_at_position(line_start_index)
		var font_variations: Array[RID] = _get_font_variation_rids(slice.font, slice)
		var shaped_line_rid: RID = _create_shaped_line(line_text, font_variations, slice.font_size)
		shaped_texts.append(shaped_line_rid)
		
		var all_glyphs: Array[Dictionary] = ts.shaped_text_get_glyphs(shaped_line_rid)
		var line_width: float = ts.shaped_text_get_size(shaped_line_rid).x
		var line_height: float = slice.font.get_height(slice.font_size)
		
		segments.append({
			"glyphs": all_glyphs,
			"slice": slice,
			"width": line_width,
			"height": line_height
		})
		
		return { "segments": segments, "max_height": line_height, "line_text": line_text }
	
	var slice_ranges: Array = []
	var curr_char_pos: int = 0
	## Slice splitting
	while curr_char_pos < line_text.length():
		var global_char_index: int = line_start_index + curr_char_pos
		var current_slice: TextSliceRes = _get_slice_at_position(global_char_index)
		var slice_end_index: int = line_text.length()
		
		for slice_candidate in text_slices:
			var slice_global_start: int = _get_global_index(slice_candidate.start_char_index)
			if slice_global_start > global_char_index and slice_global_start < line_start_index + slice_end_index:
				slice_end_index = slice_global_start - line_start_index
		
		slice_ranges.append({
			"start_index": curr_char_pos,
			"end_index": slice_end_index,
			"slice": current_slice,
			"text": line_text.substr(curr_char_pos, slice_end_index - curr_char_pos)
		})
		
		curr_char_pos = slice_end_index
	
	var first_slice = slice_ranges[0].slice
	var reference_fonts = _get_font_variation_rids(first_slice.font, first_slice)
	var bidi_shaped_line: RID = _create_shaped_line(line_text, reference_fonts, first_slice.font_size)
	var bidi_glyphs: Array[Dictionary] = ts.shaped_text_get_glyphs(bidi_shaped_line)
	
	## Processing glyphs draw data
	var shaped_glyphs_map: Dictionary = {}
	for slice_range in slice_ranges:
		var slice: TextSliceRes = slice_range.slice
		var slice_text: String = slice_range.text
		var slice_start_index: int = slice_range.start_index
		if slice_text.is_empty():
			continue
		
		var font_variations: Array[RID] = _get_font_variation_rids(slice.font, slice)
		var shaped_slice_rid: RID = _create_shaped_line(slice_text, font_variations, slice.font_size)
		shaped_texts.append(shaped_slice_rid)
		
		var slice_glyphs: Array[Dictionary] = ts.shaped_text_get_glyphs(shaped_slice_rid)
		for glyph in slice_glyphs:
			shaped_glyphs_map[slice_start_index + glyph.start] = glyph.duplicate()
	
	## Bidirectional processing (و يـ د يـ فـ -> فيديو)
	var ordered_glyphs: Array = []
	for bidi_glyph in bidi_glyphs:
		var char_index: int = bidi_glyph.start
		if shaped_glyphs_map.has(char_index):
			var correct_glyph: Dictionary = shaped_glyphs_map[char_index]
			ordered_glyphs.append({
				"start": bidi_glyph.start,
				"end": bidi_glyph.end,
				"index": correct_glyph.index,
				"font_rid": correct_glyph.font_rid,
				"advance": correct_glyph.advance,
				"offset": correct_glyph.get("offset", Vector2.ZERO),
				"flags": correct_glyph.get("flags", 0)
			})
		else:
			ordered_glyphs.append(bidi_glyph.duplicate())
	
	var current_segment: Dictionary = { "glyphs": [], "slice": null, "width": 0.0, "height": 0.0 }
	
	## Process glyph in segment
	for glyph in ordered_glyphs:
		var char_global_index: int = line_start_index + glyph.start
		var slice_for_glyph: TextSliceRes = _get_slice_at_position(char_global_index)
		
		if current_segment.slice != null and slice_for_glyph != current_segment.slice:
			if current_segment.glyphs.size() > 0:
				max_line_height = max(max_line_height, current_segment.height)
				segments.append(current_segment.duplicate(true))
			current_segment = { "glyphs": [], "slice": null, "width": 0.0, "height": 0.0 }
		
		if current_segment.slice != slice_for_glyph:
			current_segment.slice = slice_for_glyph
			current_segment.height = slice_for_glyph.font.get_height(slice_for_glyph.font_size)
		
		current_segment.glyphs.append(glyph.duplicate())
		current_segment.width += glyph.advance * tracking
	
	if current_segment.glyphs.size() > 0 and current_segment.slice != null:
		max_line_height = max(max_line_height, current_segment.height)
		segments.append(current_segment)
	
	if bidi_shaped_line.is_valid():
		ts.free_rid(bidi_shaped_line)
	
	return { "segments": segments, "max_height": max_line_height, "line_text": line_text }

func _create_shaped_line(line: String, fonts: Array[RID], size: int) -> RID:
	var shaped: RID = ts.create_shaped_text()
	ts.shaped_text_add_string(shaped, line, fonts, size)
	ts.shaped_text_shape(shaped)
	return shaped


func _calculate_x_offset(align: int, width: float) -> float:
	match align:
		0: # Left
			return 0.0
		1: # Center
			return (-width / 2.0) * tracking
		2: # Right
			return -width * tracking
	return 0.0


func _get_font_variation_rids(font: Font, text_slice: TextSliceRes) -> Array[RID]: 
	var fonts = font.get_rids()
	if fonts.is_empty(): return []
	if fonts.size() == 1: return fonts
	
	var index: int = clampi(text_slice.font_variation, 0, fonts.size() - 1) 
	return [fonts[index]]

func _get_slice_at_position(pos: int) -> TextSliceRes:
	if text_slices.is_empty():
		return TextSliceRes.new()
	
	for i in range(text_slices.size() - 1, -1, -1):
		if pos >= text_slices[i].start_char_index:
			return text_slices[i]
	
	return text_slices[0]

func _get_non_space_index(global_index: int) -> int:
	var non_space_count: int = 0
	for i in range(min(global_index, text.length())):
		if text[i] != ' ' and text[i] != '\t':
			non_space_count += 1
	return non_space_count

func _get_global_index(index: int) -> int:
	var count: int = 0
	for i in range(text.length()):
		if text[i] != ' ' and text[i] != '\t':
			if count == index:
				return i
			count += 1
	return text.length()


func _draw() -> void:
	for char_data in chars_data:
		var xf: Transform2D = char_data.get_transform()
		draw_set_transform_matrix(xf)
		
		if char_data.font_rid.is_valid():
			var slice: TextSliceRes = _get_slice_at_position(_get_non_space_index(char_data.index))
			
			ts.font_draw_glyph_outline(
				char_data.font_rid, 
				get_canvas_item(), 
				slice.font_size, 
				slice.outline_size, 
				Vector2.ZERO, 
				char_data.code, 
				slice.outline_color)
			
			ts.font_draw_glyph(
				char_data.font_rid,
				get_canvas_item(),
				slice.font_size,
				Vector2.ZERO,
				char_data.code,
				slice.font_color)
	
	draw_set_transform_matrix(Transform2D())


func _clear_shaped_textes() -> void:
	for shaped in shaped_texts:
		if shaped.is_valid():
			ts.free_rid(shaped)

func _exit_tree() -> void:
	_clear_shaped_textes()
