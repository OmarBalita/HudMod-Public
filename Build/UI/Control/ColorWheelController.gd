class_name ColorWheelController extends BoxContainer

signal val_changed(new_color: Color)

var curr_color: Color = Color(.5, .5, .5)

var color_shape: ColorWheelShape
var luminance_slider: SliderController

func _ready() -> void:
	
	vertical = true
	add_theme_constant_override(&"separation", 12)
	IS.expand(self, true, true)
	
	color_shape = ColorWheelShape.new(curr_color.h, curr_color.s, curr_color.v)
	color_shape.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	color_shape.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	luminance_slider = IS.create_slider_controller(curr_color.v, .0, 1., .001, .1)
	
	color_shape.val_changed.connect(_on_color_shape_val_changed)
	luminance_slider.val_changed.connect(_on_luminance_slider_val_changed)
	
	add_child(color_shape)
	add_child(luminance_slider)
	
	set_curr_color_manually(curr_color)

func set_curr_color(new_color: Color) -> void:
	curr_color = new_color
	color_shape.update(new_color.h, new_color.s, new_color.v)
	luminance_slider.set_curr_val_manually(new_color.v)
	
	val_changed.emit(new_color)

func set_curr_color_manually(new_color: Color) -> void:
	curr_color = new_color
	color_shape.update(new_color.h, new_color.s, new_color.v)
	luminance_slider.set_curr_val_manually(new_color.v)

func _on_color_shape_val_changed(new_hue: float, new_sat: float) -> void:
	var color: Color = curr_color
	color.h = new_hue
	color.s = new_sat
	set_curr_color(color)

func _on_luminance_slider_val_changed(new_val: float) -> void:
	set_curr_color(Color.from_hsv(curr_color.h, curr_color.s, new_val, curr_color.a))

class ColorWheelShape extends Control:
	
	signal val_changed(new_hue: float, new_sat: float)
	
	const DRAG_SENSITIVITY: float = .2
	const SNAP_ANGLE_DEG: float = 7.
	const SNAP_CENTER_PX: float = 4.
	
	@export var radius: float = 120.:
		set(val):
			radius = val
			queue_redraw()
		get:
			return minf(size.x, size.y) / 2.
	
	var hue: float
	var sat: float
	var val: float
	
	var drag_event: InputEventMouseButton
	var handle_pos: Vector2
	var is_snapped: bool = false
	
	const CIRCLE_TEXTURE: Texture2D = preload("res://Asset/Icons/vhs-circle-shape.png")
	
	func _init(_hue: float, _sat: float, _val: float) -> void:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		update(_hue, _sat, _val)
		resized.connect(queue_redraw)
	
	func _ready() -> void:
		update_from_display_pos(_get_handle_display_pos())
	
	func _gui_input(event: InputEvent) -> void:
		
		if event is not InputEventMouse:
			return
		
		if event is InputEventMouseButton:
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				
				var dist_to_center: float = (event.position - size / 2.).length()
				
				handle_pos = _get_handle_display_pos()
				
				if event.is_pressed() and dist_to_center <= radius:
					drag_event = event
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
				else:
					drag_event = null
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
					Input.warp_mouse(handle_pos + global_position)
		
		elif event is InputEventMouseMotion:
			if not drag_event: return
			
			handle_pos = handle_pos + event.relative * DRAG_SENSITIVITY
			update_from_display_pos(handle_pos)
			val_changed.emit(hue, sat)
	
	func _draw() -> void:
		var center: Vector2 = size / 2.
		var texture_size: Vector2 = Vector2.ONE * radius * 2.
		var texture_pos: Vector2 = center - texture_size / 2.
		
		var inner_radius: float = radius * .8
		const INNER_BG: Color = Color(Color.BLACK, .6)
		
		draw_texture_rect(CIRCLE_TEXTURE, Rect2(texture_pos, texture_size), false, Color(val, val, val, 1.))
		draw_arc(center, inner_radius / 2., .0, TAU, 64, INNER_BG, inner_radius, true)
		
		const GRID_COLOR: Color = Color(Color.WHITE, .4)
		var line_len: float = inner_radius * .9
		
		draw_line(center - Vector2(line_len, .0), center + Vector2(line_len, .0), GRID_COLOR, 2., true)
		draw_line(center - Vector2(.0, line_len), center + Vector2(.0, line_len), GRID_COLOR, 2., true)
		
		draw_circle(center, 2.5, GRID_COLOR)
		
		var handle_pos: Vector2 = _get_handle_display_pos()
		
		draw_arc(handle_pos, 6., .0, TAU, 16, Color.WHITE if is_snapped else Color.GRAY, 2., true)
	
	
	func _get_handle_display_pos() -> Vector2:
		var center: Vector2 = size / 2.
		var angle_rad: float = hue * TAU
		return center + Vector2(cos(angle_rad), sin(angle_rad)) * sat * radius
	
	const CARDINALS: PackedFloat32Array = [.0, PI / 2., PI, 3. * PI / 2., TAU]
	
	func update(_hue: float, _sat: float, _val: float) -> void:
		hue = _hue
		sat = _sat
		val = _val
		queue_redraw()
	
	func update_from_display_pos(point: Vector2) -> void:
		
		var center: Vector2 = size / 2.
		var offset: Vector2 = point - center
		var dist: float = offset.length()
		
		is_snapped = false
		
		if dist <= SNAP_CENTER_PX:
			sat = .0
			is_snapped = true
			queue_redraw()
			return
		
		var angle: float = atan2(offset.y, offset.x)
		if angle < .0: angle += TAU
		
		var snap_range: float = deg_to_rad(SNAP_ANGLE_DEG)
		
		for cardinal: float in CARDINALS:
			if absf(angle - cardinal) <= snap_range:
				angle = fmod(cardinal, TAU)
				is_snapped = true
				break
		
		hue = angle / TAU
		sat = clamp(dist / radius, .0, 1.)
		
		queue_redraw()


