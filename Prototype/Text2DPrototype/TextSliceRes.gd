class_name TextSliceRes extends Resource

signal text_slice_property_changed()

@export var start_char_index: int = 0

@export_group("Text")
@export_enum("Left", "Center", "Right") var text_align: int = 0:
	set(val):
		text_align = val
		text_slice_property_changed.emit()

@export_group("Font")
@export var font: Font:
	set(val):
		font = val
		text_slice_property_changed.emit()
@export var font_size: int = 16:
	set(val):
		font_size = val
		text_slice_property_changed.emit()

@export_enum("Regular", "Bold", "Italic", "Bold Italic") var font_variation: int = 0:
	set(val):
		font_variation = val
		text_slice_property_changed.emit()

@export var font_color: Color = Color.WHITE:
	set(val):
		font_color = val
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
