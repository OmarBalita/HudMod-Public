class_name Properties extends EditorRect

var media_clips_selection_group:= EditorServer.media_clips_selection_group

@export_group("Theme")
@export_subgroup("Texture")
@export var texture_add: Texture2D = preload("res://Asset/Icons/plus.png")
@export var texture_search: Texture2D = preload("res://Asset/Icons/magnifying-glass.png")
@export var texture_delete: Texture2D = preload("res://Asset/Icons/trash-can.png")
@export var texture_drag: Texture2D = preload("res://Asset/Icons/drag.png")
@export_group("Constant")
@export var scroll_margin: float = 100.0
@export var scroll_speed: float = 700.0


var curr_selected_media_clips: Array[MediaClip]
var curr_focused_media_clip: MediaClip

var drag_info: Dictionary[StringName, Variant]
var curr_scroll_speed: float = .0

var warning_message_label: Label = IS.create_label("There is no Media Clip to Display its Properties.")
var components_root_container: MarginContainer = IS.create_margin_container()


func _ready_editor() -> void:
	warning_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.add_child(warning_message_label)
	body.add_child(components_root_container)
	
	# Connections
	media_clips_selection_group.selected_objects_changed.connect(
		on_media_clips_selection_group_selected_objects_changed
	)

func _input(event: InputEvent) -> void:
	super(event)
	if drag_info.size() and drag_info.drag_enabled:
		if event is InputEventMouseMotion:
			
			var dragged_edit_box: Control = drag_info.dragged_edit_box
			var comps_container: BoxContainer = drag_info.comps_container
			var comp_box: ScrollContainer = comps_container.get_parent().get_parent()
			
			var mouse_pos: Vector2 = get_global_mouse_position()
			var drag_offset: Vector2 = drag_info.drag_offset
			var box_pos: Vector2 = comp_box.global_position
			var box_size: Vector2 = comp_box.size
			
			dragged_edit_box.global_position.y = clamp(
				mouse_pos.y + drag_offset.y,
				box_pos.y,
				box_pos.y + box_size.y - dragged_edit_box.size.y
			)
			
			if mouse_pos.y < box_pos.y + scroll_margin: curr_scroll_speed = -scroll_speed
			elif mouse_pos.y > box_pos.y + box_size.y - scroll_margin: curr_scroll_speed = scroll_speed
			else: curr_scroll_speed = .0
			drag_info[&"scroll_container"] = comp_box
			
			#var index_from: int = drag_info.index_from
			var index_to: int = get_component_index_from_display_pos(comps_container, mouse_pos.y)
			#var move_range: Array
			#var displace_dir: int
			
			if index_to != -1:
				#if index_to > index_from:
					#index_from += 1; index_to += 1
					#move_range = range(index_from, index_to)
					#displace_dir = -1
				#else:
					#move_range = range(index_to, index_from)
					#index_from -= 1
					#displace_dir = 1
				#var edit_box: IS.EditBoxContainer = drag_info.edit_box
				var target_edit_box: IS.EditBoxContainer = comps_container.get_child(index_to)
				#var boxes_displacement: float = abs(target_edit_box.position.y - edit_box.position.y) * displace_dir
				#
				#var comps_main_pos: Dictionary[int, float] = drag_info.comps_main_poss
				#var comps_curr_poss: Dictionary[int, float] = drag_info.comps_poss
				
				drag_info["index_to"] = index_to
				var drawable_rect:= EditorServer.drawable_rect
				var rect2:= target_edit_box.get_global_rect()
				var color:= IS.COLOR_ACCENT_BLUE
				drawable_rect.clear_drawn_entities()
				drawable_rect.draw_new_theme_rect(rect2)

func _physics_process(delta: float) -> void:
	
	if drag_info and drag_info.drag_enabled:
		var scroll_container: ScrollContainer = drag_info[&"scroll_container"]
		if scroll_container: scroll_container.scroll_vertical += curr_scroll_speed * delta

func close_properties() -> void:
	IS.clear_children(header)
	IS.clear_children(components_root_container)
	warning_message_label.show()

