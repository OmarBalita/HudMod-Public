class_name SelectionBox extends FocusControl

signal selection_changed()
signal selection_started()
signal selection_ended(group: bool, remove: bool)
signal selection_canceled()

@export var enabled: bool = true
@export var select_from: Array[Control]
@export var id_key_function_name: StringName

@export_group("Theme")
@export var color: Color = IS.COLOR_ACCENT_BLUE:
	set(val):
		color = val
		fill_color = Color(color, transparancy)
@export var transparancy: float = .3
var fill_color: Color = Color(color, transparancy)

var is_active: bool
var start_pos: Vector2
var end_pos: Vector2
var select_rect: Rect2

var selected_nodes: Dictionary[String, Control]

func _gui_input(event: InputEvent) -> void:
	
	super(event)
	
	if not enabled or not is_focus:
		return
	
	if event is InputEventMouseButton:
		var is_pressed: bool = event.is_pressed()
		var event_pos: Vector2 = event.position
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				var group: bool = event.ctrl_pressed
				var remove: bool = event.alt_pressed
				if is_pressed:
					request_start_selection(event_pos)
				elif is_active:
					end_selection(group, remove)
			MOUSE_BUTTON_RIGHT:
				if is_pressed:
					cancel_selection()
		update_selection(event_pos)
	
	elif event is InputEventMouseMotion and is_active:
		update_selection(event.position)


func _draw() -> void:
	if is_active:
		draw_selecting_rect(select_rect)
		for key in selected_nodes:
			var node = selected_nodes[key]
			if not is_instance_valid(node): continue
			draw_selecting_rect(node.get_global_rect())

func draw_selecting_rect(rect: Rect2, color: Color = IS.COLOR_ACCENT_BLUE) -> void:
	rect = Rect2(rect.position - global_position, rect.size)
	var start_pos = rect.position
	var end_pos = start_pos + rect.size
	var to_x_pos = Vector2(end_pos.x, start_pos.y)
	var to_y_pos = Vector2(start_pos.x, end_pos.y)
	
	draw_rect(rect, Color(color, .5))
	draw_dashed_line(start_pos, to_x_pos, color, 2.0, 10.0)
	draw_dashed_line(to_x_pos, end_pos, color, 2.0, 10.0)
	draw_dashed_line(end_pos, to_y_pos, color, 2.0, 10.0)
	draw_dashed_line(to_y_pos, start_pos, color, 2.0, 10.0)


func get_id_key_function_name() -> StringName:
	return id_key_function_name

func set_id_key_function_name(new_val: StringName) -> void:
	id_key_function_name = new_val


func request_start_selection(pos: Vector2) -> void:
	if request_selection_func.is_null() or request_selection_func.call():
		start_selection(pos)

func start_selection(pos: Vector2) -> void:
	is_active = true
	start_pos = pos
	end_pos = pos
	selection_started.emit()

func update_selection(new_pos: Vector2) -> void:
	var intersected_nodes: Dictionary[String, Control]
	
	end_pos = new_pos
	select_rect = Rect2(start_pos, end_pos - start_pos).abs()
	
	for folder: Control in select_from:
		if not is_instance_valid(folder):
			continue
		for node: Node in folder.get_children():
			if node is FocusControl:
				if select_rect.intersects(node.get_global_rect()):
					intersected_nodes[node.call(id_key_function_name)] = node
	
	selected_nodes = intersected_nodes
	selection_changed.emit()
	
	queue_redraw()

func end_selection(group: bool, remove: bool) -> void:
	is_active = false
	selection_ended.emit(group, remove)

func cancel_selection() -> void:
	is_active = false
	selection_canceled.emit()
