class_name CompDrawStar extends DrawShapeComponentRes

@export var heads: int = 5:
	set(val): heads = val; max_dirty()
@export var length: float = 100.:
	set(val): length = val; max_dirty()
@export var inner_length: float = 50.:
	set(val): inner_length = val; max_dirty()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return super().merged({
		&"heads": export(int_args(heads, 2, 1024)),
		&"length": export(float_args(length, 0, INF, .01, .5)),
		&"inner_length": export(float_args(inner_length, 0, INF, .01, .5))
	})

func _gen_points() -> Array[PackedVector2Array]:
	var star: PackedVector2Array
	
	var edges: int = heads * 2
	var x_step: float = PI / edges * 2.
	
	for head: int in edges + 1:
		var radius: float = length if head % 2 == 0 else inner_length
		var x: float = head * x_step
		star.append(Vector2(sin(x), cos(x)) * radius)
	
	return [star]

