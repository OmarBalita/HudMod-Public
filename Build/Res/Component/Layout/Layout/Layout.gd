class_name CompLayout extends ComponentRes

enum LayoutDirection {
	INHERITED,
	BASED_ON_APPLICATION_LOCALE,
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT,
	BASED_ON_SYSTEM_LOCALE
}

enum Anchor {
	POSITION,
	ANCHORS
}

enum LayoutPreset {
	PRESET_TOP_LEFT,
	PRESET_TOP_RIGHT,
	PRESET_BOTTOM_LEFT,
	PRESET_BOTTOM_RIGHT,
	PRESET_CENTER_LEFT,
	PRESET_CENTER_TOP,
	PRESET_CENTER_RIGHT,
	PRESET_CENTER_BOTTOM,
	PRESET_CENTER,
	PRESET_LEFT_WIDE,
	PRESET_RIGHT_WIDE,
	PRESET_BOTTOM_WIDE,
	PRESET_VCENTER_WIDE,
	PRESET_HCENTER_WIDE,
	PRESET_FULL_RECT
}

@export var clip_contents: bool
@export var custom_minimum_size: Vector2
@export var layout_direction: LayoutDirection
@export var layout_mode: Anchor
@export var anchors_preset: LayoutPreset
@export var position: Vector2 = Vector2(-200., -200.)
@export var size: Vector2 = Vector2(400., 400.)
@export var rotation: float
@export var scale: Vector2 = Vector2.ONE
@export var pivot_offset: Vector2
@export var pivot_offset_ratio: Vector2 = Vector2(.5, .5)

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"clip_contents": export(bool_args(clip_contents)),
		&"custom_minimum_size": export(vec2_args(custom_minimum_size)),
		&"layout_direction": export(options_args(layout_direction, LayoutDirection)),
		&"layout_mode": export(options_args(layout_mode, Anchor)),
		&"anchors_preset": export(options_args(anchors_preset, LayoutPreset)),
		&"Transform": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"position": export(vec2_args(position)),
		&"size": export(vec2_args(size)),
		&"rotation": export(float_args(rotation)),
		&"scale": export(vec2_args(scale)),
		&"pivot_offset": export(vec2_args(pivot_offset)),
		&"pivot_offset_ratio": export(vec2_args(pivot_offset_ratio)),
		&"_Transform": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	}

func _process(frame: int) -> void:
	submit_stacked_values({
		&"clip_contents": clip_contents,
		&"custom_minimum_size": custom_minimum_size,
		&"layout_direction": layout_direction,
		&"layout_mode": layout_mode,
		&"anchors_preset": anchors_preset,
		&"position": position,
		&"size": size,
		&"rotation_degrees": rotation,
		&"scale": scale,
		&"pivot_offset": pivot_offset,
		&"pivot_offset_ratio": pivot_offset_ratio
	})

