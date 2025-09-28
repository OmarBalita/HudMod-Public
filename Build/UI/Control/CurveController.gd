class_name CurveController extends FocusControl


@export var keys_res: KeysRes:
	set(val):
		if keys_res: keys_res.keys_changed.disconnect(on_keys_changed)
		if val:
			val.keys_changed.connect(on_keys_changed)
		keys_res = val
		update_keys_res()


@export_range(-10e10, 10e10) var domain: float = 1.0:
	set(val):
		domain = val
		update_keys_res()
		queue_redraw()
@export_range(-10e10, 10e10) var min_val: float = .0:
	set(val):
		min_val = val
		update_keys_res()
		queue_redraw()
@export_range(-10e10, 10e10) var max_val: float = 1.0:
	set(val):
		max_val = val
		update_keys_res()
		queue_redraw()

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
@export_range(1, 1000) var key_size: float = 10.0:
	set(val): key_size = val; queue_redraw()
@export_range(1.0, 1000.0) var handles_dist: float = 50.0:
	set(val): handles_dist = val; queue_redraw()

var mouse_coord: Variant = null

var selected_keys: Array[float] # selected_keys as x_pos
var selected_handle: Dictionary # selected_handle information as Dictionary

var is_selected_dragged: bool



func _ready() -> void:
	super()
	if not keys_res:
		keys_res = KeysRes.new()
	set_keys_preset1()

func _input(event: InputEvent) -> void:
	super(event)
	
	if event is InputEventMouse:
		
		var mouse_pos = get_local_mouse_position()
		var new_mouse_coord = get_coordinate_from_display_pos(mouse_pos)
		var mouse_delta = Vector2.ZERO if mouse_coord == null else new_mouse_coord - mouse_coord
		mouse_coord = new_mouse_coord
		
		var rounded_keys = keys_res.get_custom_keys(func(x_pos: float, info: Dictionary) -> bool: return get_distance_from_coordinate_pos(mouse_pos, Vector2(x_pos, info.y_val)) <= key_size)
		var rounded_handles = keys_res.get_custom_handles(
			func(key_coord: Vector2, pos: Vector2, type: int) -> bool:
				if is_key_selected(key_coord.x):
					return mouse_pos.distance_to(get_display_pos_from_coordinate(key_coord) + pos * handles_dist) <= key_size
				return false
		)
		
		if event is InputEventMouseButton:
			var is_pressed = event.is_pressed()
			
			match event.button_index:
				
				MOUSE_BUTTON_LEFT:
					if is_pressed:
						var grouping = event.shift_pressed
						var remove = event.alt_pressed
						
						if is_focus:
							if rounded_handles:
								select_handle(rounded_handles)
							else:
								if rounded_keys:
									select_key(rounded_keys, grouping, remove)
								else:
									add_key(new_mouse_coord.x, new_mouse_coord.y, grouping, remove)
									mouse_coord = null
								selected_handle.clear()
						else:
							deselect_all_keys()
					
					is_selected_dragged = is_pressed
				
				MOUSE_BUTTON_RIGHT when is_pressed:
					if rounded_handles:
						change_handle_keeping(rounded_handles[0])
					elif rounded_keys:
						remove_key(rounded_keys)
					else:
						deselect_all_keys()
						selected_handle.clear()
		
		elif event is InputEventMouseMotion:
			if is_selected_dragged:
				if selected_handle:
					move_selected_handle_to(mouse_pos)
				else:
					move_selected_keys(mouse_delta)


func _draw() -> void:
	draw_grid()
	draw_keys()
	super()

func draw_grid() -> void:
	
	var font = IS.LABEL_SETTINGS_MAIN.font
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


