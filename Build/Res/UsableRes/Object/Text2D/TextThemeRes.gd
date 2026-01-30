class_name TextThemeRes extends UsableRes

enum FontVariationEnum {
	REGULAR,
	BOLD,
	ITALIC,
	BOLD_ITALIC
}

@export_group("Font")
@export var font: FontVariation = FontVariation.new()

@export var load_font_from_path: bool = true
@export var font_path: String
@export var built_in_font: FontRes = FontRes.new()
@export var font_size: int = 48
@export var font_color: Color = Color.WHITE
@export var font_variation: FontVariationEnum = 0

@export_group("Outline")
@export var outline_size: int = 0
@export var outline_color: Color = Color.WHITE
@export_subgroup("Multi Outlines")
@export var outlines: Array = []

@export_group("Shadow")
@export var shadow_size: int = 0
@export var shadow_spread: int = 4
@export var shadow_color: Color = Color(Color.BLACK, .5)
@export var shadow_offset: Vector2 = Vector2.ZERO

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var is_load_from_file_func: Callable = get.bind(&"load_font_from_path")
	return {
		&"Font": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"load_font_from_path": export(bool_args(load_font_from_path)),
		&"font_path": export(string_args(font_path, IS.StringControllerType.TYPE_OPEN_FILE, ["ttf", "otf", "ttc", "otc", "woff", "woff2"], "Open Font File"), [is_load_from_file_func, [true]]),
		&"built_in_font": export([built_in_font], [is_load_from_file_func, [false]]),
		&"font_size": export(int_args(font_size, 1, 999)),
		&"font_color": export(color_args(font_color)),
		&"font_variation": export(options_args(font_variation, FontVariationEnum)),
		&"_Font": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Outline": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"outline_size": export(int_args(outline_size, 0, 999)),
		&"outline_color": export(color_args(outline_color)),
		&"outlines": export(list_args(outlines, &"TextOutlineRes")),
		&"_Outline": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Shadow": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"shadow_size": export(int_args(shadow_size, 0, 50)),
		&"shadow_spread": export(int_args(shadow_spread, 1, 50)),
		&"shadow_color": export(color_args(shadow_color)),
		&"shadow_offset": export(vec2_args(shadow_offset)),
		&"_Shadow": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	}


