class_name CurveControl extends PanelContainer


func _ready() -> void:
	var margin = IS.create_margin_container()
	var box = IS.create_box_container()
	
	var preset_options = IS.create_option_controller([
		{text = "Linear"},
		{text = "Constant"},
		{text = "Ease In"},
		{text = "Ease Out"},
		{text = "Smoothstep"}
	], "")
	var curve_controller = CurveController.new()
	IS.expand(curve_controller)
	
	box.add_child(curve_controller)
	
	margin.add_child(box)
	add_child(margin)