func draw_keys() -> void:
	
	var keys = keys_res.get_keys()
	var keys_keys = keys.keys()
	var keys_size = keys.size()
	var key_size_v2 = Vector2.ONE * key_size
	var half_key_size = key_size_v2 / 2.0
	var latest_key_pos: Variant = null
	
	var draw_interpolation_line = func(from: Vector2, to: Vector2) -> void: draw_line(from, to, Color.GRAY, 3.0, true)
	
	for index: int in keys_size - 1:
		var a = keys_keys[index]
		var b = keys_keys[index + 1]
		var a_display_pos = get_display_pos_from_coordinate(Vector2(a, .0))
		var b_display_pos = get_display_pos_from_coordinate(Vector2(b, .0))
		var a_to_b_dist = b_display_pos.x - a_display_pos.x
		var subdv = max(2, int(a_to_b_dist / 2.0))
		for time: int in subdv - 1:
			var absolute_time = time * 2.0
			var p1_offset = get_coordinate_from_display_pos(a_display_pos + Vector2.RIGHT * absolute_time).x
			var p2_offset = get_coordinate_from_display_pos(a_display_pos + Vector2.RIGHT * (absolute_time + 5.0)).x
			var p1_display_pos = get_display_pos_from_coordinate(Vector2(p1_offset, keys_res.sample(p1_offset)))
			var p2_display_pos = get_display_pos_from_coordinate(Vector2(p2_offset, keys_res.sample(p2_offset)))
			if time == subdv - 2:
				draw_interpolation_line.call(p2_display_pos, Vector2(b_display_pos.x, get_display_pos_from_coordinate(Vector2(.0, keys_res.sample(b))).y))
			draw_interpolation_line.call(p1_display_pos, p2_display_pos)
	
	for index: int in keys_size:
		var x_pos: float = keys_keys[index]
		var info = keys.get(x_pos)
		var y_val = info.y_val
		var key_pos = get_display_pos_from_coordinate(Vector2(x_pos, y_val))
		var in_handle_pos = info.in * handles_dist
		var out_handle_pos = info.out * handles_dist
		
		if latest_key_pos == null:
			draw_interpolation_line.call(Vector2(.0, key_pos.y), key_pos)
		if index >= keys_size - 1:
			draw_interpolation_line.call(key_pos, Vector2(size.x, key_pos.y))
		
		var is_key_sel = is_key_selected(x_pos)
		
		var key_rect_pos = key_pos - half_key_size
		if is_key_sel:
			if not keys_keys.min() == x_pos:
				var in_handle_rect_pos = key_pos + in_handle_pos
				draw_line(key_pos, in_handle_rect_pos, Color.WHITE, -1.0, true)
				draw_rect(Rect2(in_handle_rect_pos - half_key_size, key_size_v2), Color.GRAY)
			if not keys_keys.max() == x_pos:
				var out_handle_rect_pos = key_pos + out_handle_pos
				draw_line(key_pos, out_handle_rect_pos, Color.WHITE, -1.0, true)
				draw_rect(Rect2(out_handle_rect_pos - half_key_size, key_size_v2), Color.GRAY)
		draw_rect(Rect2(key_rect_pos, key_size_v2), Color.ROYAL_BLUE if is_key_sel else Color.WHITE)
		
		latest_key_pos = key_pos



func set_keys_preset1() -> void:
	keys_res.clear_keys()
	keys_res.add_key(.0, .0)
	keys_res.add_key(1.0, 1.0)


func set_keys_preset2() -> void:
	keys_res.clear_keys()
	keys_res.add_key(.0, 1.0)
	keys_res.add_key(1.0, .0)

func set_keys_preset3() -> void:
	keys_res.clear_keys()
	keys_res.add_key(.0, .0)
	keys_res.add_key(.5, 1.0)
	keys_res.add_key(1.0, .0)




func select_key(from: Dictionary[float, Dictionary], grouping: bool, remove: bool) -> void:
	
	var rounded_keys_keys = from.keys()
	var curr_index: int
	var can_select: bool = true
	while is_key_selected(rounded_keys_keys[curr_index]):
		curr_index += 1
		if curr_index >= from.size() - 1:
			can_select = false
			break
	if can_select:
		var x_pos = rounded_keys_keys[curr_index]
		if remove:
			selected_keys.erase(x_pos)
		else:
			if not grouping:
				selected_keys.clear()
			selected_keys.append(x_pos)
		queue_redraw()

func deselect_key(x_pos: float) -> void:
	if is_key_selected(x_pos):
		selected_keys.erase(x_pos)
	queue_redraw()

func deselect_all_keys() -> void:
	selected_keys.clear()
	queue_redraw()

func is_key_selected(x_pos: float) -> bool:
	return selected_keys.has(x_pos)

