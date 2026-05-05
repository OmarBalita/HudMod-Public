#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
##  This program is free software: you can redistribute it and/or modify   ##
##  it under the terms of the GNU General Public License as published by   ##
##  the Free Software Foundation, either version 3 of the License, or      ##
##  (at your option) any later version.                                    ##
##                                                                         ##
##  This program is distributed in the hope that it will be useful,        ##
##  but WITHOUT ANY WARRANTY; without even the implied warranty of         ##
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the           ##
##  GNU General Public License for more details.                           ##
##                                                                         ##
##  You should have received a copy of the GNU General Public License      ##
##  along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
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
var scroll_cont: ScrollContainer
var components_body: MarginContainer
var sections_controls: Dictionary[StringName, Dictionary]

var media_properties_panel_container: PanelContainer


func _ready_editor() -> void:
	super()
	
	notification_label = IS.create_label("", "", IS.label_settings_main)
	notification_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_update_notification_label()
	
	scroll_cont = IS.create_scroll_container()
	components_body = IS.create_margin_container(0, 0, 0, 0)
	
	body.add_child(notification_label)
	scroll_cont.add_child(components_body)
	body.add_child(scroll_cont)
	
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
	
	var wanted_clip_res: MediaClipRes = curr_focused_media_res
	var duplicated_clip_ress_arr: Array[MediaClipRes] = curr_clip_ress.duplicate()
	var new_comps: Array[ComponentRes]
	
	for clip_res: MediaClipRes in duplicated_clip_ress_arr:
		var new_comp_res: ComponentRes = ComponentRes.new()
		new_comp_res.set_script(script)
		new_comps.append(new_comp_res)
	
	var do_method: Callable = func() -> void:
		for idx: int in duplicated_clip_ress_arr.size():
			var clip_res: MediaClipRes = duplicated_clip_ress_arr[idx]
			clip_res.add_component(section_key, new_comps[idx])
		try_update_properties_for(wanted_clip_res, section_key)
	
	var undo_method: Callable = func() -> void:
		for idx: int in duplicated_clip_ress_arr.size():
			var clip_res: MediaClipRes = duplicated_clip_ress_arr[idx]
			clip_res.erase_component(section_key, new_comps[idx])
		try_update_properties_for(wanted_clip_res, section_key)
	
	ProjectServer2.commit_action("add_components", do_method, undo_method)

func delete_component(section_key: StringName, comp_info: ComponentInfo, edit_cont: EditContainer = null) -> void:
	
	var wanted_clip_res: MediaClipRes = curr_focused_media_res
	var duplicated_clip_ress_arr: Array[MediaClipRes] = curr_clip_ress.duplicate()
	var deleted_comps: Array[UsableRes] = comp_info.components_ress.duplicate()
	var deleted_comps_indices: Array[int]
	
	for idx: int in deleted_comps.size():
		var comp_res: ComponentRes = deleted_comps[idx]
		var comp_idx: int = duplicated_clip_ress_arr[idx].get_section_comps_absolute(section_key).find(comp_res)
		deleted_comps_indices.append(comp_idx)
	
	var do_method: Callable = func() -> void:
		for idx: int in duplicated_clip_ress_arr.size():
			duplicated_clip_ress_arr[idx].remove_at_component(section_key, deleted_comps_indices[idx])
		try_update_properties_for(wanted_clip_res, section_key)
	
	var undo_method: Callable = func() -> void:
		for idx: int in duplicated_clip_ress_arr.size():
			var clip_res: MediaClipRes = duplicated_clip_ress_arr[idx]
			var comp_res: ComponentRes = deleted_comps[idx]
			clip_res.insert_component(section_key, comp_res, deleted_comps_indices[idx])
		try_update_properties_for(wanted_clip_res, section_key)
	
	ProjectServer2.commit_action("delete_components", do_method, undo_method)

func move_component(section_key: StringName, index_from: int, index_to: int) -> void:
	var media_res_as_owner: MediaClipRes = curr_clip_ress.get(0)
	
	var do_method: Callable = func() -> void:
		media_res_as_owner.move_component(section_key, index_from, index_to)
		try_update_properties_for(media_res_as_owner, section_key)
	
	var undo_method: Callable = func() -> void:
		media_res_as_owner.move_component(section_key, index_to, index_from)
		try_update_properties_for(media_res_as_owner, section_key)
	
	ProjectServer2.commit_action("move_component", do_method, undo_method)

func update_component_method(section_key: StringName, comp_info: ComponentInfo, target_method_type: ComponentRes.MethodType) -> void:
	
	var owner_comp: ComponentRes = comp_info.component_res_owner
	var comp_ress: Array[UsableRes] = comp_info.components_ress.duplicate()
	var comps_methods: Array[ComponentRes.MethodType]
	
	for comp_res: ComponentRes in comp_ress:
		comps_methods.append(comp_res.method_type)
	
	var do_method: Callable = func() -> void:
		for comp_res: ComponentRes in comp_ress:
			comp_res.set_method_type(target_method_type)
		_update_comp_editor_header_ui(owner_comp)
	
	var undo_method: Callable = func() -> void:
		for idx: int in comp_ress.size():
			comp_ress[idx].set_method_type(comps_methods[idx])
		_update_comp_editor_header_ui(owner_comp)
	
	ProjectServer2.commit_action("set_component_method", do_method, undo_method)

