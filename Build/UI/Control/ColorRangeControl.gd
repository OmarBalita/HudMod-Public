class_name ColorRangeControl extends PanelContainer

signal val_changed()

var color_range_controller: ColorRangeController = ColorRangeController.new()
var xpos_edit: FloatController
var color_edit: ColorButton


func _ready() -> void:
	
	var margin = IS.create_margin_container()
	var box = IS.create_box_container(16, true)
	
	color_range_controller.custom_minimum_size.y = 20.0
	
	xpos_edit = IS.create_float_edit("Key Position", false, true, .0, .0, 1.0, .001)[1]
	color_edit = IS.create_color_edit("Key Color", Color.BLACK)[0]
	
	color_range_controller.selected_key_changed.connect(on_selected_key_changed)
	xpos_edit.val_changed.connect(on_xpos_edit_val_changed)
	color_edit.color_changed.connect(on_color_edit_val_changed)
	
	box.add_child(color_range_controller)
	box.add_child(xpos_edit.get_parent())
	box.add_child(color_edit.get_parent())
	
	margin.add_child(box)
	add_child(margin)


func _update_ui(x_pos: float, color: Color) -> void:
	var is_key_available = x_pos != null
	if is_key_available:
		xpos_edit.set_curr_val(x_pos, false)
		color_edit.set_curr_color(color, false)
	xpos_edit.visible = is_key_available
	color_edit.visible = is_key_available

func on_selected_key_changed(x_pos: float, color: Color) -> void:
	_update_ui(x_pos, color)
	val_changed.emit()

func on_xpos_edit_val_changed(new_pos: float) -> void:
	color_range_controller.move_selected_key(new_pos)
	val_changed.emit()

func on_color_edit_val_changed(new_color: Color) -> void:
	var color_range_res = color_range_controller.color_range_res
	color_range_res.update_key_color(color_range_controller.selected_key, new_color)
	val_changed.emit()







class ColorRangeController extends FocusControl:
	
	signal keys_changed()
	signal selected_key_changed(new_selected_key: Variant, color: Color)
	
	@export var color_range_res: ColorRangeRes:
		set(val):
			if color_range_res: color_range_res.color_range_changed.disconnect(_on_color_range_changed)
			if val: val.color_range_changed.connect(_on_color_range_changed)
			color_range_res = val
	
	var key_button_size: Vector2 = Vector2(20, 15)
	var selected_key: float:
		set(val):
			if val <= .0:
				val = color_range_res.keys.keys()[0]
			
			selected_key = val
			var selected_color: Color
			if selected_key != null:
				selected_color = color_range_res.get_key_color(selected_key)
			selected_key_changed.emit(selected_key, selected_color)
			queue_redraw()
	
	var is_dragged: bool
	
	
	func _ready():
		super()
		
		if not color_range_res:
			color_range_res = ColorRangeRes.new()
			color_range_res.add_key(0.0, Color.WHITE)
			color_range_res.add_key(1.0, Color.BLACK)
		selected_key = -1
	
	func _draw() -> void:
		draw_gradient()
		draw_color_keys()
		super()
	
	func _input(event: InputEvent) -> void:
		super(event)
		
		if event is InputEventMouse:
			var mouse_pos = get_local_mouse_position()
			var x_pos = get_xpos_from_display_pos(mouse_pos.x)
			var keys = color_range_res.get_keys()
			
			var rounded_keys = color_range_res.get_custom_keys(
				func(x_pos: float, color: Color) -> bool:
					var dist = abs(get_display_pos_from_xpos(x_pos) - mouse_pos.x)
					return dist <= key_button_size.x
			)
			
			var is_pressed = event.is_pressed()
			
			if event is InputEventMouseButton:
				
				match event.button_index:
					
					MOUSE_BUTTON_LEFT:
						
						if is_focus and is_pressed:
							
							if rounded_keys.size():
								selected_key = rounded_keys.keys()[0]
							else:
								add_key(x_pos)
							is_dragged = true
						
						else:
							is_dragged = false
					
					MOUSE_BUTTON_RIGHT:
						if is_focus and is_pressed:
							if rounded_keys:
								remove_key(rounded_keys.keys()[0])
			
			elif event is InputEventMouseMotion:
				if is_dragged:
					move_selected_key(x_pos)
	
	
	func get_color_range_res() -> ColorRangeRes:
		return color_range_res
	
	func set_color_range_res(new_color_range_res: ColorRangeRes) -> void:
		color_range_res = new_color_range_res
	
	func add_key(x_pos: float) -> void:
		var new_color = color_range_res.sample(x_pos)
		color_range_res.add_key(x_pos, new_color)
		selected_key = x_pos
		keys_changed.emit()
	
	func remove_key(x_pos: float) -> void:
		color_range_res.remove_key(x_pos)
		selected_key = -1
		keys_changed.emit()
	
	func move_selected_key(to_xpos: float) -> void:
		var key = color_range_res.move_key(selected_key, to_xpos)
		if key.size():
			selected_key = key.keys()[0]
		keys_changed.emit()
	
	
	func draw_gradient():
		var keys = color_range_res.get_keys()
		if keys.size() < 2: return
		
		var segments = 100
		var segment_width = size.x / segments
		
		for index: int in range(segments):
			var x = float(index) / float(segments - 1)
			var color = color_range_res.sample(x)
			
			var segment_rect = Rect2(
				Vector2(index * segment_width, 0),
				Vector2(segment_width + 1, size.y)
			)
			
			draw_rect(segment_rect, color)
	
	func draw_color_keys():
		var keys = color_range_res.get_keys()
		
		for x_pos in keys.keys():
			var color = keys[x_pos]
			
			var x = get_display_pos_from_xpos(x_pos)
			var y = size.y - 1
			
			var key_rect = Rect2(
				Vector2(x - key_button_size.x / 2, y),
				key_button_size
			)
			
			var outline_color = Color.BLACK
			if selected_key == x_pos:
				outline_color = Color.WHITE
			
			draw_rect(key_rect.grow(1.0), outline_color)
			draw_rect(key_rect.grow(-1.0), color)
			
			var triangle_height = 10
			var half_width = key_button_size.x / 2
			
			var triangle_points = PackedVector2Array([
				Vector2(x, y - triangle_height),
				Vector2(x - half_width, y),
				Vector2(x + half_width, y)
			])
			
			draw_dashed_line(Vector2(x, y), Vector2(x, 0), Color.DIM_GRAY, 1.0, 5.0, true)
			draw_colored_polygon(triangle_points, Color.DIM_GRAY)
			draw_polyline(triangle_points, Color.BLACK, 1)
	
	
	func get_display_pos_from_xpos(x_pos: float) -> float:
		return x_pos * size.x
	
	func get_xpos_from_display_pos(display_pos: float) -> float:
		return clamp(display_pos / size.x, .0, 1.0)
	
	
	func _on_color_range_changed():
		queue_redraw()










