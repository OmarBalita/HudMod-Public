class_name Properties2 extends EditorControl

signal property_changed()

@export_group("Theme")
@export_subgroup("Texture", "texture")
@export var texture_add: Texture2D
@export var texture_search: Texture2D
@export var texture_delete: Texture2D
@export var texture_drag: Texture2D

var clips_selection_group: SelectionGroupRes

var curr_media_ress: Array[MediaClipRes]
var curr_focused_media_res: MediaClipRes
var curr_displayed_components: Dictionary[StringName, Array]

var notification_label: Label
var sections_menu: Menu
var components_scroll: ScrollContainer
var components_body: MarginContainer
var sections_controls: Dictionary[StringName, Dictionary]

var media_properties_panel_container: PanelContainer


func _ready_editor() -> void:
	super()
	
	notification_label = IS.create_label("", IS.LABEL_SETTINGS_MAIN)
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_update_notification_label()
	
	components_scroll = IS.create_scroll_container()
	components_body = IS.create_margin_container(0, 12, 0, 0)
	components_scroll.add_child(components_body)
	
	body.add_child(notification_label)
	body.add_child(components_scroll)
	
	IS.expand(components_body, true, true)
	
	resized.connect(_on_resized)
	
	clips_selection_group = EditorServer.media_clips_selection_group
	clips_selection_group.selected_objects_changed.connect(_on_clips_selection_group_selected_objects_changed)

func popup_section_components(section_key: StringName, pop_from: Control = null) -> void:
	var part_option: MenuOption = MenuOption.new("Part")
	var options: Dictionary[MenuOption, Array] = {part_option: []}
	var section_components: Dictionary[StringName, Dictionary] = ClassServer.comps_get_section_comps(section_key)
	for comp_classname: StringName in section_components:
		var comp_info: Dictionary[StringName, Variant] = section_components[comp_classname]
		var comp_script: Script = comp_info.script
		options[part_option].append(MenuOption.new(
			comp_classname,
			comp_info.icon,
			add_component.bind(section_key, comp_script)
		))
	var components_popuped_menu: PopupedCategoriesMenu = IS.create_popuped_categories_menu(options)
	get_tree().current_scene.add_child(components_popuped_menu)
	await components_popuped_menu.categories_menu_popuped
	components_popuped_menu.popup(pop_from.global_position + Vector2(0, pop_from.size.y))

func add_component(section_key: StringName, script: Script) -> void:
	for media_res: MediaClipRes in curr_media_ress:
		var new_component_res:= ComponentRes.new()
		new_component_res.set_script(script)
		media_res.add_component(section_key, new_component_res)
	update_properties(section_key)

func delete_component(section_key: StringName, comp_info: ComponentInfo, edit_box_container: IS.EditBoxContainer = null) -> void:
	for index: int in curr_media_ress.size():
		var media_res: MediaClipRes = curr_media_ress[index]
		media_res.erase_component(section_key, comp_info.components_ress[index])
	if edit_box_container:
		edit_box_container.queue_free()
		_update_margin()
	else:
		update_properties(section_key)

func move_component(section_key: StringName, index_from: int, index_to: int) -> void:
	var media_res_as_owner: MediaClipRes = curr_media_ress.get(0)
	media_res_as_owner.move_component(section_key, index_from, index_to)
	update_properties(section_key)

func update_component_method(section_key: StringName, comp_info: ComponentInfo, target_method_type: ComponentRes.MethodType) -> void:
	for comp_res: ComponentRes in comp_info.components_ress:
		comp_res.set_method_type(target_method_type)

func navigate_to_section(section_key: StringName) -> void:
	for _section_key: StringName in sections_controls:
		sections_controls.get(_section_key).root.visible = section_key == _section_key
	_update_margin()

func update_properties(section_key: StringName = &"") -> void:
	clips_selection_group.clear_previously_freed_instances()
	
	var update_info: Dictionary[StringName, Variant] = _update_displayed_components()
	
	var new_media_ress: Array[MediaClipRes] = update_info.new_media_ress
	var new_focused_media_res: MediaClipRes = update_info.new_focused_media_res
	
	if section_key.is_empty():
		if curr_media_ress != new_media_ress or curr_focused_media_res != new_focused_media_res:
			curr_media_ress = new_media_ress
			curr_focused_media_res = new_focused_media_res
			_display_components_by_sections()
	else: _display_section_components(section_key, true)
	
	_update_margin()

