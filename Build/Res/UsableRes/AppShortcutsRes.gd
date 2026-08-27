#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright Â© 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
##	This program is free software: you can redistribute it and/or modify   ##
##	it under the terms of the GNU General Public License as published by   ##
##	the Free Software Foundation, either version 3 of the License, or	   ##
##	(at your option) any later version.									   ##
##																		   ##
##	This program is distributed in the hope that it will be useful,		   ##
##	but WITHOUT ANY WARRANTY; without even the implied warranty of		   ##
##	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the		   ##
##	GNU General Public License for more details.						   ##
##																		   ##
##	You should have received a copy of the GNU General Public License	   ##
##	along with this program. If not, see <https://www.gnu.org/licenses/>.  ##
#############################################################################
class_name AppShortcutsRes extends UsableRes

static var _default_select_container_shortcuts: Dictionary[StringName, Array] = {
	&"delete": [ShortcutNode.new_shortcut(Key.KEY_DELETE), &"delete_selected_vals"],
	&"cut": [ShortcutNode.new_shortcut(Key.KEY_X, true), &"copy_selected_vals", [true]],
	&"copy": [ShortcutNode.new_shortcut(Key.KEY_C, true), &"copy_selected_vals", [false]],
	&"past": [ShortcutNode.new_shortcut(Key.KEY_V, true), &"past_selected_vals"],
	&"duplicate": [ShortcutNode.new_shortcut(Key.KEY_D, true), &"duplicate_selected_vals"],
	&"select_all": [ShortcutNode.new_shortcut(Key.KEY_A, true), &"select_all"],
	&"deselect_all": [ShortcutNode.new_shortcut(Key.KEY_A, false, false, true), &"deselect_all"],
	&"select_invert": [ShortcutNode.new_shortcut(Key.KEY_I, true), &"select_inverse"],
	&"select_linked": [ShortcutNode.new_shortcut(Key.KEY_L, true), &"select_linked"],
	&"select_random": [ShortcutNode.new_shortcut(Key.KEY_R, true), &"select_random"]
}

static var _default_global_shortcuts: Dictionary[StringName, Array] = {
	&"left": [ShortcutNode.new_shortcut(Key.KEY_LEFT), &"frame_jump", [-1]],
	&"right": [ShortcutNode.new_shortcut(Key.KEY_RIGHT), &"frame_jump", [1]],
	&"jump_left": [ShortcutNode.new_shortcut(Key.KEY_LEFT, false, true), &"frame_jump", [-10]],
	&"jump_right": [ShortcutNode.new_shortcut(Key.KEY_RIGHT, false, true), &"frame_jump", [10]],
	&"spacial_left": [ShortcutNode.new_shortcut(Key.KEY_LEFT, true), &"frame_spacial", [-1]],
	&"spacial_right": [ShortcutNode.new_shortcut(Key.KEY_RIGHT, true), &"frame_spacial", [1]],
	&"play": [ShortcutNode.new_shortcut(Key.KEY_SPACE), &"play_and_stop"],
	
	&"new": [ShortcutNode.new_shortcut(Key.KEY_N, true), &"new"],
	&"open": [ShortcutNode.new_shortcut(Key.KEY_O, true), &"open"],
	&"save": [ShortcutNode.new_shortcut(Key.KEY_S, true), &"save"],
	&"save_as": [ShortcutNode.new_shortcut(Key.KEY_S, true, true, false), &"save_as"],
	&"undo": [ShortcutNode.new_shortcut(Key.KEY_Z, true), &"undo"],
	&"redo": [ShortcutNode.new_shortcut(Key.KEY_Z, true, true), &"redo"],
	&"exit": [ShortcutNode.new_shortcut(Key.KEY_Q, true), &"exit"],
	
	&"toggle_fullscreen": [ShortcutNode.new_shortcut(Key.KEY_F1), &"toggle_fullscreen"],
	&"report_bugs": [ShortcutNode.new_shortcut(Key.KEY_F2), &"report_bugs"],
}

