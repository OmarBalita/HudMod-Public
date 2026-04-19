extends Control

@onready var box: VBoxContainer = %Box

@onready var bg_panel_container: PanelContainer = %BGPanelContainer
@onready var bottom: PanelContainer = %Bottom

@onready var layout_btn_box: HBoxContainer = %LayoutButtonContainer
@onready var editors_folder: Control = %EditorsFolder
@onready var add_layout_btn: Button = %AddLayoutButton
@onready var delete_layout_btn: Button = %DeleteLayoutButton

@onready var freeze_rect: ColorRect = %FreezeRect

@export_group("Version")
@export var version_name: StringName
@export var version_banner: Texture2D
@export var banner_owner: StringName
@export var banner_owner_link: StringName

@export_group("About & Support")
@export var website_link: StringName
@export var support_link: StringName

@export_group("Editor")
@export var editors: Dictionary[StringName, EditorControl]
@export var preset_layouts: Array[LayoutRootInfo]
@export var custom_layouts: Array[LayoutRootInfo]




# Nodes
var curr_layout_container: SplitContainer
var curr_layout_buttons: Dictionary[LayoutRootInfo, Button]

# Resources
var curr_layout: LayoutRootInfo:
	set(val):
		curr_layout = val
		
		delete_layout_btn.visible = custom_layouts.has(curr_layout)
		
		EditorServer.update_popup_menu_layout_item_checked(curr_layout)
		EditorServer.update_popup_menu_docks_items_checked(editors)

var layout_button_group:= ButtonGroup.new()