func update_media_properties(info: Dictionary[StringName, String]) -> void:
	curr_media_ress.clear()
	
	_clear_controls()
	
	var media_type_title: String = info.get(&"title")
	sections_menu = IS.create_menu([MenuOption.new(media_type_title)])
	header.add_child(sections_menu)
	info.erase(&"title")
	
	var panel_container: PanelContainer = IS.create_panel_container()
	var margin_container: MarginContainer = IS.create_margin_container(12, 12, 12, 12)
	var box_container: BoxContainer = IS.create_box_container(0, true)
	
	var key_panel_gui_input_func: Callable = func(event: InputEvent, val_as_string: String) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				DisplayServer.clipboard_set(val_as_string)
	
	for key: StringName in info.keys():
		var val_as_string: String = info.get(key)
		
		var key_panel_container: PanelContainer = IS.create_panel_container(Vector2.ZERO, IS.STYLE_BODY)
		var key_margin_container: MarginContainer = IS.create_margin_container()
		var split_container: SplitContainer = IS.create_split_container()
		var key_label: Label = IS.create_name_label(key.capitalize())
		var val_label: Label = IS.create_label(val_as_string, IS.LABEL_SETTINGS_MAIN, {})
		
		key_panel_container.self_modulate.a = .0
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		val_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		
		key_panel_container.gui_input.connect(func(event: InputEvent) -> void:
			key_panel_gui_input_func.call(event, val_as_string)
		)
		key_panel_container.mouse_entered.connect(_on_panel_mouse_entered.bind(key_panel_container))
		key_panel_container.mouse_exited.connect(_on_panel_mouse_exited.bind(key_panel_container))
		
		IS.add_children(split_container, [key_label, val_label])
		key_margin_container.add_child(split_container)
		key_panel_container.add_child(key_margin_container)
		box_container.add_child(key_panel_container)
	
	margin_container.add_child(box_container)
	panel_container.add_child(margin_container)
	components_body.add_child(panel_container)
	
	panel_container.custom_minimum_size.y = 650
	panel_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	_update_margin()
	
	media_properties_panel_container = panel_container

func _update_displayed_components() -> Dictionary[StringName, Variant]:
	var selected_objects: Dictionary[String, Dictionary] = clips_selection_group.selected_objects
	
	curr_displayed_components.clear()
	
	if not selected_objects:
		return {
			&"new_media_ress": [] as Array[MediaClipRes],
			&"new_focused_media_res": null
		}
	
	if clips_selection_group.focused.is_empty():
		clips_selection_group.set_default_focused()
	
	var focused_object: MediaClip = clips_selection_group.focused.object
	var focused_media_res: MediaClipRes = focused_object.clip_res
	var focused_components: Dictionary[String, Array] = focused_media_res.get_components()
	
	var new_media_ress: Array[MediaClipRes]
	var new_displayed_components: Dictionary[StringName, Array]
	
	for section_key: StringName in ClassServer.comps_sections_infos:
		
		var new_section_components: Array[ComponentInfo]
		new_displayed_components[section_key] = new_section_components
		
		if focused_components.has(section_key):
			var section_components: Array = focused_components.get(String(section_key))
			for index: int in section_components.size():
				var component_res: ComponentRes = section_components[index]
				new_section_components.append(ComponentInfo.new(index, component_res))
	
	for key: String in selected_objects.keys():
		var object: MediaClip = selected_objects.get(key).object
		var media_res: MediaClipRes = object.clip_res
		var components: Dictionary[String, Array] = media_res.get_components()
		
		var sections: Array = MediaServer.get_clip_sections(object.clip_res)
		var next_displayed_components: Dictionary[StringName, Array]
		
		new_media_ress.append(media_res)
		
		for section_key: StringName in sections:
			if new_displayed_components.has(section_key):
				
				var next_section_components: Array
				
				if components.has(section_key):
					
					var section_components: Array = components.get(section_key)
					var finded_comps_by_ids: Dictionary[StringName, Array]
					
					for component_res: ComponentRes in section_components:
						finded_comps_by_ids.get_or_add(component_res.get_classname(), []).append(component_res)
					
					for component_info: ComponentInfo in new_displayed_components[section_key]:
						var target_comp_res_id: StringName = component_info.component_res_id
						
						if not finded_comps_by_ids.has(target_comp_res_id):
							continue
						
						var finded_comps_by_id: Array = finded_comps_by_ids.get(target_comp_res_id)
						
						if not finded_comps_by_id:
							continue
						
						var finded_comp_res: ComponentRes = finded_comps_by_id[0]
						finded_comps_by_id.remove_at(0)
						
						component_info.append_component_res(finded_comp_res)
						next_section_components.append(component_info)
				
				next_displayed_components[section_key] = next_section_components
		
		new_displayed_components = next_displayed_components
	
	curr_displayed_components = new_displayed_components
	
	return {
		&"new_media_ress": new_media_ress,
		&"new_focused_media_res": focused_media_res
	}

