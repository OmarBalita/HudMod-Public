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
@export var metadata_keys: Array[String]
@export var multiselect: bool = true
@export var once_selection: bool

@export_subgroup("Dragging")
@export var draggable: bool
@export var min_drag_distance: float = 5.0

@export_group("Theme")
@export var draw_focus: bool = true
@export var draw_select: bool
@export var focus_color: Color
@export var select_color: Color = Color.WHITE

@export_multiline() var editor_guides: Array[Dictionary]

var select_cancelers: Array[Callable]

var id_key: String



# RealTime Variables
# ---------------------------------------------------

var is_focus: bool:
	set(val):
		is_focus = val
		var tween = create_tween()
		tween.tween_property(self, "focus_alpha", float(is_focus) * .5, .15)
		if is_focus:
			EditorServer.push_guides(editor_guides)
		focus_changed.emit(is_focus)

var is_selected: bool:
	set(val):
		is_selected = val
		if val: selected.emit()
		else: deselected.emit()
		queue_redraw()

var dragged_rect: Control:
	set(val):
		dragged_rect = val
		queue_redraw()

var focus_alpha: float = .0:
	set(val):
		focus_alpha = val
		queue_redraw()


var press_pos: Vector2
var start_drag_dist: Vector2
var can_drag: bool
var following_drag: Control



func set_is_focus(focus: bool) -> void:
	is_focus = focus



# Background Called Functions
# ---------------------------------------------------

func _ready() -> void:
	focus_color = InterfaceServer.STYLE_ACCENT.bg_color
	
	# Connections
	if mouse_entering_calculation:
		mouse_entered.connect(set_is_focus.bind(true))
		mouse_exited.connect(set_is_focus.bind(false))

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouse:
		
		var mouse_pos = event.position
		var dist = press_pos.distance_to(event.position)
		var grouping = multiselect and event.ctrl_pressed
		
		if event is InputEventMouseButton and selectable:
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				
				if event.is_pressed():
					if is_focus:
						press_pos = mouse_pos
						start_drag_dist = mouse_pos - global_position
						can_drag = request_drag()
				
				else:
					if dragged_rect:
						end_drag()
					elif is_selected:
						if dist <= min_drag_distance:
							if event.alt_pressed:
								deselect()
					elif is_focus:
						select(grouping)
					can_drag = false
		
		elif event is InputEventMouseMotion:
			
			if can_drag and dist > min_drag_distance:
				start_drag(grouping)
			
			if dragged_rect:
				dragged_rect.global_position = mouse_pos - start_drag_dist
				dragging.emit()
			
			if rect_calculation:
				set_is_focus(get_rect().has_point(get_local_mouse_position()))

func _draw() -> void:
	var rect = Rect2(Vector2.ONE, size - Vector2.ONE)
	if draw_focus and is_focus:
		draw_rect(rect, Color(focus_color, focus_alpha), false, 3.0)
	if draw_select and is_selected:
		draw_rect(rect, select_color, false, 3.0)



# FocusControl Base Functions
# ---------------------------------------------------


func select(grouping: bool, is_drag_selection: bool = false) -> void:
	var metadata: Dictionary = get_metadata()
	selection_group.add_object(get_id_key(), self, metadata, grouping, true)
	if not is_drag_selection:
		selected_without_drag.emit()
	if once_selection:
		deselect()

func deselect() -> void:
	selection_group.remove_object(get_id_key(), true)

func request_drag() -> bool:
	return true

func start_drag(grouping: bool) -> void:
	if not dragged_rect:
		
		select(grouping, true)
		create_dragged_rect()
		hide()
		drag_started.emit()
		
		if following_drag:
			return
		
		var selected_objects = selection_group.selected_objects
		for key in selected_objects:
			var info = selected_objects.get(key)
			var selected_clip = info.object
			if not is_instance_valid(selected_clip): continue
			if selected_clip == self: continue
			selected_clip.start_drag_dist = press_pos - selected_clip.global_position
			selected_clip.following_drag = self
			selected_clip.start_drag(grouping)

func end_drag() -> void:
	dragged_rect.queue_free()
	show()
	
	if following_drag:
		following_drag = null
		return
	
	drag_finished.emit()

func create_dragged_rect() -> void:
	
	dragged_rect = duplicate()
	dragged_rect.set_script(null)
	ObjectServer.describe_node_deep(dragged_rect, {"mouse_filter" = Control.MOUSE_FILTER_IGNORE})
	
	get_tree().current_scene.add_child(dragged_rect)
	dragged_rect_created.emit(dragged_rect)



func get_id_key() -> String:
	if not id_key:
		id_key = ProjectServer.generate_new_id(selection_group.selected_objects.keys())
	return id_key

func get_metadata() -> Dictionary:
	var metadata: Dictionary
	for key in metadata_keys:
		metadata[key] = get(key)
	return metadata







