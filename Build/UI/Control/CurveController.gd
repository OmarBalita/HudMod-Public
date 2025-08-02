class_name CurveController extends FocusControl

@export var keys_res: KeysRes:
	set(val):
		if keys_res: keys_res.keys_changed.disconnect(on_keys_changed)
		if val: val.keys_changed.connect(on_keys_changed)
		keys_res = val


@export_range(-10e10, 10e10) var domain: float = 1.0:
	set(val): domain = val; queue_redraw()
@export_range(-10e10, 10e10) var min_val: float = .0:
	set(val): min_val = val; queue_redraw()
@export_range(-10e10, 10e10) var max_val: float = 1.0:
	set(val): max_val = val; queue_redraw()

@export_group("Theme")
@export_subgroup("Permission")
@export var is_draw_domain: bool = true:
	set(val): is_draw_domain = val; queue_redraw()
@export var is_draw_val_range: bool = true:
	set(val): is_draw_val_range = val; queue_redraw()
@export_subgroup("Constant")
@export_range(1, 1000) var x_timemarks_dist: int = 100:
	set(val): x_timemarks_dist = val; queue_redraw()
@export_range(1, 1000) var y_timemarks_dist: int = 100:
	set(val): y_timemarks_dist = val; queue_redraw()
@export_range(1, 1000) var key_size: float = 10:
	set(val): key_size = val; queue_redraw()

var selected_keys: Array[float]
var is_selected_keys_dragged: bool
var main_selected_key_coord: Vector2




func _ready() -> void:
	super()
	if not keys_res:
		keys_res = KeysRes.new()

func _input(event: InputEvent) -> void:
	super(event)
	
	if not is_focus:
		return
	
	if event is InputEventMouse:
		
		var mouse_pos = get_local_mouse_position()
		var coord = get_coordinate_from_display_pos()
		
		if event is InputEventMouseButton:
			var is_pressed = event.is_pressed()
			var rounded_keys = keys_res.get_custom_keys(
				func(x_pos: float, info: Dictionary) -> bool:
					var is_select_dist = mouse_pos.distance_to(get_display_pos_from_coordinate(Vector2(x_pos, info.y_val))) <= key_size
					return is_select_dist
			)
			match event.button_index:
				
				MOUSE_BUTTON_LEFT:
					if is_pressed:
						if rounded_keys.size():
							select_key(rounded_keys)
						else:
							add_key(coord.x, coord.y, event.ctrl_pressed, event.alt_pressed)
					is_selected_keys_dragged = is_pressed
				
				MOUSE_BUTTON_RIGHT when is_pressed:
					pass
		
		elif event is InputEventMouseMotion:
			if is_selected_keys_dragged:
				var coord_delta = coord - main_selected_key_coord
				for x_pos: float in selected_keys:
					var y_val = keys_res.keys.get(x_pos).y_val
					var new_coord = Vector2(x_pos, y_val) + coord
					keys_res.move_key(x_pos, new_coord.x, new_coord.y)
					selected_keys.append(new_coord.x)
					selected_keys.erase(x_pos)

func _draw() -> void:
	var font = InterfaceServer.LABEL_SETTINGS_MAIN.font
	var x_timemark_length = Vector2(0, 10)
	var y_timemark_length = Vector2(10, 0)
	
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	
	var x_timemarks_times = (size.x / x_timemarks_dist) + 1
	var y_timemarks_times = (size.y / y_timemarks_dist) + 1
	
	if is_draw_domain:
		for x: int in x_timemarks_times:
			var timemark_pos = Vector2(x * x_timemarks_dist, size.y)
			var timemark_ratio = timemark_pos.x / size.x
			var curr_val = timemark_ratio * domain
			draw_line(timemark_pos, Vector2(timemark_pos.x, .0), Color.GRAY.darkened(.7))
			draw_line(timemark_pos, timemark_pos - x_timemark_length, Color.GRAY)
			draw_string(font, timemark_pos + Vector2(10, -10), "%.2f" % curr_val, 0, -1, 14, Color.GRAY)
	
	if is_draw_val_range:
		for y: int in y_timemarks_times:
			var y_pos = y * y_timemarks_dist
			var timemark_ratio = y_pos / size.y
			var curr_val = timemark_ratio * max_val
			var timemark_pos = Vector2(.0, -y_pos + size.y)
			draw_line(timemark_pos, Vector2(size.x, timemark_pos.y), Color.GRAY.darkened(.7))
			draw_line(timemark_pos, timemark_pos + y_timemark_length, Color.GRAY)
			draw_string(font, timemark_pos + Vector2(10, -10), "%.2f" % curr_val, 0, -1, 14, Color.GRAY)
	
	var keys = keys_res.get_keys()
	var key_size_v2 = Vector2.ONE * key_size
	var half_key_size = key_size_v2 / 2.0
	
	var latest_key_pos
	
	for x_pos: float in keys:
		var y_val = keys.get(x_pos).y_val
		var key_pos = get_display_pos_from_coordinate(Vector2(x_pos, y_val))
		if latest_key_pos != null:
			draw_line(latest_key_pos, key_pos, Color.GRAY, 3.0)
		draw_rect(Rect2(key_pos - half_key_size, key_size_v2), Color.RED if x_pos in selected_keys else Color.YELLOW)
		latest_key_pos = key_pos
	
	super()




func select_key(from: Dictionary[float, Dictionary]) -> void:
	var rounded_keys_keys = from.keys()
	var curr_index: int
	var can_select: bool = true
	while rounded_keys_keys[curr_index] in selected_keys:
		curr_index += 1
		if curr_index >= from.size() - 1:
			can_select = false
			break
	if can_select:
		var x_pos = rounded_keys_keys[curr_index]
		selected_keys.append(x_pos)
		main_selected_key_coord = Vector2(x_pos, from.get(x_pos).y_val)
	queue_redraw()

func add_key(x_pos: float, y_pos: float, grouping: bool, remove: bool) -> void:
	keys_res.add_key(x_pos, y_pos)
	selected_keys.append(x_pos)



func get_coordinate_from_display_pos(pos = null) -> Vector2:
	if pos == null:
		pos = get_local_mouse_position()
	var ratio = pos / size
	var coordinate = Vector2(ratio.x * domain, max_val - (ratio.y * max_val))
	return coordinate

func get_display_pos_from_coordinate(coord: Vector2) -> Vector2:
	var ratio_x = coord.x / domain
	var ratio_y = (max_val - coord.y) / max_val
	return Vector2(ratio_x, ratio_y) * size




func on_keys_changed() -> void:
	queue_redraw()




