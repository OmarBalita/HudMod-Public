class_name GraphEditorRect extends EditorRect

signal graph_node_options_opened()
signal graph_node_option_button_pressed(option: MenuOption)


@export var graph_node_options: Dictionary[MenuOption, Array]

@onready var graph_edit: GraphEdit = GraphEdit.new()

var copied_nodes: Array[GraphNode]
var picked_graph_node: GraphNode


func _ready() -> void:
	# EditorRect
	super()
	# GraphEdit
	body.add_child(graph_edit)
	IS.set_base_settings(graph_edit)
	# Shortcuts
	shortcut_node.create_key_shortcut(SHIFT_MASK, KEY_A, open_graph_node_options)

func _input(event: InputEvent) -> void:
	super(event)
	if not is_focus:
		return
	
	if picked_graph_node:
		if event is InputEventMouseMotion:
			var use_snap: bool = (graph_edit.snapping_enabled and not event.ctrl_pressed) or (not graph_edit.snapping_enabled and event.ctrl_pressed)
			move_node(picked_graph_node, get_absolute_graph_edit_pos_from_display_pos(get_global_mouse_position()), use_snap)
		elif event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					picked_graph_node = null
				MOUSE_BUTTON_RIGHT:
					picked_graph_node.queue_free()
					picked_graph_node = null

func get_graph_node_options() -> Dictionary[MenuOption, Array]:
	return graph_node_options

func set_graph_node_options(_graph_node_options: Dictionary[MenuOption, Array]) -> void:
	graph_node_options = _graph_node_options

func open_graph_node_options() -> void:
	var latest_options_menu = get_meta("options_menu")
	if latest_options_menu: latest_options_menu.popdown()
	var options_menu:= IS.create_popuped_categories_menu(get_graph_node_options())
	options_menu.menu_button_pressed.connect(on_options_menu_menu_button_pressed)
	IS.popup(options_menu)
	set_meta("options_menu", options_menu)
	graph_node_options_opened.emit()

func create_node(title: String) -> GraphNode:
	var node:= IS.create_graph_node(title)
	node.custom_minimum_size = Vector2(300.0, 300.0)
	return node

func copy_nodes(nodes: Array[GraphNode]) -> void:
	copied_nodes = nodes

func past_nodes() -> Array[GraphNode]:
	var new_nodes: Array[GraphNode]
	for node: GraphNode in copied_nodes:
		var new_node: GraphNode = node.duplicate()
		spawn_node(node, node.focus, false)
	return new_nodes

func spawn_node(graph_node: GraphNode, pos: Variant = null, pick: bool = true) -> void:
	graph_edit.add_child(graph_node)
	if pos is not Vector2:
		pos = get_absolute_graph_edit_pos_from_display_pos(get_global_mouse_position())
	move_node(graph_node, pos)
	if pick: picked_graph_node = graph_node

func move_node(graph_node: GraphNode, to_pos: Vector2, use_snap: bool = false) -> void:
	if use_snap: to_pos = snapped(to_pos, Vector2.ONE * graph_edit.snapping_distance)
	graph_node.position_offset = to_pos

func get_absolute_graph_edit_pos_from_display_pos(pos: Vector2) -> Vector2:
	var absolute_pos:= (pos + graph_edit.scroll_offset - graph_edit.global_position) / graph_edit.zoom
	return absolute_pos



func on_options_menu_menu_button_pressed(menu_option: MenuOption) -> void:
	printt(menu_option.text, "Button Pressed")
	graph_node_option_button_pressed.emit(menu_option)