func _clear_controls() -> void:
	if sections_menu:
		sections_menu.queue_free()
	
	sections_controls.values().map(
		func(element: Dictionary) -> void:
			element.root.queue_free()
	)
	sections_controls.clear()
	
	if media_properties_panel_container:
		media_properties_panel_container.queue_free()

func _display_components_by_sections() -> void:
	_clear_controls()
	
	var notif_text: String = _update_notification_label()
	
	if notif_text.is_empty():
		
		var sections_options: Array
		
		for section_key: StringName in curr_displayed_components.keys():
			sections_options.append(MenuOption.new(section_key, null, _on_sections_menu_option_pressed.bind(section_key)))
			_display_section_components(section_key)
		
		navigate_to_section(curr_displayed_components.keys()[0])
		
		var new_sections_menu: Menu = IS.create_menu(sections_options)
		header.add_child(new_sections_menu)
		sections_menu = new_sections_menu

func _display_section_components(section_key: StringName, free_latest_display: bool = false) -> void:
	
	if free_latest_display:
		sections_controls[section_key].root.queue_free()
	
	var split_container: SplitContainer = IS.create_split_container(2, true)
	var add_and_search_split_container: SplitContainer = IS.create_split_container()
	var box_container: ArrangableBoxContainer = ArrangableBoxContainer.new(body, components_scroll)
	
	box_container.grab_released.connect(func(index_from: int, index_to: Variant) -> void:
		_on_section_box_container_grab_released(section_key, index_from, index_to)
	)
	
	var add_component_button: Button = IS.create_button("", texture_add, true)
	var search_line_edit: LineEdit = IS.create_line_edit("Search for %s Component" % section_key.capitalize(), "", texture_search)
	
	add_component_button.pressed.connect(popup_section_components.bind(section_key, add_component_button))
	search_line_edit.text_changed.connect(_on_search_line_edit_text_changed)
	
	add_and_search_split_container.add_child(add_component_button)
	add_and_search_split_container.add_child(search_line_edit)
	
	split_container.add_child(add_and_search_split_container)
	split_container.add_child(box_container)
	components_body.add_child(split_container)
	IS.expand(split_container, true)
	
	sections_controls[section_key] = {
		&"root": split_container,
		&"box": box_container
	}
	
	var section_components_info: Array = curr_displayed_components[section_key]
	
	for comp_info: ComponentInfo in section_components_info:
		_spawn_component_controller(section_key, comp_info)

