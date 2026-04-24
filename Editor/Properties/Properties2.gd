class_name Properties2 extends EditorControl

signal property_changed()

@export_group("Theme")
@export_subgroup("Texture", "texture")
@export var texture_add: Texture2D
@export var texture_search: Texture2D
@export var texture_enable: Texture2D
@export var texture_disable: Texture2D
@export var texture_delete: Texture2D
@export var texture_drag: Texture2D

var curr_clip_ress: Array[MediaClipRes]
var curr_focused_media_res: MediaClipRes

var curr_shown_section: StringName

var curr_displayed_components: Dictionary[StringName, Array]

var notification_label: Label
var sections_menu: Menu
var components_body: MarginContainer
var sections_controls: Dictionary[StringName, Dictionary]

var media_properties_panel_container: PanelContainer


func _ready_editor() -> void:
	super()
	
	notification_label = IS.create_label("", IS.label_settings_main)
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_update_notification_label()
	
	components_body = IS.create_margin_container(0, 0, 0, 0)
	
	body.add_child(notification_label)
	body.add_child(components_body)
	
	IS.expand(components_body, true, true)
	
	resized.connect(_on_resized)
	
	EditorServer.time_line2.layers_body.selected_changed.connect(_on_layers_body_selected_changed)

func _gui_input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		
		if event.ctrl_pressed:
			return
		
		if not sections_controls.has(curr_shown_section):
			return
		
		var scroll_cont: ScrollContainer = sections_controls[curr_shown_section].scroll_cont
		
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_cont.scroll_vertical += 30.
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_cont.scroll_vertical -= 30.


func popup_section_components(section_key: StringName, pop_from: Control = null) -> void:
	
	var options: Dictionary[MenuOption, Array] = {}
	var section_comps: Dictionary[StringName, Dictionary] = ClassServer.comps_get_section_comps(section_key)
	
	for subsection_key: StringName in section_comps:
		var subsection_comps: Dictionary[StringName, Dictionary] = section_comps[subsection_key]
		var subsection_menuoption: MenuOption = MenuOption.new(subsection_key)
		options[subsection_menuoption] = []
		
		for comp_classname: StringName in subsection_comps:
			var comp_info: Dictionary[StringName, Variant] = subsection_comps[comp_classname]
			var comp_script: Script = comp_info.script
			
			options[subsection_menuoption].append(MenuOption.new(
				comp_classname,
				ClassServer.classname_get_icon(comp_classname),
				add_component.bind(section_key, comp_script)
			))
	
	var components_popuped_menu: PopupedCategoriesMenu = IS.create_popuped_categories_menu(options)
	get_tree().current_scene.add_child(components_popuped_menu)
	await components_popuped_menu.categories_menu_popuped
	components_popuped_menu.popup(pop_from.global_position + Vector2(0, pop_from.size.y))

func add_component(section_key: StringName, script: Script) -> void:
	for media_res: MediaClipRes in curr_clip_ress:
		var new_component_res:= ComponentRes.new()
		new_component_res.set_script(script)
		media_res.add_component(section_key, new_component_res)
	update_properties(section_key)

func set_component_enabled(comp_info: ComponentInfo) -> void:
	var target: bool = not comp_info.component_res_owner.enabled
	for index: int in curr_clip_ress.size():
		var comp_res: ComponentRes = comp_info.components_ress[index]
		comp_res.set_enabled(target)

func delete_component(section_key: StringName, comp_info: ComponentInfo, edit_box_container: EditBoxContainer = null) -> void:
	for index: int in curr_clip_ress.size():
		var media_res: MediaClipRes = curr_clip_ress[index]
		media_res.erase_component(section_key, comp_info.components_ress[index])
	if edit_box_container:
		edit_box_container.queue_free()
		_update_margin()
	else:
		update_properties(section_key)

func move_component(section_key: StringName, index_from: int, index_to: int) -> void:
	var media_res_as_owner: MediaClipRes = curr_clip_ress.get(0)
	media_res_as_owner.move_component(section_key, index_from, index_to)
	update_properties(section_key)

