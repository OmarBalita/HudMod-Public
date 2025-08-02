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


var selected_nodes: Dictionary[String, Control]

var select_rect: Rect2
var dragged: bool
var start_pos: Vector2
var end_pos: Vector2
var group: bool
var remove: bool
var canceled: bool

var fill_color: Color = Color(color, transparancy)


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
				if EditorServer.media_clips_focused.size():
					return
				canceled = false
				selection_started.emit()
			
			elif not canceled:
				selection_ended.emit(group, remove)
			
			dragged = pressed
		
		else:
			canceled = true
			dragged = false
		update_selection()
	
	elif event is InputEventMouseMotion and dragged:
		end_pos = event.position
		update_selection()


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


func _draw() -> void:
	if dragged:
		draw_selecting_rect(select_rect)
		for key in selected_nodes:
			var node = selected_nodes[key]
			if not is_instance_valid(node): continue
			draw_selecting_rect(node.get_global_rect())


func draw_selecting_rect(rect: Rect2) -> void:
	var absolute_rect = Rect2(rect.position - global_position, rect.size)
	draw_rect(absolute_rect, fill_color)
	draw_rect(absolute_rect, color, false, 2.0)









