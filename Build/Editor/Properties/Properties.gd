class_name Properties extends EditorRect

var media_clips_selection_group:= EditorServer.media_clips_selection_group

func _ready() -> void:
	super()
	# Connections
	media_clips_selection_group.selected_objects_changed.connect(on_media_clips_selection_group_selected_objects_changed)


func open_properties(media_clips: Array[MediaClip], sections_keys: Array) -> void:
	
	IS.clear_children(header)
	IS.clear_children(body)
	await get_tree().process_frame
	
	if sections_keys:
		
		var options_info: Array[Dictionary] = TypeServer.get_sections_info(sections_keys)
		var sections_menu:= IS.create_menu(MenuOption.new_options_with_check_group(options_info))
		
		header.add_child(sections_menu)
		
		for index: int in sections_keys.size():
			
			var section_key: String = sections_keys[index]
			
			var options_container:= IS.create_box_container()
			var new_components_button:= IS.create_button("New Component", null, true)
			var search_line_edit:= IS.create_line_edit("Search for %s Component" % section_key)
			options_container.add_child(new_components_button)
			options_container.add_child(search_line_edit)
			
			var scroll_container:= IS.create_scroll_container()
			var margin_container:= IS.create_margin_container(0,12,0,0)
			var components_container:= IS.create_box_container(12, true, {})
			margin_container.add_child(components_container)
			scroll_container.add_child(margin_container)
			IS.expand(margin_container, true, true)
			
			var root_container:= IS.create_split_container(2, true)
			root_container.add_child(options_container)
			root_container.add_child(scroll_container)
			body.add_child(root_container)
			
			root_container.set_name(section_key)
			root_container.set_meta("new_button", new_components_button)
			root_container.set_meta("search_line_edit", search_line_edit)
			root_container.set_meta("components_container", components_container)
			
			new_components_button.pressed.connect(func() -> void:
				var section_components: Array
				for section_info: Dictionary in TypeServer.components[section_key]:
					section_components.append(MenuOption.new(section_info.text, section_info.icon, add_new_component.bind(media_clips, section_key, section_info.script)))
				IS.popup_menu(section_components, new_components_button)
			)
			
			var focus_media_clip = media_clips[0]
			if is_instance_valid(focus_media_clip):
				update_properties(focus_media_clip.clip_res, section_key)
		
		var change_focus_index_func: Callable = func(index: int) -> void:
			for child_index: int in body.get_child_count():
				var root_container: SplitContainer = body.get_child(child_index)
				var is_true_index: bool = child_index == index
				root_container.visible = is_true_index
		
		change_focus_index_func.call(0)
		sections_menu.focus_index_changed.connect(change_focus_index_func)


func add_new_component(media_clips: Array[MediaClip], section_key: String, component_script: Script) -> void:
	var component:= ComponentRes.new()
	component.set_script(component_script)
	for media_clip: MediaClip in media_clips:
		media_clip.clip_res.add_component(section_key, component.duplicate(true), Scene.get_scene_node(media_clip.layer_index))
	update_properties(media_clips[0].clip_res, section_key)


func update_properties(media_res: MediaClipRes, section_key: String) -> void:
	var root_container: SplitContainer = body.get_node(section_key)
	if root_container:
		var curr_components_container: BoxContainer = root_container.get_meta("components_container")
		IS.clear_children(curr_components_container)
		var section: Array = media_res.get_section_absolute(section_key)
		for component: ComponentRes in section:
			var controller: Control = ComponentRes.create_custom_edit(component.get_res_id(), component)[0]
			curr_components_container.add_child(controller.get_parent().get_parent().get_parent())


func on_media_clips_selection_group_selected_objects_changed() -> void:
	
	var clip_type: int
	var objects: Dictionary[String, Dictionary] = media_clips_selection_group.get_objects()
	
	var media_clips_selected: Array[MediaClip]
	var types_selected: Array[int]
	
	for key: String in objects:
		var info: Dictionary = objects[key]
		var object: MediaClip = info["object"]
		var object_type: int = object.type
		media_clips_selected.append(object)
		if not types_selected.has(object_type):
			types_selected.append(object_type)
	
	var properties_sections: Array = MediaServer.get_types_intersection_properties_sections(types_selected)
	open_properties(media_clips_selected, properties_sections)














