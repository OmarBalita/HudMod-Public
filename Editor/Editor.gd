class_name EditorControl extends Control

signal windowed()
signal layouted()

@export_group("Theme")
@export_subgroup("Constant")
@export var header_size: int = 50
@export_subgroup("Font", "font")
@export var font_header: Font
@export var font_main: Font

# RealTime Nodes
var container: SplitContainer

var header: MarginContainer
var body: MarginContainer

var header_panel: HeaderPanel
var body_panel: PanelContainer

var shortcut_node:= ShortcutNode.new()

func _ready() -> void:
	
	container = IS.create_split_container(1, true)
	header = IS.create_margin_container(4, 4, 4, 4)
	body = IS.create_margin_container(6, 6, 6, 6)
	
	header_panel = HeaderPanel.new(self)
	body_panel = IS.create_panel_container(Vector2.ZERO, IS.style_body, {"z_index": -1, "clip_contents": true})
	
	header_panel.custom_minimum_size.y = header_size
	header_panel.add_child(header)
	body_panel.add_child(body)
	
	container.add_child(header_panel)
	container.add_child(body_panel)
	add_child(container)

func _ready_editor() -> void:
	pass


class HeaderPanel extends PanelContainer:
	
	var windowed: bool:
		set(val):
			windowed = val
			if val: editor_control.windowed.emit()
			else: editor_control.layouted.emit()
	
	var window: Window
	
	var layout_neighbor: Control
	var layout_is_vertical: bool
	var layout_index: int
	var layout_offset: int
	
	var editor_control: EditorControl
	
	func _init(_editor_control: EditorControl) -> void:
		editor_control = _editor_control
		IS.set_base_panel_settings(self, IS.style_header)
	
	func _ready() -> void:
		set_process(false)
	
	func _gui_input(event: InputEvent) -> void:
		var mouse_pos: Vector2i = get_local_mouse_position() + Vector2(4, 4)
		
		if event is InputEventMouse:
			
			if event is InputEventMouseButton:
				var is_pressed: bool = event.is_pressed()
				if event.button_index == MOUSE_BUTTON_LEFT:
					if is_pressed:
						set_meta(&"press_time", Time.get_ticks_msec() / 1000.)
						set_meta(&"press_pos", mouse_pos)
						if windowed:
							set_process(true)
					elif not windowed:
						remove_meta(&"press_pos")
			
			elif event is InputEventMouseMotion:
				if has_meta(&"press_pos"):
					var press_pos: Vector2i = get_meta(&"press_pos")
					if press_pos != null:
						if not windowed:
							if mouse_pos.distance_to(press_pos) >= 20.0:
								to_window()
								set_process(true)
	
	func _process(delta: float) -> void:
		var drawable_rect: DrawableRect = EditorServer.drawable_rect
		var target_place: Array = move_window(DisplayServer.mouse_get_position())
		var timeout: bool = Time.get_ticks_msec() / 1000. - get_meta(&"press_time") > .2
		
		if timeout:
			drawable_rect.clear_drawn_entities()
			drawable_rect.draw_new_theme_rect(target_place[-1])
		
		if Input.get_mouse_button_mask() == 0:
			
			drawable_rect.clear_drawn_entities()
			remove_meta(&"press_pos")
			set_process(false)
			
			EditorServer.main.update_curr_layout()
			
			if not timeout:
				return
			
			target_place.resize(target_place.size() - 1)
			
			if target_place[0] != null:
				to_layout.callv(target_place)
	
	func to_window(windowed_info: WindowedInfo = null, is_inside_layout: bool = true, update_layout: bool = true) -> Window:
		
		var old_layout_index: int = editor_control.get_index()
		var old_split_cont: Control = editor_control.get_parent()
		if is_inside_layout:
			if old_split_cont.get_child_count() == 1:
				return
			layout_neighbor = old_split_cont.get_child(1 - old_layout_index)
			layout_is_vertical = old_split_cont.vertical
			layout_index = old_layout_index
			layout_offset = old_split_cont.split_offset
		
		# Step 1: Move Editor Control to Window and Popup it.
		window = Window.new()
		window.title = editor_control.get_meta(&"editor_name").capitalize()
		window.always_on_top = true
		var margin_container: MarginContainer = IS.create_margin_container(4, 4, 4, 4)
		editor_control.reparent(margin_container)
		window.add_child(margin_container)
		WindowManager.editor_windows_folder.add_child(window)
		window.popup(Rect2i(
			get_window().position + Vector2i(editor_control.global_position),
			editor_control.size
		))
		window.add_child(GlobalControl.new())
		
		window.close_requested.connect(_on_window_close_request)
		 
		if windowed_info:
			windowed_info.register_window(window)
		
		var old_split_cont_is_root: bool = old_split_cont == EditorServer.main.curr_layout_container
		var cond1: bool = not old_split_cont_is_root
		var cond2: bool = (old_split_cont_is_root and layout_neighbor is SplitContainer)
		
		if is_inside_layout and (cond1 or cond2):
			# Step 2: Move Neighbor to split_cont_parent
			var old_split_cont_parent: Container = old_split_cont.get_parent()
			layout_neighbor.reparent(old_split_cont_parent)
			old_split_cont_parent.move_child(layout_neighbor, old_split_cont.get_index())
			
			# Step 3: Delete Parent
			old_split_cont.queue_free()
			
			if old_split_cont_is_root:
				EditorServer.main.curr_layout_container = layout_neighbor
		
		window.set_meta(&"editor_name", editor_control.get_meta(&"editor_name"))
		
		windowed = true
		
		if update_layout:
			EditorServer.main.update_curr_layout()
		
		return window
	
	func target_to_layout(update_layout: bool = true) -> void:
		to_layout(layout_neighbor if is_instance_valid(layout_neighbor) else null, layout_is_vertical, layout_index, layout_offset, update_layout)
	
	func to_layout(new_layout_neighbor: Control, is_vertical: bool, new_layout_index: int = 0, new_layout_offset: int = 0, update_layout: bool = true) -> void:
		
		if not new_layout_neighbor or (new_layout_neighbor is EditorControl and new_layout_neighbor.header_panel.windowed):
			editor_control.reparent(EditorServer.main.editors_folder)
			window.queue_free()
			windowed = false
			return
		
		if new_layout_neighbor:
			var neighbor_parent: Control = new_layout_neighbor.get_parent()
			
			var new_split_cont: SplitContainer = IS.create_split_container(0, is_vertical, {split_offset = new_layout_offset})
			IS.expand(new_split_cont, true, true)
			neighbor_parent.add_child(new_split_cont)
			neighbor_parent.move_child(new_split_cont, new_layout_neighbor.get_index())
			
			new_layout_neighbor.reparent(new_split_cont)
			editor_control.reparent(new_split_cont)
			new_split_cont.move_child(editor_control, new_layout_index)
			
			if new_layout_neighbor == EditorServer.main.curr_layout_container:
				EditorServer.main.curr_layout_container = new_split_cont
		
		window.queue_free()
		windowed = false
		
		if update_layout:
			EditorServer.main.update_curr_layout()
	
	func move_window(new_pos: Vector2i) -> Array:
		var main: Control = EditorServer.main
		window.position = new_pos - get_meta(&"press_pos")
		return main.get_editor_target_place_from(
			main.get_global_mouse_position(),
			[editor_control]
		)
	
	func _on_window_close_request() -> void:
		target_to_layout()

