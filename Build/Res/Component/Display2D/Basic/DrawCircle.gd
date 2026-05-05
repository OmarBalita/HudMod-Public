#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompDrawCircle extends DrawShapeComponentRes

@export var from: float = .0:
	set(val): from = val; max_dirty()

@export var to: float = snapped(PI * 2., .001):
	set(val): to = val; max_dirty()

@export var hole_radius: float = 50.:
	set(val): hole_radius = val; max_dirty()

@export var radius: float = 100.:
	set(val): radius = val; max_dirty()

@export_range(.001, .4, .001) var step: float = .1:
	set(val): step = val; max_dirty()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return super().merged({
		&"from": export(float_args(from, -INF, INF, .01, .01, PI / 4.)),
		&"to": export(float_args(to, -INF, INF, .01, .01, PI / 4.)),
		&"hole_radius": export(float_args(hole_radius, -INF, INF, .01, .5)),
		&"radius": export(float_args(radius, -INF, INF, .01, .5)),
		&"step": export(float_args(step, .001, .4, .001))
	})

func _gen_points() -> Array[PackedVector2Array]:
	var circle: PackedVector2Array
	if from > to: return [circle]
	
	var x: float = from
	
	var start: Vector2 = Vector2(sin(x), cos(x))
	var end: Vector2 = Vector2(sin(to), cos(to))
	var start_at_end: bool = abs(to - (from + PI * 2.)) < .01
	
	while x < to:
		circle.append(Vector2(sin(x), cos(x)) * radius)
		x += step
	
	circle.append(end * radius)
	
	x = to
	
	while x > from:
		circle.append(Vector2(sin(x), cos(x)) * hole_radius)
		x -= step
	
	circle.append(start * hole_radius)
	if not start_at_end:
		circle.append(start * radius)
	
	return [circle]