func set_component_enabled(comp_info: ComponentInfo) -> void:
	
	var owner_comp: ComponentRes = comp_info.component_res_owner
	var comp_ress: Array[UsableRes] = comp_info.components_ress.duplicate()
	var comps_enabled: Array[bool]
	
	for comp_res: ComponentRes in comp_ress:
		comps_enabled.append(comp_res.enabled)
	
	var target_enabled: bool = not comp_info.component_res_owner.enabled
	var undo_enabled: bool = not target_enabled
	
	var do_method: Callable = func() -> void:
		for comp_res: ComponentRes in comp_ress: comp_res.set_enabled(target_enabled)
		_update_comp_editor_header_ui(owner_comp)
	
	var undo_method: Callable = func() -> void:
		for idx: int in comp_ress.size(): comp_ress[idx].set_enabled(undo_enabled)
		_update_comp_editor_header_ui(owner_comp)
	
	ProjectServer2.commit_action("set_component_enabled", do_method, undo_method)

func _update_comp_editor_header_ui(comp_res: ComponentRes) -> void:
	if not EditorServer.has_usable_res_controllers(comp_res):
		return
	
	var edit_cont: EditContainer = EditorServer.get_usable_res_main_edit(comp_res)
	var header_ctrlrs: Dictionary[StringName, Control] = edit_cont.get_meta(&"header_ctrlrs")
	
	if header_ctrlrs.has(&"method_type"):
		header_ctrlrs.method_type.set_selected_id_manually(comp_res.method_type)
	
	if header_ctrlrs.has(&"enable"):
		header_ctrlrs.enable.button_pressed = not comp_res.enabled
		header_ctrlrs.enable.update_button()


func navigate_to_section(section_key: StringName) -> void:
	for _section_key: StringName in sections_controls:
		sections_controls.get(_section_key).root.visible = section_key == _section_key
	curr_shown_section = section_key
	_update_margin()

func try_update_properties_for(clip_res: MediaClipRes, section_key: StringName = &"") -> void:
	if clip_res == curr_focused_media_res: update_properties(section_key)

func update_properties(section_key: StringName = &"") -> void:
	
	var update_info: Dictionary[StringName, Variant] = _update_displayed_components()
	
	var new_clip_res: Array[MediaClipRes] = update_info.new_clip_res
	var new_focused_clip_res: MediaClipRes = update_info.new_focused_clip_res
	
	if section_key.is_empty():
		if curr_clip_ress != new_clip_res or curr_focused_media_res != new_focused_clip_res:
			curr_clip_ress = new_clip_res
			curr_focused_media_res = new_focused_clip_res
			_display_components_by_sections()
	else:
		_display_section_components(section_key, true)
	
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
		var val_label: Label = IS.create_label(val_as_string, "", IS.label_settings_main, {})
		
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
	var focused_components: Dictionary[StringName, Array] = focused_clip_res.get_components()
	
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
			var components: Dictionary[StringName, Array] = clip_res.get_components()
			
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
	
	split_container.visible = section_key == curr_shown_section
	scroll_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	box_cont.grab_released.connect(func(index_from: int, index_to: Variant) -> void:
		_on_section_box_container_grab_released(section_key, index_from, index_to)
	)
	
	var add_component_button: Button = IS.create_button("", texture_add, "New component", true)
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
	var mediares_edit_cont: EditContainer = curr_focused_media_res.create_custom_edit(main_classname, curr_focused_media_res, usable_ress, search_line_edit)
	header_cont.add_child(mediares_edit_cont)

func _spawn_component_controller(section_key: StringName, comp_info: ComponentInfo) -> void:
	var curr_section_controls: Dictionary = sections_controls[section_key]
	
	var comp_res_owner: ComponentRes = comp_info.component_res_owner
	if not comp_res_owner.res_changed.is_connected(property_changed.emit):
		comp_res_owner.res_changed.connect(property_changed.emit)
	
	var comp_editor: EditContainer = ComponentRes.create_custom_edit(comp_info.component_res_id, comp_res_owner, comp_info.components_ress, curr_section_controls.search_line)
	var editor_header: BoxContainer = comp_editor.header_cont
	
	comp_editor.set_meta(&"component_res", comp_res_owner)
	comp_editor.keyframable = false
	
	if not comp_res_owner.get_forced():
		
		var header_ctrlrs: Dictionary[StringName, Control] = {}
		
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
			header_ctrlrs[&"method_type"] = method_controller
		
		var enable_button: IS.CustomTextureButton = IS.create_texture_button(texture_enable, null, texture_disable, "Enable / Disable", true)
		enable_button.button_pressed = not comp_res_owner.enabled
		enable_button.pressed.connect(set_component_enabled.bind(comp_info))
		editor_header.add_child(enable_button)
		header_ctrlrs[&"enable"] = enable_button
		
		var delete_button: IS.CustomTextureButton = IS.create_texture_button(texture_delete, null, null, "Delete")
		delete_button.pressed.connect(delete_component.bind(section_key, comp_info, comp_editor))
		editor_header.add_child(delete_button)
		header_ctrlrs[&"delete"] = delete_button
		
		if curr_clip_ress.size() == 1:
			var move_button: IS.CustomTextureButton = IS.create_texture_button(texture_drag, null, null, "Sort")
			move_button.button_down.connect(_on_component_controller_move_button_button_down.bind(section_key, comp_info.index, comp_editor))
			move_button.button_up.connect(_on_component_controller_move_button_button_up.bind(section_key, comp_editor))
			editor_header.add_child(move_button)
			header_ctrlrs[&"move"] = move_button
		
		comp_editor.set_meta(&"header_ctrlrs", header_ctrlrs)
	
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

func _on_component_controller_move_button_button_down(section_key: StringName, index_from: int, comp_editor: EditContainer) -> void:
	var section_box_container: ArrangableBoxContainer = sections_controls[section_key].box
	section_box_container.grab_element(comp_editor, index_from)

func _on_component_controller_move_button_button_up(section_key: StringName, comp_editor: EditContainer) -> void:
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


