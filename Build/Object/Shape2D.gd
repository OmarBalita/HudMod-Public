class_name Shape2DObject extends DrawShapeNode

var draw_shape_comps: Array[DrawShapeComponentRes]

func _draw() -> void:
	for comp: DrawShapeComponentRes in draw_shape_comps:
		draw_shape(comp)
