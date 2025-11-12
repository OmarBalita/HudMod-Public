class_name FocusControl extends Control

signal focus_changed(val: bool)

signal selected_without_drag()
signal selected()
signal deselected()

signal drag_started()
signal dragging()
signal drag_finished()

signal dragged_rect_created(dragged_rect: Control)


const NONE_MASK: int = 0
const CTRL_MASK: int = 268435456
const SHIFT_MASK: int = 33554432
const ALT_MASK: int = 67108864

@export_group("Custom Properties")
@export var mouse_entering_calculation: bool = true
@export var rect_calculation: bool

@export_subgroup("Selection")
@export var selectable: bool
@export var selection_group: SelectionGroupRes
@export var multiselect: bool = true

@export_subgroup("Dragging")
@export var draggable: bool
@export var min_drag_distance: float = 5.0
@export var group_when_dragging: bool

@export_group("Theme")
@export var draw_focus: bool = true
@export var draw_select: bool
@export var focus_color: Color
@export var select_color: Color = Color.WHITE

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
			if is_focus:
				EditorServer.push_guides(editor_guides)
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


# Background Called Functions
# ---------------------------------------------------

func _ready() -> void:
	focus_color = IS.STYLE_ACCENT.bg_color
	
	# Connections
	if mouse_entering_calculation:
		mouse_entered.connect(set_is_focus.bind(true))
		mouse_exited.connect(set_is_focus.bind(false))

func _input(event: InputEvent) -> void:
	
	#if event is InputEventMouse:
		#var event_pos: Vector2 = event.position
		#
		#var group: bool = multiselect and event.ctrl_pressed
		#var remove: bool = event.alt_pressed
		#
		#if event is InputEventMouseButton:
			#var is_pressed: bool = event.is_pressed()
			#if is_pressed: press_pos = event_pos
			#
			#match event.button_index:
				#MOUSE_BUTTON_LEFT:
					#if is_pressed:
						#pass
					#else:
						#pass
				#MOUSE_BUTTON_RIGHT:
					#if is_pressed:
						#pass
					#else:
						#pass
		#
		#elif event is InputEventMouseMotion:
			#pass
	
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
						can_drag = request_drag_func.is_null() or request_drag_func.call()
				
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
			
			if rect_calculation:
				set_is_focus(get_rect().has_point(get_local_mouse_position()))


func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ONE, size - Vector2.ONE)
	if draw_focus and is_focus:
		draw_rect(rect, Color(focus_color, focus_alpha), false, 3.0)
	if draw_select and is_selected:
		draw_rect(rect, select_color, false, 3.0)



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
		select(group, remove, true)
		create_dragged_rect()
		hide()
		drag_started.emit()
		
		if following_drag:
			return
		
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

func get_dragged_rect() -> Control:
	var dragged_rect: Control = duplicate()
	dragged_rect.set_script(null)
	ObjectServer.describe_node_deep(dragged_rect, {mouse_filter = MOUSE_FILTER_IGNORE})
	return dragged_rect

func create_dragged_rect() -> void:
	dragged_rect = get_dragged_rect()
	if dragged_rect:
		get_tree().current_scene.add_child(dragged_rect)
		dragged_rect_created.emit(dragged_rect)

func focus_enter() -> void:
	pass

func focus_exit() -> void:
	pass


func get_id_key() -> String:
	if not id_key:
		id_key = ProjectServer.generate_new_id(selection_group.selected_objects.keys())
	return id_key

func get_metadata() -> Dictionary:
	return metadata

func calculate_metadata(metadata_keys: Array[String]) -> Dictionary:
	var result: Dictionary
	for key: String in metadata_keys:
		result[key] = get(key)
	metadata = result
	return result







