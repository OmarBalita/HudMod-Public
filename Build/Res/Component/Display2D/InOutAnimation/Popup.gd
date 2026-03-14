class_name CompPopup extends InOutComponentRes

func _inout(frame: int) -> void:
	submit_stacked_value_with_custom_method(&"scale", t_ratio, MethodType.MULTIPLY)

