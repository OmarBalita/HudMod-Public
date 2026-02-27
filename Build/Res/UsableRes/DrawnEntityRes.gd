class_name DrawnEntityRes extends UsableRes

enum EntityTypes {
	LINE,
	DASH_LINE,
	RECT,
	CIRCLE,
	ARC,
	MESH,
	TEXTURE
}

enum DistMode {
	POINTS_DIST,
	CONST_DIST
}

@export var type: EntityTypes

@export var offset: Vector2
@export var distance_mode: DistMode
@export_range(1, 10e10) var distance: int = 1
@export_range(.0, 1.0) var from: float = .0
@export_range(.0, 1.0) var to: float = 1.0

@export var use_custom: bool
@export_range(.0, 1e6) var custom_width: float = 5.0
@export var custom_color: Color = Color.WHITE
@export var custom_antialized: bool = true

@export var dash_scale: float = 2.0

@export var filled: bool = true
@export var width_scale: float = 1.0

@export var rect_size: Vector2 = Vector2.ONE

@export var circle_radius: float = 3.0

@export var arc_start_angle: float = .0
@export var arc_end_angle: float = TAU
@export var arc_points_count: int = 8

#@export var mesh: Mesh

@export var position: Vector2
@export var rotation: float
@export var scale: Vector2
@export var skew: float

#func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	#var custom_cond = CtrlrHelper.get_ui_cond(get_use_custom, [true])
	#return {
		#"type": CtrlrHelper.get_option_controller_args([], EntityTypes.keys(), type),
		#
		#"offset": CtrlrHelper.get_vec2_controller_args([], offset),
		#"distance_mode": CtrlrHelper.get_option_controller_args([], DistMode.keys(), distance_mode),
		#"distance": CtrlrHelper.get_float_controller_args([], true, distance),
		#"from": CtrlrHelper.get_float_controller_args([], false, from),
		#"to": CtrlrHelper.get_float_controller_args([], false, to),
		#
		#"use_custom": CtrlrHelper.get_bool_controller_args([], use_custom),
		#"custom_width": CtrlrHelper.get_float_controller_args([get_use_custom, [true]], custom_width),
		#"custom_color": CtrlrHelper.get_color_controller_args([get_use_custom, [true]], custom_color),
		#"custom_antialized": CtrlrHelper.get_bool_controller_args([get_use_custom, [true]], custom_antialized),
		#
		#"dash_scale": CtrlrHelper.get_float_controller_args([get_type, [1]], false, dash_scale),
		#
		#"filled": CtrlrHelper.get_bool_controller_args([get_type, [2, 3]], filled),
		#"width_scale": CtrlrHelper.get_float_controller_args([get_type, [2, 3, 4]], false, width_scale),
		#
		#"rect_size": CtrlrHelper.get_vec2_controller_args([get_type, [2]], rect_size),
		#
		#"circle_radius": CtrlrHelper.get_float_controller_args([get_type, [3]], false, circle_radius),
		#
		#"arc_start_angle": CtrlrHelper.get_float_controller_args([get_type, [4]], false, arc_start_angle),
		#"arc_end_angle": CtrlrHelper.get_float_controller_args([get_type, [4]], false, arc_end_angle),
		#"arc_points_count": CtrlrHelper.get_float_controller_args([get_type, [4]], true, arc_points_count),
		#
		#"texture": CtrlrHelper.get_res_controller_args([get_type, [6]], texture),
		#"position": CtrlrHelper.get_vec2_controller_args([get_type, [6]], position),
		#"rotation": CtrlrHelper.get_float_controller_args([get_type, [6]], false, rotation),
		#"scale": CtrlrHelper.get_vec2_controller_args([get_type, [6]], scale),
		#"skew": CtrlrHelper.get_float_controller_args([get_type, [6]], false, skew)
	#}


func get_type() -> int:
	return type

func set_type(new_type: int) -> void:
	type = new_type

func get_use_custom() -> bool:
	return use_custom

func set_use_custom(new_use_custom: bool) -> void:
	use_custom = new_use_custom









