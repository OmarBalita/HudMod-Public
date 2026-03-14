@abstract class_name DrawShapeNode extends Node2D

func draw_shape(draw_shape_comp: DrawShapeComponentRes) -> void:
	if draw_shape_comp.just_store:
		return
	
	var all_points: Array[PackedVector2Array] = draw_shape_comp.all_points
	var color: Color = draw_shape_comp.color
	
	if draw_shape_comp.stroke_size:
		var stroke_width: float = draw_shape_comp.stroke_size
		var stroke_color: Color = draw_shape_comp.stroke_color
		for points: PackedVector2Array in all_points:
			draw_polyline(points, stroke_color, stroke_width, true)
	
	var colors:= PackedColorArray([color])
	for points: PackedVector2Array in all_points:
		draw_polygon(points, colors)

