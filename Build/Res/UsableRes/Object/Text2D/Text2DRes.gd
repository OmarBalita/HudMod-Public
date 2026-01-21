@icon("res://Asset/Icons/Objects/text-2d.png")
class_name Text2DRes extends Object2DRes

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

enum TextAlignment {
	LEFT,
	CENTER,
	RIGHT
}

static var ts: TextServer = TextServerManager.get_primary_interface()

@export_multiline var text: String:
	set(val): text = val; start_update_data()
@export var tracking: float:
	set(val): tracking = val; update_characters()
@export var lines_spacing: float = 1.:
	set(val): lines_spacing = val; start_update_lines_positions()
@export var text_alignment: TextAlignment = TextAlignment.CENTER:
	set(val): text_alignment = val; start_update_lines_positions()
@export var pivot_position: PivotPosition = PivotPosition.CENTER:
	set(val): pivot_position = val; start_update_lines_positions()
@export var text_themes: Array = [TextThemeRes.new()]
@export var text_themes_data: Dictionary[int, TextThemeRes] = {}
@export var lines_data: Array:
	set(val): lines_data = val; start_update_lines_positions()


var total_text_size: Vector2 = Vector2.ZERO
var non_space_map: PackedInt32Array

var is_calculating: bool

func _init() -> void:
	text_themes_data = {0: text_themes[0]}

func instance_object(parent_res: MediaClipRes, media_res: MediaClipRes, layer_index: int, frame_in: int, root_layer_index: int) -> Node:
	var text_2d: Text2D = Text2D.new()
	text_2d.text_res = self
	Scene2.instance_object_2d(parent_res, media_res, text_2d, layer_index, frame_in, root_layer_index)
	return text_2d

static func get_object_info() -> Dictionary[StringName, String]:
	return {
		&"title": "Text2D",
		&"description": ""
	}

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"text": export(string_args(text, 1)),
		&"Transform": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"tracking": export(float_args(tracking)),
		&"lines_spacing": export(float_args(lines_spacing)),
		&"text_alignment": export(options_args(text_alignment, TextAlignment)),
		&"pivot_position": export(options_args(pivot_position, PivotPosition)),
		&"_Transform": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		&"Apply Theme": export_method(ExportMethodType.METHOD_CALLABLE, method_callable_args(apply_selected_theme_to_selected_text)),
		&"text_themes": export(list_args(text_themes, &"TextThemeRes", true, true, true, true, 1)),
	}

func _send_new_val(edit_box_container: IS.EditBoxContainer, usable_res: UsableRes, prop_key: StringName, prop_new_val: Variant) -> void:
	super(edit_box_container, usable_res, prop_key, prop_new_val)
	if prop_key == &"text_themes":
		delete_non_existent_themes()

func apply_selected_theme_to_selected_text() -> void:
	var text_ctrlr: CustomTextEdit = EditorServer.get_usable_res_property_controller(self, &"text").controller
	var list_ctrlr: ListController = EditorServer.get_usable_res_property_controller(self, &"text_themes").controller
	
	if text_ctrlr.has_selection() and list_ctrlr.focus_index != -1:
		apply_theme(
			text_ctrlr.get_selection_from_index(),
			text_ctrlr.get_selection_to_index(),
			text_themes[list_ctrlr.focus_index]
		)

func delete_non_existent_themes() -> void:
	for text_index: int in text_themes_data.keys():
		if not text_themes.has(text_themes_data[text_index]):
			text_themes_data.erase(text_index)
			if not text_themes_data.has(0):
				text_themes_data[0] = text_themes[0]
	start_update_data(true)

func apply_theme(from: int, to: int, theme: TextThemeRes) -> void:
	text_themes_data[from] = theme
	text_themes_data.sort()
	
	var text_themes_data_keys: Array[int] = text_themes_data.keys()
	var from_index: int = text_themes_data_keys.find(from)
	
	var latest_removed_theme: TextThemeRes
	for index: int in range(from_index + 1, text_themes_data_keys.size()):
		var text_index: int = text_themes_data_keys[index]
		if to < text_index:
			if latest_removed_theme:
				text_themes_data[text_index] = latest_removed_theme
			break
		else:
			latest_removed_theme = text_themes_data[text_index]
			text_themes_data.erase(text_index)
	
	print(text_themes_data)
	
	start_update_data(true)

func start_update_data(force: bool = false) -> void:
	#if not force and text == text_res.text:
		#return
	#if is_calculating:
		#return
	#receive_props()
	#is_calculating = true
	#var thread: Thread = Thread.new()
	update_data(self)
	#WorkerThreadPool.add_task(update_data.bind(text_res))