static var _default_media_explorer_shortcuts: Dictionary[StringName, Array] = _default_select_container_shortcuts

static var _default_viewport_shortcuts: Dictionary[StringName, Array] = _default_select_container_shortcuts

static var _default_timeline_shortcuts: Dictionary[StringName, Array] = _default_select_container_shortcuts.merged({
	&"switch_edit_mode": [ShortcutNode.new_shortcut(Key.KEY_TAB), &"switch_edit_mode"],
	&"enter_clip": [ShortcutNode.new_shortcut(Key.KEY_ENTER), &"enter_clip"],
	&"exit_clip": [ShortcutNode.new_shortcut(Key.KEY_BACKSPACE), &"exit_clip"],
	
	&"create_parent": [ShortcutNode.new_shortcut(Key.KEY_P, false, true), &"create_parent"],
	&"reparent": [ShortcutNode.new_shortcut(Key.KEY_R, false, true), &"reparent_clip"],
	&"parent_up": [ShortcutNode.new_shortcut(Key.KEY_U, false, true), &"parent_up", [1]],
	&"clear_parents": [ShortcutNode.new_shortcut(Key.KEY_C, false, true), &"clear_parents"],
	
	&"open_graph": [ShortcutNode.new_shortcut(Key.KEY_G, true), &"open_graph_editors"],
	&"close_graph": [ShortcutNode.new_shortcut(Key.KEY_G, false, false, true), &"close_graph_editors"],
	
	&"save_presets": [ShortcutNode.new_shortcut(Key.KEY_S, false, false, true), &"save_presets", [false]],
	&"save_global_presets": [ShortcutNode.new_shortcut(Key.KEY_S, false, true, true), &"save_presets", [true]],
	
	&"split_l": [ShortcutNode.new_shortcut(Key.KEY_Z), &"split_clips", [true, false]],
	&"split": [ShortcutNode.new_shortcut(Key.KEY_X), &"split_clips", [true, true]],
	&"split_r": [ShortcutNode.new_shortcut(Key.KEY_C), &"split_clips", [false, true]]
})

static var _default_curve_editor_shortcuts: Dictionary[StringName, Array] = _default_select_container_shortcuts.merged({
	&"visible_x": [ShortcutNode.new_shortcut(Key.KEY_X), &"change_channel_visibility", [0]],
	&"visible_y": [ShortcutNode.new_shortcut(Key.KEY_Y), &"change_channel_visibility", [1]],
	&"visible_z": [ShortcutNode.new_shortcut(Key.KEY_Z), &"change_channel_visibility", [2]],
	&"visible_w": [ShortcutNode.new_shortcut(Key.KEY_W), &"change_channel_visibility", [3]]
})

static var _default_all_shortcuts: Dictionary[StringName, Dictionary] = {
	&"Global": _default_global_shortcuts,
	&"Explorer": _default_media_explorer_shortcuts,
	&"Viewport": _default_viewport_shortcuts,
	&"Timeline": _default_timeline_shortcuts,
	&"Curve Editor": _default_curve_editor_shortcuts,
}


func _init() -> void:
	use_global_variables_as_properties = false
	for key: StringName in _default_all_shortcuts:
		register_prop(key, _default_all_shortcuts[key].duplicate_deep(DeepDuplicateMode.DEEP_DUPLICATE_ALL))

func load_shortcuts_to(shortcut_node: ShortcutNode) -> void:
	if properties.has(shortcut_node.key):
		shortcut_node.set_shortcuts(get_prop(shortcut_node.key))
	else:
		register_prop(shortcut_node.key, shortcut_node.get_shortcuts())

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	var shortcuts_cont:= ShortcutsCommandsContainer.new()
	for prop_key: StringName in properties:
		shortcuts_cont.add_controller(prop_key, get_prop(prop_key), _default_all_shortcuts[prop_key])
	return {&"Shortcuts": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, [shortcuts_cont])}