func open_properties(media_clips: Array[MediaClip], focused_media_clip: MediaClip, sections_keys: Array) -> void:
	
	close_properties()
	
	await get_tree().process_frame
	
	if sections_keys:
		warning_message_label.hide()
		
		var options_info: Array[Dictionary] = TypeServer.get_sections_info(sections_keys)
		var sections_menu:= IS.create_menu(MenuOption.new_options_with_check_group(options_info))
		
		header.add_child(sections_menu)
		
		for index: int in sections_keys.size():
			
			var section_key: String = sections_keys[index]
			
			var options_container:= IS.create_box_container()
			var new_components_button:= IS.create_button("", texture_add, true)
			var search_line_edit:= IS.create_line_edit("Search for %s Component" % section_key, "", texture_search)
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
			components_root_container.add_child(root_container)
			
			root_container.set_name(section_key)
			root_container.set_meta("new_button", new_components_button)
			root_container.set_meta("search_line_edit", search_line_edit)
			root_container.set_meta("components_container", components_container)
			
			new_components_button.pressed.connect(func() -> void:
				var section_components: Array
				for section_info: Dictionary in TypeServer.components[section_key]:
					section_components.append(MenuOption.new(section_info.text, section_info.icon, add_new_component.bind(media_clips, focused_media_clip, section_key, section_info.script)))
				IS.popup_menu(section_components, new_components_button)
			)
			
			update_section_properties(media_clips, focused_media_clip if is_instance_valid(focused_media_clip) else null, section_key)
		
		var change_focus_index_func: Callable = func(index: int) -> void:
			for child_index: int in components_root_container.get_child_count():
				var root_container: SplitContainer = components_root_container.get_child(child_index)
				var is_true_index: bool = child_index == index
				root_container.visible = is_true_index
		
		change_focus_index_func.call(0)
		sections_menu.focus_index_changed.connect(change_focus_index_func)


func add_new_component(media_clips: Array[MediaClip], focused_media_clip: MediaClip, section_key: String, component_script: Script) -> void:
	var component:= ComponentRes.new()
	component.set_script(component_script)
	focused_media_clip.clip_res.add_component(section_key, component)
	update_section_properties(media_clips, focused_media_clip, section_key)

func delete_component(media_clips: Array[MediaClip], focused_media_clip: MediaClip, section_key: String, component: ComponentRes) -> void:
	focused_media_clip.clip_res.erase_component(section_key, component)
	update_section_properties(media_clips, focused_media_clip, section_key)

func update_section_properties(media_clips: Array[MediaClip], focused_media_clip: MediaClip, section_key: String) -> void:
	
	var media_ress: Array = media_clips.map(
		func(element: MediaClip) -> MediaClipRes:
			return element.clip_res
	)
	if not focused_media_clip: return
	if not media_ress: return
	var focused_media_res: MediaClipRes = focused_media_clip.clip_res
	
	var root_container: SplitContainer = components_root_container.get_node(section_key)
	
	if root_container:
		
		var curr_components_container: BoxContainer = root_container.get_meta("components_container")
		IS.clear_children(curr_components_container)
		var section: Array = focused_media_res.get_section_absolute(section_key)
		
		for index: int in section.size():
			var component: ComponentRes = section[index]
			
			var controller: Control = UsableRes.create_custom_edit(component.get_res_id(), component)[0]
			var edit_box: IS.EditBoxContainer = controller.get_meta("owner")
			edit_box.keyframable = false
			var delete_button:= IS.create_texture_button(texture_delete)
			var method_controller:= IS.create_option_controller([
				{text = "Set"}, {text = "Add"}, {text = "Sub"}, {text = "Multiply"}, {text = "Divid"}
			], "", component.method_type)
			var drag_button:= IS.create_texture_button(texture_drag)
			
			edit_box.keyframe_sended.connect(component.request_animation_keyframe)
			delete_button.pressed.connect(delete_component.bind(media_clips, focused_media_clip, section_key, component))
			method_controller.selected_option_changed.connect(func(id: int, option: MenuOption) -> void: component.method_type = id)
			drag_button.button_down.connect(on_component_drag_button_button_down.bind(edit_box, component, section_key))
			drag_button.button_up.connect(on_component_drag_button_button_up)
			#drag_button.gui_input.connect(func(event: InputEvent) -> void: on_component_drag_button_gui_input.call(event, index))
			
			IS.add_children(edit_box.header, [method_controller, delete_button, drag_button])
			curr_components_container.add_child(edit_box)

