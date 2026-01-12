class_name TextSegmentRes extends Resource

@export var glyphs: Array[Dictionary]

@export var slice: TextSliceRes

@export var width: float
@export var height: float

@export var max_ascent: float
@export var max_descent: float

func calculate_width() -> float:
	var total: float = 0.0
	for glyph in glyphs:
		total += glyph.advance
	return total

func add_glyph(glyph: Dictionary) -> void:
	glyphs.append(glyph.duplicate())
	width += glyph.advance

func update_metrics_from_font() -> void:
	if slice != null and slice.font != null:
		var font_size: int = slice.font_size
		height = slice.font.get_height(font_size)
		max_ascent = slice.font.get_ascent(font_size)
		max_descent = slice.font.get_descent(font_size)

func is_empty() -> bool:
	return glyphs.is_empty()

func get_glyph_count() -> int:
	return glyphs.size()