func update_component_method(section_key: StringName, comp_info: ComponentInfo, target_method_type: ComponentRes.MethodType) -> void:
	for comp_res: ComponentRes in comp_info.components_ress:
		comp_res.set_method_type(target_method_type)

func navigate_to_section(section_key: StringName) -> void:
	for _section_key: StringName in sections_controls:
		sections_controls.get(_section_key).root.visible = section_key == _section_key
	curr_shown_section = section_key
	_update_margin()

func update_properties(section_key: StringName = &"") -> void:
	
	var update_info: Dictionary[StringName, Variant] = _update_displayed_components()
	
	var new_clip_res: Array[MediaClipRes] = update_info.new_clip_res
	var new_focused_clip_res: MediaClipRes = update_info.new_focused_clip_res
	
	if section_key.is_empty():
		if curr_clip_ress != new_clip_res or curr_focused_media_res != new_focused_clip_res:
			curr_clip_ress = new_clip_res
			curr_focused_media_res = new_focused_clip_res
			_display_components_by_sections()
	else: _display_section_components(section_key, true)
	
	_update_margin()

func update_media_properties(info: Dictionary[StringName, String]) -> void:
	curr_clip_ress.clear()
	
	_clear_controls()
	
	var media_type_title: String = info.get(&"title")
	sections_menu = IS.create_menu([MenuOption.new(media_type_title)])
	header.add_child(sections_menu)
	info.erase(&"title")
	
	var panel_container: PanelContainer = IS.create_panel_container()
	var margin_container: MarginContainer = IS.create_margin_container(12, 12, 12, 12)
	var box_container: BoxContainer = IS.create_box_container(0, true)
	
	box_container.clip_contents = true
	
	var key_panel_gui_input_func: Callable = func(event: InputEvent, val_as_string: String) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				DisplayServer.clipboard_set(val_as_string)
	
	for key: StringName in info.keys():
		var val_as_string: String = info.get(key)
		
		var key_panel_container: PanelContainer = IS.create_panel_container(Vector2.ZERO, IS.style_body)
		var key_margin_container: MarginContainer = IS.create_margin_container()
		var split_container: SplitContainer = IS.create_split_container()
		var key_label: Label = IS.create_name_label(key.capitalize())
		var val_label: Label = IS.create_label(val_as_string, IS.label_settings_main, {})
		
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
	var layers_body: TimeLine2.LayersSelectContainer = EditorServer.time_line2.layers_body
	var selected_clips: Dictionary[int, Dictionary] = layers_body.selected
	
	curr_displayed_components.clear()
	
	if selected_clips.is_empty() or not layers_body.is_focused_exists():
		return {
			&"new_clip_res": [] as Array[MediaClipRes],
			&"new_focused_clip_res": null
		}
	
	var focused_clip_res: MediaClipRes = layers_body.get_focused_val()
	var focused_components: Dictionary[String, Array] = focused_clip_res.get_components()
	
	var new_clip_res: Array[MediaClipRes]
	var new_displayed_components: Dictionary[StringName, Array]
	var new_displayed_mediaclipres: Dictionary[StringName, ComponentInfo]
	
	for section_key: StringName in ClassServer.comps_sections_infos:
		
		var new_section_components: Array[ComponentInfo]
		new_displayed_components[section_key] = new_section_components
		
		if focused_components.has(section_key):
			var section_components: Array = focused_components.get(String(section_key))
			for index: int in section_components.size():
				var component_res: ComponentRes = section_components[index]
				new_section_components.append(ComponentInfo.new(index, component_res))
	
	
	for layer_idx: int in selected_clips:
		
		var port: Dictionary = selected_clips[layer_idx]
		
		for frame: int in port:
		
			var clip_res: MediaClipRes = port[frame]
			var components: Dictionary[String, Array] = clip_res.get_components()
			
			var sections: Array = MediaServer.object_clip_info[clip_res.get_classname()].sections
			var next_displayed_components: Dictionary[StringName, Array]
			
			new_clip_res.append(clip_res)
			
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
	
	return {&"new_clip_res": new_clip_res, &"new_focused_clip_res": focused_clip_res}

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
	
	var add_and_search_split_cont: SplitContainer = IS.create_split_container()
	
	var scroll_cont: ScrollContainer = IS.create_scroll_container()
	var margin_cont: MarginContainer = IS.create_margin_container(0, 12, 0, 0)
	var header_and_comps_split_cont: SplitContainer = IS.create_split_container(2, true)
	var header_cont: BoxContainer = IS.create_box_container(2, true)
	var box_cont: ArrangableBoxContainer = ArrangableBoxContainer.new(body, scroll_cont)
	
	scroll_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	box_cont.grab_released.connect(func(index_from: int, index_to: Variant) -> void:
		_on_section_box_container_grab_released(section_key, index_from, index_to)
	)
	
	var add_component_button: Button = IS.create_button("", texture_add, true)
	var search_line_edit: LineEdit = IS.create_line_edit("Search for %s Component" % section_key.capitalize(), "", texture_search)
	
	add_component_button.pressed.connect(popup_section_components.bind(section_key, add_component_button))
	search_line_edit.text_changed.connect(_on_search_line_edit_text_changed)
	
	add_and_search_split_cont.add_child(add_component_button)
	add_and_search_split_cont.add_child(search_line_edit)
	
	header_and_comps_split_cont.add_child(header_cont)
	header_and_comps_split_cont.add_child(box_cont)
	margin_cont.add_child(header_and_comps_split_cont)
	scroll_cont.add_child(margin_cont)
	
	split_container.add_child(add_and_search_split_cont)
	split_container.add_child(scroll_cont)
	components_body.add_child(split_container)
	
	IS.expand(header_and_comps_split_cont)
	IS.expand(margin_cont)
	IS.expand(split_container)
	
	sections_controls[section_key] = {
		&"root": split_container,
		&"header": header_cont,
		&"box": box_cont,
		&"margin_cont": margin_cont,
		&"scroll_cont": scroll_cont,
		&"search_line": search_line_edit
	}
	
	var section_components_info: Array = curr_displayed_components[section_key]
	
	for comp_info: ComponentInfo in section_components_info:
		_spawn_component_controller(section_key, comp_info)
	
	var media_res_section_key: StringName = curr_focused_media_res.get_properties_section()
	if media_res_section_key.is_empty() or section_key != media_res_section_key:
		header_cont.hide()
		return
	
	var main_classname: StringName = curr_focused_media_res.get_classname()
	
	for media_res: MediaClipRes in curr_clip_ress:
		if media_res.get_classname() != main_classname:
			header_cont.hide()
			return
	
	var usable_ress: Array[UsableRes]
	for media_res: MediaClipRes in curr_clip_ress: usable_ress.append(media_res)
	var mediares_editbox: EditBoxContainer = IS.get_edit_box_from(curr_focused_media_res.create_custom_edit(main_classname, curr_focused_media_res, usable_ress, search_line_edit))
	header_cont.add_child(mediares_editbox)

