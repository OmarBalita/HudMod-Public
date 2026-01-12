class_name LineData extends Resource

signal line_data_changed()

enum LineAlignment {
	NONE = -1,
	LEFT,
	CENTER,
	RIGHT
}

@export var line_align: LineAlignment = LineAlignment.NONE:
	set(val):
		line_align = val
		line_data_changed.emit()

@export var line_offset: Vector2 = Vector2.ONE:
	set(val):
		line_offset = val
		line_data_changed.emit()

var line_text: String
var segments: Array[TextSegmentRes]

var max_height: float
var max_ascent: float
var max_descent: float
var total_width: float

var position: Vector2


func calculate_total_width() -> float:
	var result: float = 0.0
	for segment: TextSegmentRes in segments:
		result += segment.width
	total_width = result
	return result

func calculate_x_offset(align: int = -1) -> float:
	var alignment = align if align != LineAlignment.NONE else line_align
	var width = calculate_total_width()
	
	match alignment:
		LineAlignment.LEFT, 0:
			return 0.0
		LineAlignment.CENTER, 1:
			return -width / 2.0
		LineAlignment.RIGHT, 2:
			return -width
	return 0.0

func update_metrics() -> void:
	max_height = 0.0
	max_ascent = 0.0
	max_descent = 0.0
	
	for segment: TextSegmentRes in segments:
		max_height = max(max_height, segment.height)
		max_ascent = max(max_ascent, segment.max_ascent)
		max_descent = max(max_descent, segment.max_descent)

func add_segment(segment: TextSegmentRes) -> void:
	segments.append(segment)
	max_height = max(max_height, segment.height)
	max_ascent = max(max_ascent, segment.max_ascent)
	max_descent = max(max_descent, segment.max_descent)

func is_empty() -> bool:
	return segments.is_empty() or line_text.strip_edges().is_empty()

func get_segment_count() -> int:
	return segments.size()

func get_total_glyph_count() -> int:
	var count: int = 0
	for segment in segments:
		count += segment.get_glyph_count()
	return count

func set_position_with_y_offset(x_align: int, y_offset: float) -> void:
	var y_pos = (y_offset + max_ascent) + line_offset.y
	position = Vector2(0, y_pos)
