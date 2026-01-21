class_name TextSegmentRes extends Resource

@export var theme: TextThemeRes

@export var width: float
@export var height: float

@export var max_ascent: float
@export var max_descent: float

var glyphs: Array[Dictionary]
var chars_data: Array[CharacterData]

func calculate_width() -> float:
	var total: float = 0.0
	for glyph: Dictionary in glyphs:
		total += glyph.advance
	return total

func add_glyph(glyph: Dictionary) -> void:
	glyphs.append(glyph.duplicate())
	width += glyph.advance

func update_metrics_from_font() -> void:
	if theme != null and theme.font != null:
		var font_size: int = theme.font_size
		height = theme.font.get_height(font_size)
		max_ascent = theme.font.get_ascent(font_size)
		max_descent = theme.font.get_descent(font_size)

func is_empty() -> bool:
	return glyphs.is_empty()

func get_glyph_count() -> int:
	return glyphs.size()
