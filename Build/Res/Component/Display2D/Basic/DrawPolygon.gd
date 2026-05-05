#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompDrawPolygon extends DrawShapeComponentRes

@export_range(3, 1024) var edges: int = 7:
	set(val): edges = val; max_dirty()
@export var scale: float = 100.:
	set(val): scale = val; max_dirty()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return super().merged({
		&"edges": export(int_args(edges, 3, 1024)),
		&"scale": export(float_args(scale, -INF, INF, .01, .5)),
	})

func _gen_points() -> Array[PackedVector2Array]:
	var polygon: PackedVector2Array
	
	var x_step: float = PI / edges * 2.
	
	for idx: int in edges + 1:
		var x: float = idx * x_step
		polygon.append(Vector2(sin(x), cos(x)) * scale)
	
	return [polygon]