func update_data(text_res: Text2DRes) -> void:
	var text: String = text_res.text
	var text_themes: Array = text_res.text_themes
	
	_build_non_space_map(text)
	
	var curr_char_index: int = 0
	var lines: PackedStringArray = text.split("\n", true)
	
	var new_lines_data: Array
	for line_index: int in lines.size():
		var raw_line: String = lines[line_index]
		var line_text: String = raw_line
		if line_text.strip_edges().is_empty():
			line_text = "\n"
		
		var line_data: LineData = _prepare_line_data(text_themes, line_text, curr_char_index)
		_build_characters(line_data, line_text, curr_char_index, text_res.tracking)
		new_lines_data.append(line_data)
		curr_char_index += line_text.length()
	
	text_res.set_prop(&"lines_data", new_lines_data)
	
	finish_update.call_deferred()

func finish_update() -> void:
	update_lines_positions()
	
	is_calculating = false
	if text != text:
		start_update_data(true)

func _build_non_space_map(text: String) -> void:
	non_space_map.clear()
	non_space_map.resize(text.length())
	
	var count: int = 0
	for index: int in text.length():
		var ch: String = text[index]
		if ch != ' ' and ch != '\t' and ch != '\n':
			non_space_map[index] = count
			count += 1
		else:
			non_space_map[index] = count

func _build_characters(line_data: LineData, line_text: String, line_start_index: int, tracking: float) -> void:
	var segments: Array[TextSegmentRes] = line_data.segments
	var curr_position: Vector2 = line_data.position
	
	for segment: TextSegmentRes in segments:
		var glyphs: Array[Dictionary] = segment.glyphs
		var theme: TextThemeRes = segment.theme
		var theme_font_size: int = theme.font_size if theme != null else 16
		
		segment.chars_data.clear()
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
			
			segment.chars_data.append(CharacterData.new())
			
			curr_position.x += advance + tracking * theme.font_size


func _prepare_line_data(text_themes: Array, line_text: String, line_start_index: int) -> LineData:
	# --- Single-Theme ---
	var theme: TextThemeRes = _get_theme_at_position(line_start_index)
	var font: Font = theme.font
	var font_size: int = theme.font_size
	var font_variations: Array[RID] = _get_font_variation_rids(font, theme)
	
	var shaped_line_rid: RID = _create_shaped_line(line_text, font_variations, font_size)
	
	var glyphs: Array[Dictionary] = ts.shaped_text_get_glyphs(shaped_line_rid)
	var line_width: float = ts.shaped_text_get_size(shaped_line_rid).x
	var ascent: float = font.get_ascent(font_size)
	var descent: float = font.get_descent(font_size)
	var height: float = ascent + descent
	
	var segment: TextSegmentRes = _create_new_segment(glyphs, theme, line_width, height, ascent, descent)
	return _create_new_line_data([segment], height, ascent, descent, LineData.LineAlignment.NONE, line_text, Vector2.ZERO)
	
	# --- Multi-theme ---
	var line_shape: Dictionary = _shape_multitheme_line(line_text, line_start_index)
	var ordered_glyphs: Array = line_shape.ordered_glyphs
	var bidi_rid: RID = line_shape.bidi_rid
	
	var segments_data: Dictionary = _compose_segments_from_glyphs(ordered_glyphs, line_text, line_start_index)
	if bidi_rid.is_valid():
		ts.free_rid(bidi_rid)
	
	return _create_new_line_data(segments_data.segments, segments_data.max_line_height, segments_data.max_ascent, segments_data.max_descent,LineData.LineAlignment.NONE, line_text, Vector2.ZERO)

func _shape_multitheme_line(line_text: String, line_start_index: int) -> Dictionary:
	var char_to_theme_map: Array[TextThemeRes] = []
	char_to_theme_map.resize(line_text.length())
	
	for index: int in line_text.length():
		var global_index: int = line_start_index + index
		char_to_theme_map[index] = _get_theme_at_position(global_index)
	
	var main_shaped: RID = ts.create_shaped_text()
	
	var theme_segments_infos: Array[Dictionary] = []
	var current_segment_start: int = 0
	var curr_theme: TextThemeRes = char_to_theme_map[0]
	
	for index in range(1, line_text.length()):
		if char_to_theme_map[index] != curr_theme:
			theme_segments_infos.append({
				"start": current_segment_start,
				"end": index,
				"theme": curr_theme
			})
			current_segment_start = index
			curr_theme = char_to_theme_map[index]
	
	theme_segments_infos.append({
		"start": current_segment_start,
		"end": line_text.length(),
		"theme": curr_theme
	})
	
	for segment: Dictionary in theme_segments_infos:
		var theme: TextThemeRes = segment.theme
		var segment_text: String = line_text.substr(segment.start, segment.end - segment.start)
		
		if segment_text.is_empty():
			continue
		
		var fonts: Array = _get_font_variation_rids(theme.font, theme)
		ts.shaped_text_add_string(main_shaped, segment_text, fonts, theme.font_size)
	
	ts.shaped_text_shape(main_shaped)
	
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
	var last_theme: TextThemeRes = null
	
	for glyph: Dictionary in ordered_glyphs:
		var char_index: int = line_start_index + glyph.start
		var current_theme: TextThemeRes = _get_theme_at_position(char_index)
		
		if last_theme != null and last_theme != current_theme:
			if current_segment.glyphs.size() > 0:
				max_line_height = max(max_line_height, current_segment.height)
				max_ascent = max(max_ascent, current_segment.max_ascent)
				max_descent = max(max_descent, current_segment.max_descent)
				segments.append(current_segment)
			current_segment = _create_new_segment()
		
		if current_segment.theme != current_theme:
			current_segment.theme = current_theme
			current_segment.update_metrics_from_font()
		
		current_segment.add_glyph(glyph)
		last_theme = current_theme
	
	if current_segment.glyphs.size() > 0:
		max_line_height = max(max_line_height, current_segment.height)
		max_ascent = max(max_ascent, current_segment.max_ascent)
		max_descent = max(max_descent, current_segment.max_descent)
		segments.append(current_segment)
	
	return { "segments": segments, "max_line_height": max_line_height, "max_ascent": max_ascent,"max_descent": max_descent }


