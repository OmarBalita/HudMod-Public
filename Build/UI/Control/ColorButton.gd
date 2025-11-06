class_name ColorButton extends Button

signal color_changed(color: Color)

@export_enum("Embeded", "Windowed") var color_controller_popup_type: int

var curr_color: Color

func _ready() -> void:
	pressed.connect(on_pressed)

func _draw() -> void:
	draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), curr_color)

func get_curr_color() -> Color:
	return curr_color

func set_curr_color(new_color: Color, emit_change: bool = true) -> void:
	curr_color = new_color
	if emit_change:
		color_changed.emit(curr_color)
	queue_redraw()

func set_curr_color_manually(new_color: Color) -> void:
	set_curr_color(new_color, false)

func on_pressed() -> void:
	var color_controller: PopupedColorController
	if color_controller_popup_type: color_controller = WindowManager.popup_color_controller_window(get_window(), curr_color)
	else: color_controller = IS.popup_color_controller(curr_color, self, get_window())
	color_controller.color_changed.connect(set_curr_color)