func _spawn_component_controller(section_key: StringName, comp_info: ComponentInfo) -> void:
	var comp_res_owner: ComponentRes = comp_info.component_res_owner
	comp_res_owner.res_changed.connect(property_changed.emit)
	
	var comp_controllers: Array[Control] = ComponentRes.create_custom_edit(comp_info.component_res_id, comp_res_owner, comp_info.components_ress)
	var comp_editor: IS.EditBoxContainer = IS.get_edit_box_from(comp_controllers)
	var editor_header: BoxContainer = comp_editor.header
	
	comp_editor.set_meta(&"component_res", comp_res_owner)
	comp_editor.keyframable = false
	
	var method_controller: OptionController = IS.create_option_controller([
		{text = "Set"},
		{text = "Add"},
		{text = "Sub"},
		{text = "Multiply"},
		{text = "Divide"}
	], "", comp_res_owner.get_method_type())
	method_controller.selected_option_changed.connect(func(id: int, option: MenuOption) -> void:
		update_component_method(section_key, comp_info, id))
	editor_header.add_child(method_controller)
	
	var delete_button: IS.CustomTextureButton = IS.create_texture_button(texture_delete)
	delete_button.pressed.connect(delete_component.bind(section_key, comp_info, comp_editor))
	editor_header.add_child(delete_button)
	
	if curr_media_ress.size() == 1:
		var move_button: IS.CustomTextureButton = IS.create_texture_button(texture_drag)
		move_button.button_down.connect(_on_component_controller_move_button_button_down.bind(section_key, comp_info.index, comp_editor))
		move_button.button_up.connect(_on_component_controller_move_button_button_up.bind(section_key, comp_editor))
		editor_header.add_child(move_button)
	
	sections_controls[section_key].box.add_child(comp_editor)
	
	var update_usable_ress_func: Callable = func(new_frame: int) -> void:
		var media_res: MediaClipRes = comp_res_owner.get_owner()
		var new_local_frame: int = clamp(new_frame - media_res.clip_pos, 0, media_res.length)
		comp_res_owner.update_controllers(new_local_frame)
	
	update_usable_ress_func.call(EditorServer.get_frame())
	EditorServer.frame_changed.connect(update_usable_ress_func)
	comp_editor.tree_exited.connect(func() -> void: EditorServer.frame_changed.disconnect(update_usable_ress_func))

func _update_notification_label() -> String:
	var notif_text: String
	if not curr_displayed_components:
		if curr_media_ress: notif_text = "The clips you selected do not have any shared property."
		else: notif_text = "At least one Clip must be selected to display its properties."
	notification_label.text = notif_text
	notification_label.visible = not notif_text.is_empty()
	return notif_text

func _update_margin() -> void:
	await get_tree().process_frame
	var activate_margin_cond: bool = components_body.size.y > body.size.y - 24
	components_body.add_theme_constant_override(&"margin_right", 12 if activate_margin_cond else 0)

func _on_resized() -> void:
	_update_margin()

func _on_clips_selection_group_selected_objects_changed() -> void:
	await get_tree().process_frame
	update_properties()

func _on_sections_menu_option_pressed(section_key: StringName) -> void:
	navigate_to_section(section_key)

func _on_section_box_container_grab_released(section_key: StringName, index_from: int, index_to: Variant) -> void:
	if index_to != null and index_from != index_to:
		move_component(section_key, index_from, index_to)

func _on_search_line_edit_text_changed(new_text: String) -> void:
	pass

func _on_component_controller_move_button_button_down(section_key: StringName, index_from: int, comp_editor: IS.EditBoxContainer) -> void:
	var section_box_container: ArrangableBoxContainer = sections_controls[section_key].box
	section_box_container.grab_element(comp_editor, index_from)

func _on_component_controller_move_button_button_up(section_key: StringName, comp_editor: IS.EditBoxContainer) -> void:
	var section_box_container: ArrangableBoxContainer = sections_controls[section_key].box
	section_box_container.release_element()

func _on_panel_mouse_entered(panel: PanelContainer) -> void:
	panel.self_modulate.a = 1.0

func _on_panel_mouse_exited(panel: PanelContainer) -> void:
	panel.self_modulate.a = .0



class ComponentInfo extends Resource:
	@export var index: int
	@export var component_res_id: StringName
	@export var component_res_owner: ComponentRes
	@export var components_ress: Array[UsableRes]
	
	func _init(_index: int, _component_res_owner: ComponentRes) -> void:
		index = _index
		component_res_id = _component_res_owner.get_classname()
		component_res_owner = _component_res_owner
	
	func append_component_res(value: ComponentRes) -> void:
		components_ress.append(value)

class ArrangableBoxContainer extends VBoxContainer:
	
	signal grab_started(element: Control, index_from: int)
	signal grab_released(index_from: int, index_to: Variant)
	
	@export var owner_control: MarginContainer
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
					var comp_edit: IS.EditBoxContainer = get_child(index)
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