func update_characters() -> void:
	
	var lines_data: Array = lines_data
	
	var curr_char_index: int = 0
	var lines: PackedStringArray = text.split("\n", true)
	
	for line_index: int in lines.size() - 1:
		
		var line_text: String = lines[line_index]
		if line_text.strip_edges().is_empty(): line_text = "\n"
		
		_build_characters(lines_data[line_index], line_text, curr_char_index, tracking)
		curr_char_index += line_text.length()
	
	_update_chars_positions()
	if owner: owner.call_node_method_if(&"queue_redraw")


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

func _create_new_segment(p_glyphs: Array[Dictionary] = [], p_theme: TextThemeRes = null, p_width: float = 0.0, p_height: float = 0.0, p_max_ascent: float = 0.0, p_max_descent: float = 0.0) -> TextSegmentRes:
	var new_segment: TextSegmentRes = TextSegmentRes.new()
	
	new_segment.glyphs = p_glyphs
	new_segment.theme = p_theme
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


func _get_font_variation_rids(font: Font, text_theme: TextThemeRes) -> Array[RID]:
	var fonts: Array[RID] = font.get_rids()
	var index: int = clampi(text_theme.font_variation, 0, fonts.size() - 1)
	return [fonts[index]]

func _get_theme_at_position(pos: int) -> TextThemeRes:
	var text_themes_data_keys: Array = text_themes_data.keys()
	for char_start_index: int in text_themes_data_keys:
		if pos >= char_start_index:
			return text_themes_data[char_start_index]
	return text_themes_data[text_themes_data_keys.front()]

func _get_global_index(index: int) -> int:
	var count: int = 0
	for char_index: int in text.length():
		var char = text[char_index]
		if char != ' ' and char != '\t' and char != '\n':
			if count == index:
				return char_index
			count += 1
	return text.length()

func start_update_lines_positions() -> void:
	update_lines_positions()

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
	if owner: owner.call_node_method_if(&"queue_redraw")

func _update_chars_positions() -> void:
	var pivot_offset: Vector2 = _get_pivot_offset()
	
	for line: LineData in lines_data:
		var line_start_pos: Vector2 = line.position
		
		var effective_align: int = line.line_align
		if effective_align == LineData.LineAlignment.NONE:
			effective_align = int(text_alignment)
		
		var total_tracking_offset: float = 0.0
		for segment: TextSegmentRes in line.segments:
			total_tracking_offset += segment.glyphs.size() * tracking * segment.theme.font_size
		
		var tracking_center_offset: float = total_tracking_offset / 2.0
		
		var alignment_x: float = line.calculate_x_offset(effective_align) - tracking_center_offset
		var current_x: float = alignment_x
		
		for segment: TextSegmentRes in line.segments:
			for char_index: int in segment.glyphs.size():
				var glyph: Dictionary = segment.glyphs[char_index]
				var char_data: CharacterData = segment.chars_data[char_index]
				var glyph_offset: Vector2 = glyph.offset
				
				char_data.global_position = Vector2(current_x + line.line_offset.x, line_start_pos.y) + glyph_offset + pivot_offset
				char_data.update_transform()
				current_x += glyph.advance + tracking * segment.theme.font_size

func _get_pivot_offset() -> Vector2:
	var offset: Vector2 = Vector2.ZERO
	
	var size_half: Vector2 = total_text_size / 2.
	
	match pivot_position:
		PivotPosition.TOP_LEFT: offset = Vector2(-size_half.x, -total_text_size.y)
		PivotPosition.TOP_CENTER: offset = Vector2(.0, -total_text_size.y)
		PivotPosition.TOP_RIGHT: offset = Vector2(size_half.x, -total_text_size.y)
		PivotPosition.CENTER_LEFT: offset = Vector2(-size_half.x, -size_half.y)
		PivotPosition.CENTER: offset = Vector2(.0, -size_half.y)
		PivotPosition.CENTER_RIGHT: offset = Vector2(size_half.x, -size_half.y)
		PivotPosition.BOTTOM_LEFT: offset = Vector2(-size_half.x, .0)
		PivotPosition.BOTTOM_CENTER: offset = Vector2.ZERO
		PivotPosition.BOTTOM_RIGHT: offset = Vector2(size_half.x, .0)
	
	return offset

