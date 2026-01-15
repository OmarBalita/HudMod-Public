class_name Text2D extends Node2D


var text_res: Text2DRes:
	set(val):
		text_res = val
		
		self.text           = text_res.get_prop(&"text")
		self.text_slices    = text_res.get_prop(&"text_slices")
		self.lines_data     = text_res.get_prop(&"lines_data")
		self.tracking       = text_res.get_prop(&"tracking")
		self.lines_spacing  = text_res.get_prop(&"lines_spacing")
		self.text_alignment = text_res.get_prop(&"text_alignment")
		self.pivot_position = text_res.get_prop(&"pivot_position")
		
		text_res.on_update_data.connect(update_data)
		text_res.on_update_lines_positions.connect(update_lines_positions)
		text_res.on_update_characters.connect(update_characters)

const TextAlignment = Text2DRes.TextAlignment
const PivotPosition = Text2DRes.PivotPosition

var text: String = ""
var text_slices: Array[TextSliceRes] = []
var lines_data: Array[LineData] = []
var tracking: float = .0
var lines_spacing: float = .0
var text_alignment: TextAlignment = TextAlignment.LEFT
var pivot_position: PivotPosition = PivotPosition.CENTER

var ts: TextServer
var total_text_size: Vector2 = Vector2.ZERO
var chars_data: Array = []
var shaped_texts: Array = []
var non_space_map: PackedInt32Array

# ===== Initialization =====

func _init(_text_res) -> void:
	text_res = _text_res
	ts = TextServerManager.get_primary_interface()


func _ready() -> void:
	update_data()



# ===== Utility Functions =====
func add_new_text_slice() -> void:
	var new_text_slice: TextSliceRes = TextSliceRes.new()
	new_text_slice.text_slice_property_changed.connect(_on_text_slice_property_changed)
	text_slices.append(new_text_slice)



# ===== Data Building =====
func update_data() -> void:
	var saved_lines_settings: Array[Dictionary] = []
	for line: LineData in lines_data:
		saved_lines_settings.append({
			"line_align": line.line_align,
			"line_offset": line.line_offset,
		})
	
	chars_data.clear()
	lines_data.clear()
	_clear_shaped_textes()
	_build_non_space_map()
	
	var curr_char_index: int = 0
	var lines: PackedStringArray = text.split("\n", true)
	
	for line_index: int in lines.size():
		var raw_line: String = lines[line_index]
		var line_text: String = raw_line
		if line_text.strip_edges().is_empty():
			line_text = "\n"
		
		var line_data: LineData = _prepare_line_data(line_text, curr_char_index)
		line_data.line_data_changed.connect(_on_line_data_changed)
		
		if line_index < saved_lines_settings.size():
			var saved: Dictionary = saved_lines_settings[line_index]
			line_data.line_align = saved.line_align
			line_data.line_offset = saved.line_offset
		
		lines_data.append(line_data)
		
		_build_characters(line_data, line_text, curr_char_index)
		curr_char_index += line_text.length()
	
	update_lines_positions()

func _build_non_space_map() -> void:
	non_space_map.clear()
	non_space_map.resize(text.length())
	
	var count: int = 0
	for index in text.length():
		var ch = text[index]
		if ch != ' ' and ch != '\t' and ch != '\n':
			non_space_map[index] = count
			count += 1
		else:
			non_space_map[index] = count

func _build_characters(line_data: LineData, line_text: String, line_start_index: int) -> void:
	var segments: Array[TextSegmentRes] = line_data.segments
	var current_position: Vector2 = line_data.position
	
	for segment: TextSegmentRes in segments:
		var glyphs: Array = segment.glyphs
		var slice: TextSliceRes = segment.slice
		var slice_font_size: int = slice.font_size if slice != null else 16
		
		for glyph: Dictionary in glyphs:
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
		
		var segment: TextSegmentRes = _create_new_segment(glyphs, slice, line_width, height, ascent, descent)
		return _create_new_line_data([segment], height, ascent, descent, LineData.LineAlignment.NONE, line_text, Vector2.ZERO)
	
	# --- Multi-slice ---
	var line_shape: Dictionary = _shape_multislice_line(line_text, line_start_index)
	var ordered_glyphs: Array = line_shape.ordered_glyphs
	var bidi_rid: RID = line_shape.bidi_rid
	
	var segments_data: Dictionary = _compose_segments_from_glyphs(ordered_glyphs, line_text, line_start_index)
	if bidi_rid.is_valid():
		ts.free_rid(bidi_rid)
	
	return _create_new_line_data(segments_data.segments, segments_data.max_line_height, segments_data.max_ascent, segments_data.max_descent,LineData.LineAlignment.NONE, line_text, Vector2.ZERO)

