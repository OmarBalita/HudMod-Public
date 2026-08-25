class_name ColorWheelController extends BoxContainer

signal val_changed(new_color: Color)

var curr_color: Color = Color(.5, .5, .5)

var color_shape: WheelColorShape
var luminance_slider: SliderController

func _init() -> void:
	vertical = true
	add_theme_constant_override(&"separation", 6)
	IS.expand(self, true, true)
	
	color_shape = WheelColorShape.new(curr_color.h, curr_color.s, curr_color.v)
	color_shape.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_shape.size_flags_vertical = Control.SIZE_EXPAND_FILL
	color_shape.custom_minimum_size = Vector2(100, 100)
	
	luminance_slider = IS.create_slider_controller(curr_color.v, 0.0, 1.0, 0.0, 0.0)
	
	color_shape.val_changed.connect(_on_color_shape_val_changed)
	luminance_slider.val_changed.connect(_on_luminance_slider_val_changed)
	
	add_child(color_shape)
	add_child(luminance_slider)

func set_curr_color(new_color: Color) -> void:
	curr_color = new_color
	color_shape.update(new_color.h, new_color.s, new_color.v)
	luminance_slider.set_curr_val_manually(new_color.v)
	
	val_changed.emit(new_color)

func set_curr_color_manually(new_color: Color) -> void:
	set_curr_color(new_color)

func _on_color_shape_val_changed(new_hue: float, new_sat: float) -> void:
	var color: Color = curr_color
	color.h = new_hue
	color.s = new_sat
	set_curr_color(color)

func _on_luminance_slider_val_changed(new_val: float) -> void:
	set_curr_color(Color.from_hsv(curr_color.h, curr_color.s, new_val, curr_color.a))

class WheelColorShape extends Control:
	
	signal val_changed(new_hue: float, new_sat: float)
	
	const DRAG_SENSITIVITY: float = 0.35
	const SNAP_ANGLE_DEG: float = 7.0
	const SNAP_CENTER_PX: float = 4.0
	
	@export var radius: float = 120.0:
		set(val):
			radius = val
			update_properties()
			queue_redraw()
		get:
			return min(size.x, size.y) / 2.0
	
	var hue: float
	var sat: float
	var val: float
	
	var dragged: bool
	var is_snapped: bool = false
	
	var drag_point: Vector2
	var last_mouse_pos: Vector2
	
	var circle_texture: Texture2D = preload("res://Asset/Icons/vhs-circle-shape.png")
	
	func _init(_hue: float, _sat: float, _val: float) -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		update(_hue, _sat, _val)
		resized.connect(queue_redraw)
	
	func _ready() -> void:
		update_properties()
	
	func _gui_input(event: InputEvent) -> void:
		if event is InputEvent:
			var mouse_pos: Vector2 = get_local_mouse_position()
			
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT:
					var dist_to_center: float = (mouse_pos - size / 2.).length()
					if event.is_pressed():
						if dist_to_center <= radius:
							dragged = true
							last_mouse_pos = mouse_pos
							var center: Vector2 = size / 2.
							var angle_rad: float = hue * TAU
							drag_point = center + Vector2(cos(angle_rad), sin(angle_rad)) * sat * radius
						else: dragged = false
					else: dragged = false
			
			elif event is InputEventMouseMotion:
				if dragged:
					var delta: Vector2 = mouse_pos - last_mouse_pos
					last_mouse_pos = mouse_pos
					drag_point += delta * DRAG_SENSITIVITY
					update_from_display_point(drag_point)
					val_changed.emit(hue, sat)
	
	func _draw() -> void:
		var center: Vector2 = size / 2.
		var texture_size: Vector2 = Vector2.ONE * radius * 2.
		var texture_pos: Vector2 = center - texture_size / 2.
		
		draw_texture_rect(circle_texture, Rect2(texture_pos, texture_size), false, Color(val, val, val, 1.0))
		
		var inner_radius: float = radius * 0.83
		
		var hole_bg := Color(0.05, 0.05, 0.07, 0.6)
		draw_arc(center, inner_radius / 2.0, 0.0, TAU, 64, hole_bg, inner_radius, true)
		
		var grid_color := Color(1.0, 1.0, 1.0, 0.3)
		var line_len: float = inner_radius * 0.9
		
		draw_line(center - Vector2(line_len, 0), center + Vector2(line_len, 0), grid_color, 2.0, true)
		draw_line(center - Vector2(0, line_len), center + Vector2(0, line_len), grid_color, 2.0, true)
		
		draw_circle(center, 2.5, grid_color)
		
		var angle_rad: float = hue * TAU
		var display_offset: Vector2 = Vector2(cos(angle_rad), sin(angle_rad)) * sat * radius
		var handle_pos: Vector2 = center + display_offset
		
		draw_arc(handle_pos, 6.0, 0.0, TAU, 32, Color(1, 1, 1, .7) if is_snapped else Color.WHITE, 2.0, true)
	
	func update_properties() -> void:
		custom_minimum_size = Vector2.ONE * radius * 2.0
	
	func update(_hue: float, _sat: float, _val: float) -> void:
		hue = _hue
		sat = _sat
		val = _val
		queue_redraw()

	func update_from_display_point(point = null) -> void:
		
		if point == null:
			point = get_local_mouse_position()
		
		var center: Vector2 = size / 2.
		var offset: Vector2 = point - center
		var dist: float = offset.length()
		
		is_snapped = false
		
		if dist <= SNAP_CENTER_PX:
			sat = 0.0
			is_snapped = true
			queue_redraw()
			return
		
		var angle: float = atan2(offset.y, offset.x)
		
		if angle < .0:
			angle += TAU
		
		var snap_range: float = deg_to_rad(SNAP_ANGLE_DEG)
		for cardinal in [0.0, PI / 2.0, PI, 3.0 * PI / 2.0, TAU]:
			if abs(angle - cardinal) <= snap_range:
				angle = fmod(cardinal, TAU)
				is_snapped = true
				break
		
		hue = angle / TAU
		sat = clamp(dist / radius, .0, 1.)
		
		queue_redraw()
