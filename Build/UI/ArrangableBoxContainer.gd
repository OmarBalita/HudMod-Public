class_name ArrangableBoxContainer extends VBoxContainer

signal grab_started(element: Control, index_from: int)
signal grab_released(index_from: int, index_to: Variant)

@export var owner_control: Control
@export var scroll_container: ScrollContainer
@export_group(&"Theme")
@export_subgroup(&"Constant")
@export var scroll_speed: float = 800.0

var is_element_grabbed: bool

var element: Control:
	set(val):
		
		var index_from: int = get_meta(&"index_from")
		var index_to: Variant = get_meta(&"index_to")
		
		if val:
			_instance_grabbed_control(val)
			val.modulate.a = .0
			grab_started.emit(element, index_from)
		
		else:
			_free_grabbed_control()
			element.modulate.a = 1.0
			grab_released.emit(index_from, index_to)
		
		is_element_grabbed = val != null
		element = val

var grabbed_control: Control

func _init(_owner_control: Control, _scroll_container: ScrollContainer) -> void:
	add_theme_constant_override(&"separation", 12)
	owner_control = _owner_control
	scroll_container = _scroll_container

func _input(event: InputEvent) -> void:
	if element:
		
		if event is InputEventMouseMotion:
			var mouse_pos: Vector2 = get_global_mouse_position()
			
			grabbed_control.global_position.y = mouse_pos.y + get_meta(&"drag_offset").y
			
			var nav_dir: int
			if mouse_pos.y < owner_control.global_position.y + 64.: nav_dir = -1
			elif mouse_pos.y > owner_control.global_position.y + owner_control.size.y - 64.: nav_dir = 1
			set_meta(&"nav_dir", nav_dir)
			
			var drawable_rect: DrawableRect = get_tree().get_first_node_in_group(&"drawable_rect")
			
			drawable_rect.clear_drawn_entities()
			
			for index: int in get_child_count():
				var comp_edit: EditBoxContainer = get_child(index)
				var rect: Rect2 = comp_edit.get_global_rect()
				if rect.has_point(mouse_pos):
					drawable_rect.draw_new_theme_rect(rect)
					set_meta(&"index_to", index)
					break

func grab_element(element_as_child: Control, index_from: int) -> void:
	index_from = max(0, index_from)
	set_meta(&"index_from", index_from)
	
	element = element_as_child
	
	var drag_offset: Vector2 = element.global_position - get_global_mouse_position()
	set_meta(&"drag_offset", drag_offset)
	set_meta(&"nav_dir", .0)
	
	while element:
		
		grabbed_control.global_position.y = clamp(
			grabbed_control.global_position.y,
			global_position.y,
			global_position.y + size.y - grabbed_control.size.y
		)
		
		var scroll_offset: float = get_meta(&"nav_dir") * scroll_speed * get_process_delta_time()
		scroll_container.scroll_vertical += scroll_offset
		
		await get_tree().process_frame

func release_element() -> void:
	if is_element_grabbed:
		element = null
		var drawable_rect: DrawableRect = get_tree().get_first_node_in_group(&"drawable_rect")
		drawable_rect.clear_drawn_entities()

func _instance_grabbed_control(from: Control) -> void:
	var new_grabbed_control: Control = from.duplicate()
	ObjectServer.call_method_deep(new_grabbed_control, &"set_script", [null])
	new_grabbed_control.global_position = from.global_position
	new_grabbed_control.size = from.size
	get_tree().current_scene.add_child(new_grabbed_control)
	grabbed_control = new_grabbed_control

func _free_grabbed_control() -> void:
	grabbed_control.queue_free()
	grabbed_control = null

