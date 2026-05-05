#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompDrawRect extends DrawShapeComponentRes

@export var size: Vector2 = Vector2(100., 100.):
	set(val): size = val; max_dirty()
@export_range(.0, 1.) var corner_scale: float:
	set(val): corner_scale = val; max_dirty()
@export_range(1, 32) var corner_details: int = 12:
	set(val): corner_details = val; max_dirty()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return super().merged({
		&"size": export(vec2_args(size)),
		&"corner_scale": export(float_args(corner_scale, .0, 1., .001)),
		&"corner_details": export(int_args(corner_details, 1, 32))
	})

func _gen_points() -> Array[PackedVector2Array]:
	
	var _corner_scale: float = min(.99, corner_scale)
	
	var min_size: float = min(size.x, size.y)
	var corner_offset: Vector2 = Vector2(min_size, min_size) * _corner_scale
	var corner_left: Vector2 = size - corner_offset
	
	var x_step: float = PI / corner_details / 2.
	
	var q1: int = corner_details
	var q2: int = corner_details * 2
	var q3: int = corner_details * 3
	var q4: int = corner_details * 4
	
	var offset2:= Vector2(corner_left.x, -corner_left.y)
	var offset4:= Vector2(-corner_left.x, corner_left.y)
	
	var rect: PackedVector2Array
	
	if _corner_scale:
		
		for time: int in range(q2, q3 + 1):
			var x: float = time * x_step
			var point: Vector2 = Vector2(cos(x), sin(x)) * corner_offset - corner_left
			rect.append(point)
		
		for time: int in range(q3, q4 + 1):
			var x: float = time * x_step
			var point: Vector2 = Vector2(cos(x), sin(x)) * corner_offset + offset2
			rect.append(point)
		
		for time: int in q1 + 1:
			var x: float = time * x_step
			var point: Vector2 = Vector2(cos(x), sin(x)) * corner_offset + corner_left
			rect.append(point)
		
		for time: int in range(q1, q2 + 1):
			var x: float = time * x_step
			var point: Vector2 = Vector2(cos(x), sin(x)) * corner_offset + offset4
			rect.append(point)
		
		var end_point:= Vector2(.0, corner_offset.y) - size
		rect.append(end_point)
		if not corner_scale:
			end_point.x += .01
			rect.append(end_point)
	
	else:
		rect = PackedVector2Array([
			-size,
			Vector2(size.x, -size.y),
			size,
			Vector2(-size.x, size.y),
			-size
		])
	
	return [rect]
