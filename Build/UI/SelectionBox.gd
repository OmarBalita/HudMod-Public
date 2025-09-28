class_name SelectionBox extends FocusControl

signal selection_changed()
signal selection_started()
signal selection_ended(grouping: bool)

@export var id_key_function_name: String

@export var enabled: bool = true
@export var select_from: Array[Control]

@export_group("Theme")
@export var color: Color = Color.WHITE
@export var transparancy: float = .3
var fill_color: Color = Color(color, transparancy)


var request_selection_func: Callable

var selected_nodes: Dictionary[String, Control]

var select_rect: Rect2
var dragged: bool
var start_pos: Vector2
var end_pos: Vector2
var group: bool
var remove: bool
var canceled: bool




func _init() -> void:
	mouse_entering_calculation = false
	rect_calculation = true


func _input(event: InputEvent) -> void:
	
	super(event)
	
	if not enabled or not is_focus:
		return
	
	if event is InputEventMouseButton:
		var pressed = event.is_pressed()
		if event.button_index == MOUSE_BUTTON_LEFT:
			
			start_pos = event.position
			end_pos = event.position
			group = event.ctrl_pressed
			remove = event.alt_pressed
			
			if pressed:
				if request_selection_func.is_null() or request_selection_func.call():
					canceled = false
					selection_started.emit()
					dragged = true
			
			elif not canceled:
				selection_ended.emit(group, remove)
				dragged = false
		
		else:
			canceled = true
			dragged = false
		update_selection()
	
	elif event is InputEventMouseMotion and dragged:
		end_pos = event.position
		update_selection()


func _draw() -> void:
	if dragged:
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






func update_selection() -> void:
	var intersected_nodes: Dictionary[String, Control]
	
	select_rect = Rect2(start_pos, end_pos - start_pos).abs()
	
	for folder in select_from:
		if not is_instance_valid(folder):
			continue
		for node in folder.get_children():
			if node is FocusControl:
				if select_rect.intersects(node.get_global_rect()):
					intersected_nodes[node.call(id_key_function_name)] = node
	
	selected_nodes = intersected_nodes
	selection_changed.emit()
	
	queue_redraw()