func _shape_multislice_line(line_text: String, line_start_index: int) -> Dictionary:
	var char_to_slice_map: Array[TextSliceRes] = []
	char_to_slice_map.resize(line_text.length())
	
	for index: int in line_text.length():
		var global_index: int = line_start_index + index
		char_to_slice_map[index] = _get_slice_at_position_non_space(global_index)
	
	var main_shaped: RID = ts.create_shaped_text()
	
	var slice_segments: Array[Dictionary] = []
	var current_segment_start: int = 0
	var current_slice: TextSliceRes = char_to_slice_map[0]
	
	for index in range(1, line_text.length()):
		if char_to_slice_map[index] != current_slice:
			slice_segments.append({
				"start": current_segment_start,
				"end": index,
				"slice": current_slice
			})
			current_segment_start = index
			current_slice = char_to_slice_map[index]
	
	slice_segments.append({
		"start": current_segment_start,
		"end": line_text.length(),
		"slice": current_slice
	})
	
	for segment: Dictionary in slice_segments:
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
	
	for glyph: Dictionary in glyphs:
		ordered_glyphs.append(glyph.duplicate())
	
	return {
		"ordered_glyphs": ordered_glyphs,
		"bidi_rid": main_shaped
	}

func _compose_segments_from_glyphs(ordered_glyphs: Array, line_text: String, line_start_index: int) -> Dictionary:
	var segments: Array[TextSegmentRes] = []
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
	
	var current_segment: TextSegmentRes = _create_new_segment()
	var last_slice: TextSliceRes = null
	
	for glyph: Dictionary in ordered_glyphs:
		var char_index: int = line_start_index + glyph.start
		var current_slice: TextSliceRes = _get_slice_at_position_non_space(char_index)
		
		if last_slice != null and last_slice != current_slice:
			if current_segment.glyphs.size() > 0:
				max_line_height = max(max_line_height, current_segment.height)
				max_ascent = max(max_ascent, current_segment.max_ascent)
				max_descent = max(max_descent, current_segment.max_descent)
				segments.append(current_segment)
			current_segment = _create_new_segment()
		
		if current_segment.slice != current_slice:
			current_segment.slice = current_slice
			current_segment.update_metrics_from_font()
		
		current_segment.add_glyph(glyph)
		last_slice = current_slice
	
	if current_segment.glyphs.size() > 0:
		max_line_height = max(max_line_height, current_segment.height)
		max_ascent = max(max_ascent, current_segment.max_ascent)
		max_descent = max(max_descent, current_segment.max_descent)
		segments.append(current_segment)
	
	return { "segments": segments, "max_line_height": max_line_height, "max_ascent": max_ascent,"max_descent": max_descent }



# ===== Updating Data =====
func update_characters() -> void:
	chars_data.clear()
	
	var curr_char_index: int = 0
	var lines: PackedStringArray = text.split("\n", true)
	
	for line_index: int in lines.size():
		if line_index >= lines_data.size():
			break
		
		var raw_line: String = lines[line_index]
		var line_text: String = raw_line
		if line_text.strip_edges().is_empty():
			line_text = "\n"
		
		_build_characters(lines_data[line_index], line_text, curr_char_index)
		curr_char_index += line_text.length()
	
	_update_chars_positions()
	queue_redraw()



# ===== Line & Segment Creation =====
func _create_new_line_data(p_segments: Array[TextSegmentRes], p_max_height: float, p_max_ascent: float, p_max_descent: float, p_line_align: int, p_line_text: String, p_position: Vector2) -> LineData:
	var new_line_data: LineData = LineData.new()
	
	new_line_data.segments = p_segments
	new_line_data.max_height = p_max_height
	new_line_data.max_ascent = p_max_ascent
	new_line_data.max_descent = p_max_descent
	new_line_data.line_align = p_line_align
	new_line_data.line_text = p_line_text
	new_line_data.position = p_position
	
	return new_line_data

func _create_new_segment(p_glyphs: Array[Dictionary] = [], p_slice: TextSliceRes = null, p_width: float = 0.0, p_height: float = 0.0, p_max_ascent: float = 0.0, p_max_descent: float = 0.0) -> TextSegmentRes:
	var new_segment: TextSegmentRes = TextSegmentRes.new()
	
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



# ===== Slice & Font Helpers =====
func _get_font_variation_rids(font: Font, text_slice: TextSliceRes) -> Array[RID]:
	var fonts = font.get_rids()
	var index: int = clampi(text_slice.font_variation, 0, fonts.size() - 1)
	return [fonts[index]]

func _get_slice_at_position(pos: int) -> TextSliceRes:
	for index in range(text_slices.size() - 1, -1, -1):
		if pos >= text_slices[index].start_char_index:
			return text_slices[index]
	return text_slices[0]