func _spawn_component_controller(section_key: StringName, comp_info: ComponentInfo) -> void:
	var curr_section_controls: Dictionary = sections_controls[section_key]
	
	var comp_res_owner: ComponentRes = comp_info.component_res_owner
	comp_res_owner.res_changed.connect(property_changed.emit)
	
	var comp_controllers: Array[Control] = ComponentRes.create_custom_edit(comp_info.component_res_id, comp_res_owner, comp_info.components_ress, curr_section_controls.search_line)
	var comp_editor: EditBoxContainer = IS.get_edit_box_from(comp_controllers)
	var editor_header: BoxContainer = comp_editor.header
	
	comp_editor.set_meta(&"component_res", comp_res_owner)
	comp_editor.keyframable = false
	
	if not comp_res_owner.get_forced():
		
		if comp_res_owner.has_method_type():
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
		
		var enable_button: IS.CustomTextureButton = IS.create_texture_button(texture_enable, null, texture_disable, true)
		enable_button.button_pressed = not comp_res_owner.enabled
		enable_button.pressed.connect(set_component_enabled.bind(comp_info))
		editor_header.add_child(enable_button)
		
		var delete_button: IS.CustomTextureButton = IS.create_texture_button(texture_delete)
		delete_button.pressed.connect(delete_component.bind(section_key, comp_info, comp_editor))
		editor_header.add_child(delete_button)
		
		if curr_clip_ress.size() == 1:
			var move_button: IS.CustomTextureButton = IS.create_texture_button(texture_drag)
			move_button.button_down.connect(_on_component_controller_move_button_button_down.bind(section_key, comp_info.index, comp_editor))
			move_button.button_up.connect(_on_component_controller_move_button_button_up.bind(section_key, comp_editor))
			editor_header.add_child(move_button)
	
	curr_section_controls.box.add_child(comp_editor)
	
	var update_usable_ress_func: Callable = func(new_frame: int) -> void:
		var media_res: MediaClipRes = comp_res_owner.get_owner()
		
		var new_local_frame: int = clamp(new_frame - media_res.clip_pos, 0, media_res.length)
		comp_res_owner.update_controllers(new_local_frame)
	
	update_usable_ress_func.call(PlaybackServer.position)
	PlaybackServer.position_changed.connect(update_usable_ress_func)
	comp_editor.tree_exited.connect(func() -> void: PlaybackServer.position_changed.disconnect(update_usable_ress_func))

