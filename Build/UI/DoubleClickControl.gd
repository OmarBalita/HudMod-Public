class_name DoubleClickControl extends FocusControl

signal clicked()

enum ButtonIndeces {MOUSE_BUTTON_LEFT = 1, MOUSE_BUTTON_RIGHT = 2, MOUSE_BUTTON_MIDDLE = 3}

@export var button_index: ButtonIndeces = 1
@export var double_click_threshold: float = 0.3

var last_click_time: float = 0.0

func _gui_input(event: InputEvent) -> void:
	
	super(event)
	
	if is_focus and event is InputEventMouseButton:
		if event.button_index == button_index and event.pressed:
			var current_time = Time.get_ticks_msec() / 1000.0
			if current_time - last_click_time < double_click_threshold:
				_double_click()
			last_click_time = current_time

func _double_click() -> void:
	clicked.emit()

