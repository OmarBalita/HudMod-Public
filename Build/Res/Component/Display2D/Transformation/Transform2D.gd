class_name CompTransform2D extends ComponentRes

@export var position: Vector2
@export var rotation_degrees: float
@export var scale: Vector2 = Vector2.ONE
@export var skew: float

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"position": export(vec2_args(position)),
		&"rotation_degrees": export(float_args(rotation_degrees)),
		&"scale": export(vec2_args(scale)),
		&"skew": export(float_args(skew))
	}

func _process(frame: int) -> void:
	submit_stacked_value(&"position", position)
	submit_stacked_value(&"rotation_degrees", rotation_degrees)
	submit_stacked_value(&"scale", scale)
	submit_stacked_value(&"skew", skew)

func _apply_custom_stacked_values(frame: int, dict: Dictionary[StringName, Array]) -> void:
	apply_stacked_value(dict, &"position", sample_or_get(self, &"position", frame))
	apply_stacked_value(dict, &"rotation_degrees", sample_or_get(self, &"rotation_degrees", frame))
	apply_stacked_value(dict, &"scale", sample_or_get(self, &"scale", frame))

