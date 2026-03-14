class_name DrawShapeChild extends DrawShapeNode

var draw_shape_comp: DrawShapeComponentRes

func _draw() -> void:
	draw_shape(draw_shape_comp)
