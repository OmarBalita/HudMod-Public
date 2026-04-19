class_name FocusControl extends Control

signal focus_changed(val: bool)

signal selected_without_drag()
signal selected()
signal deselected()

signal drag_started()
signal dragging()
signal drag_finished()

signal dragged_rect_created(dragged_rect: Control)

@export_subgroup("Selection")
@export var selectable: bool
@export var selection_group: SelectionGroupRes
@export var multiselect: bool = true

@export_subgroup("Dragging")
@export var draggable: bool
@export var min_drag_distance: float = 10.0
@export var group_when_dragging: bool

@export_group("Theme")
@export var draw_focus: bool = true
@export var draw_select: bool
@export var draw_width: float = 3.0
@export var draw_focus_color: Color = IS.color_accent
@export var draw_select_color: Color = IS.color_accent_highlight

@export_multiline() var editor_guides: Array[Dictionary]

var id_key: String
var metadata: Dictionary

var request_selection_func: Callable
var request_drag_func: Callable


# RealTime Variables
# ---------------------------------------------------

var is_focus: bool:
	set(val):
		is_focus = val
		if draw_focus:
			var tween = create_tween()
			tween.tween_property(self, "focus_alpha", float(is_focus) * .5, .15)
		focus_changed.emit(is_focus)

var is_selected: bool: set = set_is_selected

var is_dragging: bool
var dragged_rect: Control

var focus_alpha: float = .0:
	set(val):
		focus_alpha = val
		queue_redraw()

var is_pressed: bool
var press_pos: Vector2
var start_drag_dist: Vector2
var can_drag: bool
var following_drag: Control



func set_is_selected(new_val: bool) -> void:
	is_selected = new_val
	if new_val: selected.emit()
	else: deselected.emit()
	queue_redraw()

func set_is_focus(new_val: bool) -> void:
	is_focus = new_val


# Background Calling Functions
# ---------------------------------------------------

func _ready() -> void:
	# Connections
	mouse_entered.connect(set_is_focus.bind(true))
	mouse_exited.connect(set_is_focus.bind(false))

func _gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouse:
		var mouse_pos: Vector2 = event.position
		var dist: float = press_pos.distance_to(mouse_pos)
		
		var group: bool = multiselect and event.ctrl_pressed
		var remove: bool = event.alt_pressed
		
		if event is InputEventMouseButton and selectable:
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				
				if event.is_pressed():
					if is_focus:
						is_pressed = true
						press_pos = mouse_pos
						start_drag_dist = mouse_pos - global_position
						can_drag = draggable and (request_drag_func.is_null() or request_drag_func.call())
				
				else:
					if is_dragging:
						end_drag()
					elif is_focus and is_pressed:
						if dist <= min_drag_distance:
							if is_selected:
								if event.alt_pressed: deselect()
								else: request_select(group, remove)
							else: request_select(group, remove)
						is_pressed = false
					can_drag = false
		
		elif event is InputEventMouseMotion:
			if can_drag and dist > min_drag_distance:
				start_drag(group or group_when_dragging, false)
			
			if is_dragging:
				if dragged_rect:
					dragged_rect.global_position = mouse_pos - start_drag_dist
				dragging.emit()

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2(-draw_width, -draw_width) / 2.0, size + Vector2(draw_width, draw_width))
	if draw_select and is_selected:
		draw_rect(rect, draw_select_color, false, draw_width)
	elif draw_focus and is_focus:
		draw_rect(rect, Color(draw_focus_color, focus_alpha), false, draw_width)


# FocusControl Base Functions
# ---------------------------------------------------


func request_select(group: bool, remove: bool, is_drag_selection: bool = false) -> void:
	if request_selection_func.is_null() or request_selection_func.call():
		select(group, remove, is_drag_selection)

func select(group: bool, remove: bool, is_drag_selection: bool = false, emit_change: bool = true) -> void:
	selection_group.add_object(get_id_key(), self, get_metadata(), group, emit_change)
	if not is_drag_selection: selected_without_drag.emit()
	#if once_selection:
		#deselect()

func deselect() -> void:
	selection_group.remove_object(get_id_key(), true)


func start_drag(group: bool, remove: bool) -> void:
	if not is_dragging:
		
		is_dragging = true
		_create_dragged_rect()
		hide()
		
		if following_drag:
			return
		
		select(group, remove, true, false)
		drag_started.emit()
		
		var selected_objects: Dictionary[String, Dictionary] = selection_group.selected_objects
		for key: String in selected_objects.keys():
			var info: Dictionary = selected_objects.get(key)
			var selected_clip: Variant = info.object
			if not is_instance_valid(selected_clip): continue
			if selected_clip == self: continue
			selected_clip.start_drag_dist = press_pos - selected_clip.global_position
			selected_clip.following_drag = self
			selected_clip.start_drag(group, remove)

func end_drag() -> void:
	
	is_dragging = false
	if dragged_rect:
		dragged_rect.queue_free()
	show()
	
	if following_drag:
		following_drag = null
		return
	
	drag_finished.emit()

func _get_dragged_rect() -> Control:
	var dragged_rect: Control = duplicate()
	dragged_rect.set_script(null)
	ObjectServer.describe_node_deep(dragged_rect, {mouse_filter = MOUSE_FILTER_IGNORE})
	return dragged_rect

func _create_dragged_rect() -> void:
	dragged_rect = _get_dragged_rect()
	if dragged_rect:
		get_tree().current_scene.add_child(dragged_rect)
		dragged_rect_created.emit(dragged_rect)

func get_id_key() -> String:
	#if not id_key:
		#id_key = ProjectServer.generate_new_id(selection_group.selected_objects.keys())
	return id_key

func get_metadata() -> Dictionary:
	return metadata

func set_metadata(new_metadata: Dictionary) -> void:
	metadata = new_metadata

func calculate_metadata(metadata_keys: Array[String]) -> Dictionary:
	var result: Dictionary
	for key: String in metadata_keys:
		result[key] = get(key)
	metadata = result
	return result