func create_shortcuts_container() -> ShortcutsContainer:
	return ShortcutsContainer.new(self)

class ShortcutsCommandsContainer extends VBoxContainer:
	
	static var val_comp_method: Callable =\
		func(default: InputEventKey, new_val: InputEventKey) -> bool:
			return default.is_match(new_val)
	
	var categories: Dictionary[String, Category]
	var category_items: Dictionary[String, Array]

	signal shortcut_selected(text: StringName)
	
	func add_controller(key: StringName, shortcuts: Dictionary, default: Dictionary) -> void:
		
		var category: Category = IS.create_category(true, key, Color.TRANSPARENT, Vector2.ZERO, false)
		
		category.is_expanded = true
		
		var items: Array[Dictionary] = []
		
		for shortcut_key: StringName in shortcuts:
			
			var shortcut: Shortcut = shortcuts[shortcut_key][0]
			var event: InputEventKey = shortcut.events[0]
			
			var default_shortcut: Shortcut = default[shortcut_key][0]
			var default_event: InputEventKey = default_shortcut.events[0]
			
			var sh_edit_cont: EditContainer = IS.create_edit_cont(shortcut_key)
			sh_edit_cont.curr_val = event
			sh_edit_cont.default_val = default_event
			sh_edit_cont.resetable = true
			sh_edit_cont.method_compare = val_comp_method
			
			var switch_btn:= SwitchButton.new()
			switch_btn.curr_event = event
			switch_btn.switched_to.connect(
				func _on_switch_btn_switched_to(event: InputEventKey) -> void:
					sh_edit_cont.set_curr_value(event)
			)

			sh_edit_cont.name_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			
			sh_edit_cont.name_label.gui_input.connect(
				func(event: InputEvent) -> void:
					if event is InputEventMouseButton and event.is_pressed():
						if event.button_index == MOUSE_BUTTON_LEFT:
							shortcut_selected.emit(switch_btn.curr_event.as_text())
			)
			
			sh_edit_cont.val_changed.connect(
				func _on_sh_edit_cont_val_changed(new_val: Variant) -> void:
					shortcut.events = [new_val]
					switch_btn.curr_event = new_val
					switch_btn.update_ui()
			)
			
			sh_edit_cont.add_child(switch_btn)
			category.add_content(sh_edit_cont)
			
			items.append({edit_cont = sh_edit_cont, label = String(shortcut_key).to_lower()})
			
			IS.expand(sh_edit_cont)
			IS.expand(switch_btn)
		
		categories[key] = category
		category_items[key] = items
		
		add_child(category)
	
	func filter(search_query: String) -> void:
		
		var query: String = search_query.strip_edges().to_lower()
		
		for cat_key: String in categories:
			
			var category: Category = categories[cat_key]
			var items: Array = category_items[cat_key]
			var any_visible: bool = false
			
			for item: Dictionary in items:
				var edit_cont: EditContainer = item.edit_cont
				var is_finded: bool = query.is_empty() or StringHelper.fuzzy_search(query, item.label)
				edit_cont.visible = is_finded
				any_visible = any_visible or is_finded
			
			category.visible = any_visible


	class SwitchButton extends Button:
		
		signal switched_to(event: InputEventKey)
		var curr_event: InputEventKey
		
		func _init() -> void:
			toggle_mode = true
			IS.set_base_settings(self)
			IS.set_button_style(self, IS.style_transparent, null, IS.style_panel)
			IS.set_font_colors(self)
			pressed.connect(_on_button_pressed)
		
		func _ready() -> void:
			update_ui()
			deactivate()
		
		func _input(event: InputEvent) -> void:
			if event is InputEventKey:
				if event.is_pressed():
					switch(event)
			
			elif event is InputEventMouseButton:
				if event.button_index not in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP] and event.is_pressed():
					if button_pressed:
						button_pressed = false
						_on_button_pressed()
		
		func update_ui() -> void:
			if curr_event:
				text = curr_event.as_text()
		
		func activate() -> void:
			text = "..."
			set_process_input(true)
		
		func deactivate() -> void:
			set_process_input(false)
			update_ui()

		func switch(to: InputEventKey) -> void:
			curr_event = to
			update_ui()
			switched_to.emit(to)
		
		func _on_button_pressed() -> void:
			if button_pressed:
				activate()
			else:
				deactivate()
		
		func _is_modifier_only(event: InputEventKey) -> bool:
			var kc = event.keycode
			return kc == KEY_CTRL or kc == KEY_SHIFT or kc == KEY_ALT or kc == KEY_META

