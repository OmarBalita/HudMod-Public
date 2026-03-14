class_name CompSwing extends InOutComponentRes

func _inout(frame: int) -> void:
	submit_stacked_value(&"rotation_degrees", (1. - t_ratio) * 180.)
