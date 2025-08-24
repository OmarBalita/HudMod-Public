class_name CurveControl extends PanelContainer


func _ready() -> void:
	var margin = InterfaceServer.create_margin_container()
	var box = InterfaceServer.create_box_container()
	
	var preset_options = InterfaceServer.create_option_controller([
		{text = "Linear"},
		{text = "Constant"},
		{text = "Ease In"},
		{text = "Ease Out"},
		{text = "Smoothstep"}
	], "")
	var curve_controller = CurveController.new()
	InterfaceServer.expand(curve_controller)
	
	box.add_child(curve_controller)
	
	margin.add_child(box)
	add_child(margin)