func _update_notification_label() -> String:
	var notif_text: String
	if not curr_displayed_components:
		if curr_clip_ress: notif_text = "The clips you selected do not have any shared property."
		else: notif_text = "At least one Clip must be selected to display its properties."
	notification_label.text = notif_text
	notification_label.visible = not notif_text.is_empty()
	return notif_text

func _update_margin() -> void:
	await get_tree().process_frame
	for section_key: String in sections_controls:
		var controls: Dictionary = sections_controls[section_key]
		var activate_margin_cond: bool = controls.header.size.y + controls.margin_cont.size.y > components_body.size.y - 16
		controls.margin_cont.add_theme_constant_override(&"margin_right", 12 if activate_margin_cond else 0)

func _on_resized() -> void:
	_update_margin()

func _on_layers_body_selected_changed() -> void:
	update_properties()

func _on_sections_menu_option_pressed(section_key: StringName) -> void:
	navigate_to_section(section_key)

func _on_section_box_container_grab_released(section_key: StringName, index_from: int, index_to: Variant) -> void:
	if index_to != null and index_from != index_to:
		move_component(section_key, index_from, index_to)

func _on_search_line_edit_text_changed(new_text: String) -> void:
	pass

func _on_component_controller_move_button_button_down(section_key: StringName, index_from: int, comp_editor: EditBoxContainer) -> void:
	var section_box_container: ArrangableBoxContainer = sections_controls[section_key].box
	section_box_container.grab_element(comp_editor, index_from)

func _on_component_controller_move_button_button_up(section_key: StringName, comp_editor: EditBoxContainer) -> void:
	var section_box_container: ArrangableBoxContainer = sections_controls[section_key].box
	section_box_container.release_element()

func _on_panel_mouse_entered(panel: PanelContainer) -> void:
	panel.self_modulate.a = 1.0

func _on_panel_mouse_exited(panel: PanelContainer) -> void:
	panel.self_modulate.a = .0



class ComponentInfo extends Resource:
	@export var index: int
	@export var component_res_id: StringName
	@export var component_res_owner: UsableRes
	@export var components_ress: Array[UsableRes]
	
	func _init(_index: int, _component_res_owner: UsableRes) -> void:
		index = _index
		component_res_id = _component_res_owner.get_classname()
		component_res_owner = _component_res_owner
	
	func append_component_res(value: UsableRes) -> void:
		components_ress.append(value)


