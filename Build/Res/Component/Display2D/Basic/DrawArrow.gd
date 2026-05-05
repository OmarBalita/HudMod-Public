#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompDrawArrow extends DrawShapeComponentRes

@export var width: float = 50.:
	set(val): width = val; max_dirty()
@export var from: Vector2 = Vector2(-100., .0):
	set(val): from = val; max_dirty()
@export var to: Vector2 = Vector2(100., .0):
	set(val): to = val; max_dirty()

@export_group("Arrow", "arrow")
@export var arrow_from: bool = true:
	set(val): arrow_from = val; max_dirty()
@export var arrow_to: bool = true:
	set(val): arrow_to = val; max_dirty()
@export var arrow_width: float = 20.:
	set(val): arrow_width = val; max_dirty()
@export var arrow_length: float = 40.:
	set(val): arrow_length = val; max_dirty()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return super().merged({
		&"width": export(float_args(width)),
		&"from": export(vec2_args(from)),
		&"to": export(vec2_args(to)),
		
		&"Arrow": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"arrow_from": export(bool_args(arrow_from)),
		&"arrow_to": export(bool_args(arrow_to)),
		&"arrow_width": export(float_args(arrow_width)),
		&"arrow_length": export(float_args(arrow_length)),
		&"_Arrow": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	})

func _gen_points() -> Array[PackedVector2Array]:
	var arrow: PackedVector2Array
	
	var dir: Vector2 = (to - from).normalized()
	var normal: Vector2 = Vector2(-dir.y, dir.x)
	
	var width_h: Vector2 = normal * (width / 2.)
	
	var a: Vector2 = from + width_h
	var b: Vector2 = to + width_h
	var c: Vector2 = to - width_h
	var d: Vector2 = from - width_h
	
	var wing: Vector2 = width_h + normal * arrow_width
	var head: Vector2 = dir * arrow_length
	
	arrow.append(d)
	
	if arrow_from:
		arrow.append(from - wing)
		arrow.append(from - head)
		arrow.append(from + wing)
	
	arrow.append(a)
	arrow.append(b)
	
	if arrow_to:
		arrow.append(to + wing)
		arrow.append(to + head)
		arrow.append(to - wing)
	
	arrow.append(c)
	arrow.append(d)
	
	return [arrow]

