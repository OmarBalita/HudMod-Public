class_name LineData extends UsableRes

enum LineAlignment {
	NONE = -1,
	LEFT,
	CENTER,
	RIGHT
}

@export var line_align: LineAlignment = LineAlignment.NONE
@export var line_offset: Vector2 = Vector2.ONE

var line_text: String
var segments: Array[TextSegmentRes]

var max_height: float
var max_ascent: float
var max_descent: float
var total_width: float

var position: Vector2

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"line_align": export(options_args(line_align, LineAlignment)),
		&"line_offset": export(vec2_args(line_offset))
	}

func calculate_total_width() -> float:
	var result: float = 0.0
	for segment: TextSegmentRes in segments:
		result += segment.width
	total_width = result
	return result

func calculate_x_offset(align: int = -1) -> float:
	var alignment: int = align if line_align == LineAlignment.NONE else line_align
	var width: float = calculate_total_width()
	
	match alignment:
		LineAlignment.LEFT: return .0
		LineAlignment.CENTER: return -width / 2.0
		LineAlignment.RIGHT: return -width
		_: return .0

func update_metrics() -> void:
	max_height = 0.0
	max_ascent = 0.0
	max_descent = 0.0
	for segment: TextSegmentRes in segments:
		update_metrics_with(segment)

func update_metrics_with(segment: TextSegmentRes) -> void:
	max_height = max(max_height, segment.height)
	max_ascent = max(max_ascent, segment.max_ascent)
	max_descent = max(max_descent, segment.max_descent)

func add_segment(segment: TextSegmentRes) -> void:
	segments.append(segment)
	update_metrics_with(segment)

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
