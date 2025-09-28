class_name FlexGridContainer extends GridContainer

var control_size: Vector2:
	set(val):
		control_size = val
		queue_redraw()

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _draw() -> void:
	var h_count = int(size.x / (control_size.x + get_theme_constant("h_separation")))
	columns = h_count

func get_control_size() -> Vector2:
	return control_size

func set_control_size(new_control_size: Vector2) -> void:
	control_size = new_control_size
