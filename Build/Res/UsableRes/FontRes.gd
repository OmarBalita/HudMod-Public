class_name FontRes extends UsableRes

static var fonts: Dictionary[StringName, Dictionary]

@export var font: FontFile = preload("res://Asset/Fonts/Aftika-Font/Fontspring-DEMO-aftika-black.otf")

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var font_button: Button = IS.create_button("Choose Font", load("res://Asset/Icons/font-adjustment.png"), true)
	var font_label: Label = _extract_label()
	return {
		&"font_option_button": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, [font_button]),
		&"font_viewer": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, [font_label])
	}

func _extract_label() -> Label:
	var label_settings:= LabelSettings.new()
	label_settings.font = font
	label_settings.font_size = 24
	var label: Label = IS.create_label(font.get_font_name(), label_settings)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, 0)
	label.custom_minimum_size.y = 100.
	return label

func get_font() -> FontFile: return font
func set_font(new_val: FontFile) -> void: font = new_val

func apply_font(family: StringName, style: StringName) -> void:
	pass