class ShortcutsActiveKeyContainer extends VBoxContainer:
	var shortcuts_container: ShortcutsCommandsContainer
	var rows: Dictionary[String, Label] = {}
	var rows_box: VBoxContainer
	 
	func _init(container: ShortcutsCommandsContainer = null) -> void:
		shortcuts_container = container
		var col_header := IS.create_box_container(16, false, {size_flags_horizontal = Control.SIZE_EXPAND_FILL})
		
		var panel_col_label := IS.create_label("Panel", "", IS.label_settings_main)
		panel_col_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel_col_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var commands_col_label := IS.create_label("Commands", "", IS.label_settings_main)
		commands_col_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		commands_col_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		col_header.add_child(panel_col_label)
		col_header.add_child(commands_col_label)
		add_child(col_header)
		add_child(IS.create_h_line_panel())
		
		var scroll := ScrollContainer.new()
		IS.expand(scroll, true, true)
		
		rows_box = VBoxContainer.new()
		IS.expand(rows_box, true, false)
		scroll.add_child(rows_box)
		add_child(scroll)
		
		if shortcuts_container:
			_build_rows()
		
		clear()
	 
	func set_shortcuts_container(container: ShortcutsCommandsContainer) -> void:
		shortcuts_container = container
		for child in rows_box.get_children():
			child.queue_free()
		rows.clear()
		
		_build_rows()
		clear()
	 
	 
	func _build_rows() -> void:
		for category_key: String in shortcuts_container.categories:
			var row := IS.create_box_container(16, false, {size_flags_horizontal = Control.SIZE_EXPAND_FILL})
			
			var panel_label := IS.create_label(category_key, "", IS.label_settings_main)
			panel_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			panel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			IS.set_font_colors(panel_label)
			
			var commands_label := Label.new()
			commands_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			commands_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			IS.set_font_colors(commands_label)
			
			row.add_child(panel_label)
			row.add_child(commands_label)
			rows_box.add_child(row)
			
			rows[category_key] = commands_label
	 
	func show_active_key(key_string: String) -> void:
		var normalized: String = key_string.strip_edges()
		
		if shortcuts_container == null or normalized.is_empty():
			_clear_rows()
			return
		
		for category_key: String in shortcuts_container.category_items:
			if not rows.has(category_key):
				continue
			
			var items: Array = shortcuts_container.category_items[category_key]
			var matched_labels: Array[String] = []
			
			for item: Dictionary in items:
				var edit_cont: EditContainer = item.edit_cont
				var event: InputEventKey = edit_cont.curr_val
				
				if event and _key_string_matches(event, normalized):
					matched_labels.append(String(item.label).capitalize())
			
			rows[category_key].text = ", ".join(matched_labels)
	 
	func clear() -> void:
		_clear_rows()
	
	func _clear_rows() -> void:
		for category_key: String in rows:
			rows[category_key].text = ""
	
	func _key_string_matches(event: InputEventKey, key_string: String) -> bool:
		if event.as_text() == key_string:
			return true
		
		var event_tokens: Array = event.as_text().to_lower().split("+")
		var input_tokens: Array = key_string.to_lower().split("+")
		
		event_tokens.sort()
		input_tokens.sort()
		
		return event_tokens == input_tokens

