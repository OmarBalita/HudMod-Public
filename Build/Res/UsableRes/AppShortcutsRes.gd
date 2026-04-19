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
	&"report_bugs": [ShortcutNode.new_shortcut(Key.KEY_F2), &"report_bugs"]
}

static var _default_timeline_shortcuts: Dictionary[StringName, Array] = _default_select_container_shortcuts.merged({
	&"switch_edit_mode": [ShortcutNode.new_shortcut(Key.KEY_TAB), &"switch_edit_mode"],
	&"enter_clip": [ShortcutNode.new_shortcut(Key.KEY_ENTER), &"enter_clip"],
	&"exit_clip": [ShortcutNode.new_shortcut(Key.KEY_BACKSPACE), &"exit_clip"],
	
	&"create_parent": [ShortcutNode.new_shortcut(Key.KEY_P, false, true), &"create_parent"],
	&"reparent": [ShortcutNode.new_shortcut(Key.KEY_R, false, true), &"reparent_clip"],
	&"parent_up": [ShortcutNode.new_shortcut(Key.KEY_U, false, true), &"parent_up"],
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
	&"Timeline": _default_timeline_shortcuts,
	&"Curve Editor": _default_curve_editor_shortcuts
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

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var shortcuts_cont:= ShortcutsContainer.new()
	for prop_key: StringName in properties:
		shortcuts_cont.add_controller(prop_key, get_prop(prop_key), _default_all_shortcuts[prop_key])
	return {&"Shortcuts": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, [shortcuts_cont])}


class ShortcutsContainer extends VBoxContainer:
	
	static var val_comp_method: Callable =\
		func(default: InputEventKey, new_val: InputEventKey) -> bool:
			return default.is_match(new_val)
	
	func add_controller(key: StringName, shortcuts: Dictionary, default: Dictionary) -> void:
		
		var category: Category = IS.create_category(true, key, Color.TRANSPARENT, Vector2.ZERO, false)
		
		category.is_expanded = true
		
		for shortcut_key: StringName in shortcuts:
			
			var shortcut: Shortcut = shortcuts[shortcut_key][0]
			var event: InputEventKey = shortcut.events[0]
			
			var default_shortcut: Shortcut = default[shortcut_key][0]
			var default_event: InputEventKey = default_shortcut.events[0]
			
			var sh_edit_cont: IS.EditBoxContainer = IS.create_edit_box(shortcut_key, Vector2())
			sh_edit_cont.curr_val = event
			sh_edit_cont.default_val = default_event
			sh_edit_cont.resetable = true
			sh_edit_cont.value_comp_method = val_comp_method
			
			var switch_btn:= SwitchButton.new()
			switch_btn.curr_event = event
			switch_btn.switched_to.connect(
				func _on_switch_btn_switched_to(event: InputEventKey) -> void:
					sh_edit_cont.set_curr_val(event)
			)
			
			sh_edit_cont.val_changed.connect(
				func _on_sh_edit_cont_val_changed(usable_res: UsableRes, key: StringName, new_val: Variant) -> void:
					shortcut.events = [new_val]
					switch_btn.curr_event = new_val
					switch_btn.update_ui()
			)
			
			sh_edit_cont.add_child(switch_btn)
			category.add_content(sh_edit_cont)
			
			IS.expand(sh_edit_cont)
			IS.expand(switch_btn)
		
		add_child(category)


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





