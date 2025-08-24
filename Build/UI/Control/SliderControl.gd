class_name SliderControl extends HBoxContainer

@export_group("Theme")
@export_subgroup("Texture", "texture")
@export var texture_left: Texture2D
@export var texture_right: Texture2D
@export_subgroup("Constants")
@export var slider_size:= Vector2(200.0, 10.0)
@export_subgroup("Color")
@export var bg_color: Color = Color.WEB_GRAY
@export var grabber_color: Color = Color.GRAY
@export var highlight_color: Color = InterfaceServer.COLOR_ACCENT_BLUE

# Nodes

var slider_controller: SliderController = SliderController.new(slider_size, bg_color, highlight_color, grabber_color)
var left_button: TextureButton
var right_button: TextureButton



func _ready() -> void:
	
	custom_minimum_size.x = 200.0
	
	# Base Settings(
	add_theme_constant_override("separation", 16)
	
	# Ready Nodes
	left_button = InterfaceServer.create_texture_button(texture_left)
	right_button = InterfaceServer.create_texture_button(texture_right)
	add_child(left_button)
	add_child(slider_controller)
	add_child(right_button)
	
	# Connections
	left_button.pressed.connect(on_left_button_pressed)
	right_button.pressed.connect(on_right_button_pressed)


class SliderController extends Control:
	
	signal grab_started()
	signal grab_finished()
	signal val_changed(new_val: float)
	
	var min_val: float = .0
	var max_val: float = 100.0
	var step: float = .1
	var curr_val: float = .0:
		set(val):
			curr_val = clamp(val, min_val, max_val)
			queue_redraw()
	
	var bg_color: Color
	var fill_color: Color
	var grabber_main_color: Color
	var grabber_main_radius: float = 10.0
	var grabber_drag_radius: float = 13.0
	
	# RealTime Variables
	var is_grab: bool:
		set(val):
			is_grab = val
			tweener.play(self, "grabber_display_color", [grabber_main_color.lightened(float(is_grab))], [.2])
			tweener.play(self, "grabber_display_radius", [grabber_drag_radius if is_grab else grabber_main_radius], [.2])
			queue_redraw()
	
	var grabber_display_color: Color = grabber_main_color
	
	var grabber_display_radius: float = grabber_main_radius:
		set(val):
			grabber_display_radius = val
			queue_redraw()
	
	var tweener:= TweenerComponent.new()
	
	func _init(_size: Vector2, _bg_color: Color, _fill_color: Color, _grabber_main_color: Color) -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		custom_minimum_size = _size
		bg_color = _bg_color
		fill_color = _fill_color
		grabber_main_color = _grabber_main_color
		grabber_display_color = grabber_main_color
	
	func _ready() -> void:
		tweener.easeType = Tween.EASE_OUT
		tweener.transType = Tween.TRANS_SPRING
		add_child(tweener)
	
	func _gui_input(event: InputEvent) -> void:
		
		if event is InputEventMouseButton:
			if event.is_pressed():
				if get_global_rect().grow(grabber_main_radius).has_point(get_global_mouse_position()):
					is_grab = true
					update_curr_val()
					grab_started.emit()
			else:
				is_grab = false
				grab_finished.emit()
		
		elif event is InputEventMouseMotion:
			if is_grab:
				update_curr_val()
	
	func _draw() -> void:
		var half_y_size = size.y / 2.0
		var grabber_display_pos = ((curr_val - min_val) / (max_val - min_val)) * size.x
		var grabber_pos = Vector2(grabber_display_pos, half_y_size)
		
		# Draw BG
		draw_rect(Rect2(Vector2.ZERO, size), bg_color)
		draw_circle(Vector2(size.x, half_y_size), half_y_size, bg_color)
		draw_rect(Rect2(Vector2.ZERO, Vector2(grabber_display_pos, size.y)), fill_color)
		draw_circle(Vector2(.0, half_y_size), half_y_size, fill_color)
		
		# Draw Grabber
		draw_circle(grabber_pos, grabber_display_radius, grabber_display_color, true, -1, true)
		if is_grab:
			draw_circle(grabber_pos, grabber_display_radius, grabber_main_color, false, 4, true)
	
	func get_curr_val() -> float:
		return curr_val
	
	func set_curr_val(new_val: float) -> void:
		curr_val = new_val
		val_changed.emit(curr_val)
	
	func set_curr_val_manually(new_val: float) -> void:
		curr_val = new_val
	
	func update_curr_val() -> void:
		var mouse_pos = get_local_mouse_position()
		var ratio = clamp(mouse_pos.x / size.x, 0.0, 1.0)
		set_curr_val(ratio * (max_val - min_val) + min_val)





func on_left_button_pressed() -> void:
	slider_controller.curr_val -= slider_controller.step

func on_right_button_pressed() -> void:
	slider_controller.curr_val += slider_controller.step