class ShortcutsContainer extends MarginContainer:
	
	var commands_container: ShortcutsCommandsContainer
	var active_key_container: ShortcutsActiveKeyContainer
	var search_line: LineEdit
	var key_badge: Label

	func _init(shortcuts: AppShortcutsRes) -> void:
		IS.expand(self, true, true)
		
		var shortcut_panel := IS.create_panel_container(Vector2.ZERO, IS.style_body)
		IS.expand(shortcut_panel, true, true)
		
		var margin := IS.create_margin_container()
		
		var split_cont: SplitContainer = IS.create_split_container()
		IS.expand(split_cont, true, true)
		
		var active_key_panel := IS.create_panel_container(Vector2.ZERO, IS.style_panel)
		IS.expand(active_key_panel, true, true)
		
		var active_key_margin := IS.create_margin_container()
		IS.expand(active_key_margin, true, true)
		
		var active_key_vbox := IS.create_box_container(8, true)
		IS.expand(active_key_vbox, true, true)
		
		var active_key_header := IS.create_box_container(8, false, {size_flags_horizontal = Control.SIZE_EXPAND_FILL})
		
		var active_key_title := IS.create_label("Active Key: ", "", IS.label_settings_main)
		active_key_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		active_key_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		key_badge = Label.new()
		key_badge.custom_minimum_size = Vector2(36, 24)
		key_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		IS.set_font_colors(key_badge)
		
		active_key_header.add_child(active_key_title)
		active_key_header.add_child(key_badge)
		
		commands_container = ShortcutsCommandsContainer.new()
		for key: StringName in shortcuts.properties:
			commands_container.add_controller(
				key,
				shortcuts.get_prop(key),
				AppShortcutsRes._default_all_shortcuts[key]
			)
		commands_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		commands_container.custom_minimum_size.x = 0
		commands_container.size_flags_stretch_ratio = 1.0
		
		active_key_container = ShortcutsActiveKeyContainer.new(commands_container)
		IS.expand(active_key_container, true, true)
		
		active_key_vbox.add_child(active_key_header)
		active_key_vbox.add_child(active_key_container)
		
		active_key_margin.add_child(active_key_vbox)
		active_key_panel.add_child(active_key_margin)
		
		var v_line := IS.create_v_line_panel()
		
		var commands_panel := IS.create_panel_container(Vector2.ZERO, IS.style_panel)
		IS.expand(commands_panel, true, true)
		
		var commands_margin := IS.create_margin_container()
		IS.expand(commands_margin, true, true)
		
		var commands_vbox := IS.create_box_container(16, true)
		IS.expand(commands_vbox, true, true)
		
		search_line = IS.create_line_edit("Search", "", null)
		
		var commands_label := IS.create_label("Commands: ", "", IS.label_settings_main)
		commands_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		IS.expand(commands_label, true, false)
		
		var top_commands_container := IS.create_box_container(16, false, {size_flags_horizontal = Control.SIZE_EXPAND_FILL})
		
		search_line.text_changed.connect(
			func(new_text: String) -> void:
				commands_container.filter(new_text)
		)
		
		var scroll := ScrollContainer.new()
		IS.expand(scroll, true, true)
		scroll.add_child(commands_container)
		
		top_commands_container.add_child(commands_label)
		top_commands_container.add_child(search_line)
		commands_vbox.add_child(top_commands_container)
		commands_vbox.add_child(scroll)
		
		commands_margin.add_child(commands_vbox)
		commands_panel.add_child(commands_margin)
		
		split_cont.add_child(active_key_panel)
		split_cont.add_child(v_line)
		split_cont.add_child(commands_panel)
		
		margin.add_child(split_cont)
		shortcut_panel.add_child(margin)
		add_child(shortcut_panel)
	
	
	func show_active_key(key_string: String) -> void:
		key_badge.text = key_string
		active_key_container.show_active_key(key_string)