func _get_slice_at_position_non_space(global_index: int) -> TextSliceRes:
	var non_space_index: int = _get_non_space_index(global_index)
	for index in range(text_slices.size() - 1, -1, -1):
		if non_space_index >= text_slices[index].start_char_index:
			return text_slices[index]
	return text_slices[0] if text_slices.size() > 0 else TextSliceRes.new()

func _get_non_space_index(global_index: int) -> int:
	if global_index >= non_space_map.size():
		return non_space_map[non_space_map.size() - 1] if non_space_map.size() > 0 else 0
	return non_space_map[global_index]

func _get_global_index(index: int) -> int:
	var count: int = 0
	for char_index: int in text.length():
		var char = text[char_index]
		if char != ' ' and char != '\t' and char != '\n':
			if count == index:
				return char_index
			count += 1
	return text.length()



# ===== Pivot & Position =====
func update_lines_positions() -> void:
	if lines_data.is_empty():
		return
	
	var max_line_width: float = 0.0
	var total_height: float = 0.0
	
	for line: LineData in lines_data:
		var line_width: float = line.calculate_total_width()
		max_line_width = max(max_line_width, line_width)
		total_height += line.max_height * lines_spacing
	
	total_text_size = Vector2(max_line_width, total_height)
	
	var y_offset: float = 0.0
	for line_index in lines_data.size():
		var line: LineData = lines_data[line_index]
		
		var effective_align: int = line.line_align
		if effective_align == LineData.LineAlignment.NONE:
			effective_align = int(text_alignment)
		
		line.set_position_with_y_offset(effective_align, y_offset)
		y_offset += line.max_height * lines_spacing
	
	_update_chars_positions()
	queue_redraw()

func _update_chars_positions() -> void:
	var pivot_offset: Vector2 = _get_pivot_offset()
	
	var char_index: int = 0
	for line: LineData in lines_data:
		var line_start_pos: Vector2 = line.position
		
		var effective_align: int = line.line_align
		if effective_align == LineData.LineAlignment.NONE:
			effective_align = int(text_alignment)
		
		var total_tracking_offset: float = 0.0
		for segment: TextSegmentRes in line.segments:
			total_tracking_offset += segment.glyphs.size() * tracking * segment.slice.font_size
		
		var tracking_center_offset: float = total_tracking_offset / 2.0
		
		var alignment_x: float = line.calculate_x_offset(effective_align) - tracking_center_offset
		var current_x: float = alignment_x
		
		for segment: TextSegmentRes in line.segments:
			for glyph: Dictionary in segment.glyphs:
				if char_index >= chars_data.size():
					break
				
				var char_data: CharacterData = chars_data[char_index]
				var glyph_offset: Vector2 = glyph.offset
				
				char_data.global_position = Vector2(current_x + line.line_offset.x, line_start_pos.y) + glyph_offset + pivot_offset
				
				current_x += glyph.advance + tracking * segment.slice.font_size
				char_index += 1

func _get_pivot_offset() -> Vector2:
	var offset: Vector2 = Vector2.ZERO
	
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



# ===== Draw =====
func _draw() -> void:
	var slice_groups: Dictionary = {}
	
	for char_data: CharacterData in chars_data:
		var slice: TextSliceRes = char_data.text_slice
		if slice == null:
			continue
		
		if not slice_groups.has(slice):
			slice_groups[slice] = []
		slice_groups[slice].append(char_data)
	
	# Shadow
	for slice in slice_groups.keys():
		var chars_in_slice: Array = slice_groups[slice]
		
		if slice.shadow_color.a > 0:
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
	
	for char_data: CharacterData in chars_data:
		var xf: Transform2D = char_data.get_transform()
		draw_set_transform_matrix(xf)
		
		if char_data.font_rid.is_valid():
			var slice: TextSliceRes = char_data.text_slice
			if slice == null: continue
			
			if !slice.outlines.is_empty():
				for outline: TextOutlineRes in slice.outlines:
					if outline.color.a > 0.01 and outline.size > 0:
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
			if slice.outline_color.a > 0.01 and slice.outline_size > 0:
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
				slice.font_color * char_data.color
			)
	
	draw_set_transform_matrix(Transform2D())



# ===== Signels Connetions =====
func _on_text_slice_property_changed() -> void:
	update_data()

func _on_character_property_changed() -> void:
	queue_redraw()

func _on_line_data_changed() -> void:
	update_lines_positions()



# ===== Clean Up =====
func _clear_shaped_textes() -> void:
	for shaped in shaped_texts:
		if shaped.is_valid():
			ts.free_rid(shaped)
	shaped_texts.clear()

func _exit_tree() -> void:
	_clear_shaped_textes()