func _ready() -> void:
	
	get_window().borderless = false
	get_window().mode = Window.MODE_MAXIMIZED
	get_window().min_size = Vector2i(1500, 900)
	get_tree().set_auto_accept_quit(false)
	
	IS.set_base_panel_settings(bg_panel_container, IS.style_cornerless_dark)
	IS.set_base_panel_settings(bottom, IS.style_body)
	
	_load_custom_layouts()
	
	for editor_key: StringName in editors:
		editors[editor_key].set_meta(&"editor_name", editor_key)
	
	Scene2._ready_scene()
	EditorServer._ready_editor_server(editors)
	
	_init_layout_editor()
	_update_layout_editor()
	
	add_layout_btn.pressed.connect(_on_add_layout_btn_pressed)
	delete_layout_btn.pressed.connect(_on_delete_layout_btn_pressed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		update_curr_layout(false)


func _load_custom_layouts() -> void:
	custom_layouts = EditorServer.load_custom_layouts()

func _init_layout_editor() -> void:
	for layout: LayoutRootInfo in preset_layouts:
		layout.layout_changed.connect(_on_preset_layout_changed.bind(layout))
	for layout: LayoutRootInfo in custom_layouts:
		layout.set_root_deep(layout)
		layout.layout_changed.connect(_on_custom_layout_changed.bind(layout))

func _update_layout_editor(open_what: LayoutRootInfo = null) -> void:
	for control: Control in layout_btn_box.get_children():
		control.queue_free()
	curr_layout_buttons.clear()
	
	for layout: LayoutRootInfo in preset_layouts:
		register_layout_button(layout)
	layout_btn_box.add_child(IS.create_v_line_panel())
	for layout: LayoutRootInfo in custom_layouts:
		register_layout_button(layout)
	
	open_layout(open_what if open_what else preset_layouts[0])


func register_layout_button(layout: LayoutRootInfo) -> void:
	var button: Button = IS.create_button(layout.layout_name.capitalize(), layout.layout_image, false, true)
	
	button.toggle_mode = true
	button.custom_minimum_size.x = 220.0
	button.add_theme_stylebox_override(&"focus", IS.style_box_empty)
	
	button.button_group = layout_button_group
	button.pressed.connect(_on_layout_btn_pressed.bind(button, layout))
	
	layout_btn_box.add_child(button)
	
	curr_layout_buttons[layout] = button

func open_layout(layout: LayoutRootInfo) -> void:
	close_curr_layout()
	var open_result: Dictionary[StringName, Variant] = layout.open(editors)
	curr_layout_container = open_result.layout
	
	var btn: Button = curr_layout_buttons[layout]
	btn.button_pressed = true
	
	box.add_child(curr_layout_container)
	box.move_child(curr_layout_container, 1)
	
	curr_layout = layout

func close_curr_layout() -> void:
	
	for editor_name: StringName in editors:
		var editor: EditorControl = editors[editor_name]
		if editor.get_parent() != editors_folder:
			var header_panel: EditorControl.HeaderPanel = editor.header_panel
			if header_panel.windowed:
				header_panel.target_to_layout(false)
			editor.reparent(editors_folder)
	
	if curr_layout_container:
		curr_layout_container.queue_free()
		curr_layout_container = null

func create_new_layout(layout_container: SplitContainer, layout_name: StringName) -> void:
	var new_layout: LayoutRootInfo = LayoutRootInfo.parse(layout_container)
	new_layout.set_layout_name(layout_name)
	custom_layouts.append(new_layout)
	EditorServer.save_custom_layouts([new_layout])
	EditorServer.update_popup_menus()
	_update_layout_editor(new_layout)

func delete_custom_layout(layout_info: LayoutRootInfo) -> void:
	custom_layouts.erase(layout_info)
	EditorServer.remove_custom_layouts([layout_info])
	EditorServer.update_popup_menus()
	_update_layout_editor()

func update_curr_layout(delay_frame: bool = true) -> void:
	if preset_layouts.has(curr_layout): return
	
	if delay_frame: await get_tree().process_frame
	
	var new_layout_version: LayoutRootInfo = LayoutRootInfo.parse(curr_layout_container)
	new_layout_version.set_layout_name(curr_layout.layout_name)
	new_layout_version.set_layout_image(curr_layout.layout_image)
	new_layout_version.set_meta(&"id", curr_layout.get_meta(&"id"))
	EditorServer.save_custom_layouts([new_layout_version], false, false)
	
	var button: Button = curr_layout_buttons[curr_layout]
	var btn_pressed_signal: Signal = button.pressed
	
	btn_pressed_signal.disconnect(btn_pressed_signal.get_connections()[0].callable)
	btn_pressed_signal.connect(_on_layout_btn_pressed.bind(button, new_layout_version))
	
	custom_layouts[custom_layouts.find(curr_layout)] = new_layout_version
	curr_layout_buttons[new_layout_version] = button
	
	EditorServer.update_popup_menus()
	
	curr_layout = new_layout_version


func get_editor_target_place_from(global_pos: Vector2, editors_ignored: Array = []) -> Array: # [0]: target_editor, [1]: vertical?, [2]: index
	var target_editor: EditorControl
	var vertical: bool
	var index: int
	
	var rect_fordraw: Rect2
	
	for editor_name: StringName in editors:
		
		var editor: EditorControl = editors[editor_name]
		if editor.get_parent() == editors_folder or editors_ignored.has(editor):
			continue
		
		var editor_pos:= editor.position
		var editor_global_pos:= editor.global_position
		var editor_size:= editor.size
		var local_pos: Vector2 = global_pos - editor_global_pos
		
		if editor.get_rect().has_point(local_pos + editor_pos):
			var dists: Array[float] = [
				local_pos.x, editor.size.x - local_pos.x,
				local_pos.y, editor.size.y - local_pos.y
			]
			
			var min_dist: float = dists.min()
			if min_dist > 120.:
				EditorServer.drawable_rect.clear_drawn_entities()
				return [target_editor, vertical, index, rect_fordraw]
			
			var dir_index: int = dists.find(min_dist)
			
			target_editor = editor
			vertical = dir_index > 1
			index = dir_index % 2
			
			var editor_size_half: Vector2 = editor_size / 2.
			var editor_size_hx:= Vector2(editor_size_half.x, editor_size.y)
			var editor_size_hy:= Vector2(editor_size.x, editor_size_half.y)
			
			match dir_index:
				0: rect_fordraw = Rect2(editor_global_pos, editor_size_hx)
				1: rect_fordraw = Rect2(editor_global_pos + Vector2.RIGHT * editor_size_half.x, editor_size_hx)
				2: rect_fordraw = Rect2(editor_global_pos, editor_size_hy)
				3: rect_fordraw = Rect2(editor_global_pos + Vector2.DOWN * editor_size_half.y, editor_size_hy)
			break
	
	return [target_editor, vertical, index, rect_fordraw]


func _on_preset_layout_changed(layout: LayoutRootInfo) -> void:
	ResourceSaver.save(layout, layout.resource_path)

func _on_custom_layout_changed(layout: LayoutRootInfo) -> void:
	EditorServer.save_custom_layouts([layout], false, false)

func _on_layout_btn_pressed(button: Button, layout: LayoutRootInfo) -> void:
	if layout != curr_layout:
		await update_curr_layout()
		open_layout(layout)

func _on_add_layout_btn_pressed() -> void:
	var layout_name_edit: LineEdit = IS.create_string_edit(&"Layout Name", &"", &"Custom Layout")[0]
	
	var accept_func: Callable = func() -> void:
		create_new_layout(curr_layout_container, layout_name_edit.text)
	
	var box: BoxContainer = WindowManager.popup_accept_window(get_window(), Vector2(400., 150.), &"New Layout", accept_func)
	box.add_child(layout_name_edit.get_parent())
	
	layout_name_edit.grab_focus()
	layout_name_edit.select_all()
	
	layout_name_edit.text_submitted.connect(func(layout_name: StringName) -> void:
		accept_func.call()
		box.get_window().queue_free()
	)

func _on_delete_layout_btn_pressed() -> void:
	delete_custom_layout(curr_layout)