func add_key(x_pos: float, y_pos: float, grouping: bool, remove: bool) -> void:
	var key = keys_res.add_key(x_pos, y_pos)
	var absolute_x_pos = key.keys()[0]
	select_key({absolute_x_pos: {}}, grouping, remove)

func move_selected_keys(delta: Vector2) -> void:
	
	var selected_replaced: Dictionary[float, float]
	for x_pos: float in selected_keys:
		var info = keys_res.keys.get(x_pos)
		if info == null:
			continue
		var y_val = info.y_val
		var new_coord = Vector2(x_pos, y_val) + delta
		var key = keys_res.move_key(x_pos, new_coord.x, new_coord.y)
		if key.size():
			selected_replaced[x_pos] = key.keys()[0]
	
	for from_x_pos: float in selected_replaced:
		var to_x_pos = selected_replaced.get(from_x_pos)
		selected_keys.erase(from_x_pos)
		selected_keys.append(to_x_pos)
	queue_redraw()

func remove_key(rounded_keys: Dictionary[float, Dictionary]) -> void:
	var x_pos = rounded_keys.keys()[0]
	keys_res.remove_key(x_pos)
	deselect_key(x_pos)


func select_handle(from: Array[Dictionary]) -> void:
	if not selected_handle:
		selected_handle = from[0]
	else:
		for handle: Dictionary in from:
			if handle.coord == selected_handle.coord:
				continue
			selected_handle = handle
			break

func move_selected_handle_to(new_pos: Vector2) -> void:
	var selected_replaced_by: Dictionary
	var key_xpos = selected_handle.key_coord.x
	var new_handle_coord = (new_pos - get_display_pos_from_coordinate(selected_handle.key_coord)) / handles_dist
	var handle_type = selected_handle.type
	var handle_is_keeped = selected_handle.is_keeped
	selected_handle = keys_res.move_handle(key_xpos, new_handle_coord, handle_type)
	if handle_is_keeped:
		keys_res.move_handle(key_xpos, -new_handle_coord, 0 if handle_type == 1 else 1)
	queue_redraw()

func change_handle_keeping(handle: Dictionary) -> void:
	var key_coord = handle.key_coord
	var key_xpos = key_coord.x
	var handle_type = handle.type
	
	var new_is_keeped = not handle.is_keeped
	var new_handle_coord: Vector2
	
	if new_is_keeped:
		var key_info = keys_res.keys.get(key_xpos)
		new_handle_coord = -(key_info.in if handle_type else key_info.out)
	else:
		var neighbor_key_xpos = keys_res.get_right_neighbor_key_pos(key_xpos) if handle_type else keys_res.get_left_neighbor_key_pos(key_xpos)
		if neighbor_key_xpos != null:
			var neighbor_key_coord = Vector2(neighbor_key_xpos, keys_res.get_key_val(neighbor_key_xpos))
			new_handle_coord = key_coord.direction_to(neighbor_key_coord)
			new_handle_coord.y *= -1.0
		elif handle_type: new_handle_coord = Vector2.RIGHT
		else: new_handle_coord = Vector2.LEFT
	
	keys_res.keys.get(key_xpos).handles_keeped = new_is_keeped
	keys_res.move_handle(key_xpos, new_handle_coord, handle_type)
	
	queue_redraw()



func update_keys_res() -> void:
	if keys_res:
		keys_res.domain = domain
		keys_res.min_val = min_val
		keys_res.max_val = max_val



func get_coordinate_from_display_pos(pos: Vector2) -> Vector2:
	var ratio = pos / size
	var coordinate = Vector2(ratio.x * domain, max_val - (ratio.y * max_val))
	return coordinate

func get_display_pos_from_coordinate(coord: Vector2) -> Vector2:
	var ratio_x = coord.x / domain
	var ratio_y = (max_val - coord.y) / max_val
	return Vector2(ratio_x, ratio_y) * size

func get_distance_from_coordinate_pos(from: Vector2, coord_pos: Vector2) -> float:
	var display_coord = get_display_pos_from_coordinate(coord_pos)
	return from.distance_to(display_coord)


func on_keys_changed() -> void:
	queue_redraw()




