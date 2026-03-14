class_name CompSlide extends InOutComponentRes

@export var slide_dist: float = 50.
@export var direction: float = .0

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return super().merged({
		&"slide_dist": export(float_args(slide_dist)),
		&"direction": export(float_args(direction, -INF, INF, .01, 1.))
	})

func _inout(frame: int) -> void:
	var offset: float = (1. - t_ratio) * slide_dist
	var dir_rad: float = deg_to_rad(direction)
	submit_stacked_value(&"position", Vector2(cos(dir_rad), sin(dir_rad)) * offset)