func get_component_index_from_display_pos(comp_container: BoxContainer, pos: float) -> int:
	var scroll_container: ScrollContainer = comp_container.get_parent().get_parent()
	var comps_count: int = comp_container.get_child_count()
	for index: int in comps_count:
		var comp_edit_box: IS.EditBoxContainer = comp_container.get_child(index)
		var box_pos: float = comp_edit_box.global_position.y
		var box_size: float = comp_edit_box.size.y
		var is_above_pos: bool = box_pos < pos
		var is_under_pos: bool = box_pos + box_size >= pos
		if (is_above_pos or index == 0) and (is_under_pos or index == comps_count - 1):
			return index
	return -1




func on_media_clips_selection_group_selected_objects_changed() -> void:
	
	var objects: Dictionary[String, Dictionary] = media_clips_selection_group.get_selected_objects()
	var focused_object: Dictionary = media_clips_selection_group.focused
	
	var selected_media_clips: Array[MediaClip]
	var focused_media_clip: MediaClip
	var types_selected: Array[int]
	
	for key: String in objects:
		var info: Dictionary = objects[key]
		if not info.object: continue
		var object: MediaClip = info.object
		if object is ImportedClip:
			var object_type: int = object.type
			selected_media_clips.append(object)
			if not types_selected.has(object_type):
				types_selected.append(object_type)
	
	if focused_object.size() and focused_object.object:
		focused_media_clip = focused_object.object
	
	if curr_selected_media_clips == selected_media_clips and curr_focused_media_clip == focused_media_clip:
		return
	curr_selected_media_clips = selected_media_clips
	curr_focused_media_clip = focused_media_clip
	
	var properties_sections: Array = MediaServer.get_types_intersection_properties_sections(types_selected)
	open_properties(selected_media_clips, focused_media_clip, properties_sections)

func on_component_drag_button_button_down(edit_box: IS.EditBoxContainer, component: ComponentRes, section_key: StringName) -> void:
	# Comps Container and Comps Main Poss
	var comps_container:= edit_box.get_parent()
	var comps_main_poss: Dictionary[int, float] = {}
	for index: int in comps_container.get_child_count():
		comps_main_poss[index] = comps_container.get_child(index).position.y
	# Instance Dragged Edit Box
	var dragged_edit_box:= edit_box.duplicate()
	ObjectServer.call_method_deep(dragged_edit_box, &"set_script", [null])
	dragged_edit_box.global_position = edit_box.global_position
	dragged_edit_box.size = edit_box.size
	get_tree().get_current_scene().add_child(dragged_edit_box)
	# Hide Edit Boxe
	edit_box.modulate.a = .0
	# identify Dragged Component Info
	var index_from: int = component.get_owner().get_section_absolute(section_key).find(component)
	drag_info = {
		&"drag_enabled": true,
		&"drag_offset": edit_box.global_position - get_global_mouse_position(),
		
		&"comps_main_poss": comps_main_poss,
		&"comps_poss": {} as Dictionary[int, float],
		
		&"comps_container": comps_container,
		&"scroll_container": null,
		&"edit_box": edit_box,
		&"dragged_edit_box": dragged_edit_box,
		
		&"component": component,
		
		&"section_key": section_key,
		
		&"index_from": index_from,
		&"index_to": index_from
	}

func on_component_drag_button_button_up() -> void:
	
	var edit_box: IS.EditBoxContainer = drag_info.edit_box
	var dragged_edit_box: Control = drag_info.dragged_edit_box
	
	var component: ComponentRes = drag_info.component
	var media_res: MediaClipRes = component.get_owner()
	
	var section_key: String = drag_info.section_key
	
	var index_from: int = drag_info.index_from
	var index_to: int = drag_info.index_to
	
	if index_from == index_to and index_to != -1:
		drag_info.drag_enabled = false
		var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(dragged_edit_box, "global_position:y", edit_box.global_position.y, .2)
		tween.play()
		await tween.finished
		edit_box.modulate.a = 1.0
	else:
		media_res.move_component(section_key, index_from, index_to)
		update_section_properties(curr_selected_media_clips, curr_focused_media_clip, section_key)
	
	dragged_edit_box.queue_free()
	drag_info.clear()
	curr_scroll_speed = .0
	
	EditorServer.drawable_rect.clear_drawn_entities()
