class_name TextSliceRes extends UsableRes

signal text_slice_property_changed()

@export var start_char_index: int = 0:
	set(val):
		start_char_index = val
		text_slice_property_changed.emit()

@export_group("Font")
@export var font: FontVariation = FontVariation.new():
	set(val):
		font = val
		text_slice_property_changed.emit()

@export var font_size: int = 16:
	set(val):
		font_size = val
		text_slice_property_changed.emit()

@export var font_color: Color = Color.WHITE:
	set(val):
		font_color = val
		text_slice_property_changed.emit()

@export_enum("Regular", "Bold", "Italic", "Bold Italic") var font_variation: int = 0:
	set(val):
		font_variation = val
		text_slice_property_changed.emit()

@export_group("Outline")
@export var outline_size: int = 0:
	set(val):
		outline_size = val
		text_slice_property_changed.emit()

@export var outline_color: Color = Color.WHITE:
	set(val):
		outline_color = val
		text_slice_property_changed.emit()

@export_subgroup("Multi Outlines")
@export var outlines: Array[TextOutlineRes] = []

@export_group("Shadow")
@export var shadow_size: int = 1:
	set(val):
		shadow_size = val
		text_slice_property_changed.emit()

@export var shadow_color: Color = Color(0, 0, 0, 0):
	set(val):
		shadow_color = val
		text_slice_property_changed.emit()

@export var shadow_offset: Vector2 = Vector2.ZERO:
	set(val):
		shadow_offset = val
		text_slice_property_changed.emit()

func _init() -> void:
	set_res_id(&"TextSliceRes")
