class_name MediaClipResPath extends UsableRes

signal media_res_changed(old_one: MediaClipRes, new_one: MediaClipRes)

@export var media_res: MediaClipRes:
	set(val):
		
		if media_res != val:
			media_res_changed.emit(media_res, val)
		if val:
			retarget_id = val.id
		
		media_res = val
		
		emit_res_changed()
		_try_update_editor()

@export var retarget_id: StringName

var owner: MediaClipRes:
	set(val):
		owner = val
		if owner and owner.id == retarget_id:
			media_res = owner

var cond_func: Callable = any_cond

static func new_mediares_path(_cond_func: Callable = any_cond, _media_res: MediaClipRes = null, owner: MediaClipRes = null) -> MediaClipResPath:
	var new_one:= MediaClipResPath.new()
	new_one.cond_func = _cond_func
	new_one.media_res = _media_res
	new_one.owner = owner
	return new_one

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var path_box: BoxContainer = IS.create_box_container(12)
	var path_line: LineEdit = IS.create_line_edit("[Empty]")
	var media_res_picker_button: IS.CustomTextureButton = IS.create_texture_button(preload("res://Asset/Icons/tool.png"), null, null, true)
	var delete_button: IS.CustomTextureButton = IS.create_texture_button(preload("res://Asset/Icons/trash-can.png"))
	
	path_line.editable = false
	
	path_box.add_child(path_line)
	path_box.add_child(media_res_picker_button)
	path_box.add_child(delete_button)
	
	media_res_picker_button.pressed.connect(_on_media_res_picker_button_pressed.bind(media_res_picker_button))
	delete_button.pressed.connect(_on_delete_button)
	
	return {
		&"path_ctrlr": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, method_custom_args(path_box)),
	}

func _exported_props_controllers_created(main_edit: IS.EditBoxContainer, props_controllers: Dictionary[StringName, Control]) -> void:
	var panel_container: PanelContainer = main_edit.get_child(0)
	panel_container.add_theme_stylebox_override(&"panel", IS.style_box_empty)
	_try_update_editor()

func _try_update_editor() -> void:
	
	if EditorServer.has_usable_res_controllers(self):
		var path_box: BoxContainer = EditorServer.get_usable_res_property_controller(self, &"path_ctrlr")
		var path_line: LineEdit = path_box.get_child(0)
		
		if media_res:
			path_line.text = ("(Self) " if media_res == owner else "") + media_res.get_display_name()
		else:
			path_line.clear()
		
		path_box.get_child(1).visible = media_res == null
		path_box.get_child(2).visible = media_res != null


func _on_media_res_picker_button_pressed(media_res_picker_button: IS.CustomTextureButton) -> void:
	
	if media_res_picker_button.button_pressed:
		
		EditorServer.time_line.process_mode = Node.PROCESS_MODE_DISABLED
		
		var tree: SceneTree = EditorServer.get_tree()
		var drawable_rect: DrawableRect = EditorServer.drawable_rect
		
		var media_clips_focused: Array[MediaClip] = EditorServer.media_clips_focused
		
		var font: Font = IS.label_settings_main.font
		
		while Input.get_mouse_button_mask() == 0:
			drawable_rect.clear_drawn_entities()
			if media_clips_focused.size():
				var str_pos: Vector2 = drawable_rect.get_global_mouse_position() + Vector2(.0, -10.)
				var str: String = media_clips_focused[0].clip_res.get_display_name()
				drawable_rect.draw_new_string_outline(font, str_pos, str, 0, 20, 4, Color.BLACK)
				drawable_rect.draw_new_string(font, str_pos, str, 0, 20, Color(Color.WHITE, .8))
			await tree.process_frame
		
		if media_clips_focused.size():
			var target_res: MediaClipRes = media_clips_focused[0].clip_res
			if cond_func.is_null() or cond_func.call(target_res):
				for res: MediaClipResPath in EditorServer.get_usable_res_shared_ress(self):
					res.media_res = target_res
		
		drawable_rect.clear_drawn_entities()
		
		media_res_picker_button.button_pressed = false
		media_res_picker_button.update_button()
		
		EditorServer.time_line.process_mode = Node.PROCESS_MODE_INHERIT

func _on_delete_button() -> void:
	media_res = null
	_try_update_editor()

func get_media_res() -> MediaClipRes: return media_res
func set_media_res(new_val: MediaClipRes) -> void: media_res = new_val

func is_null() -> bool: return media_res == null
func is_empty() -> bool: return media_res == null or media_res.curr_node == null
func is_valid() -> bool: return media_res != null and media_res.curr_node != null

static func any_cond(media_res: MediaClipRes) -> bool: return true
static func node2d_cond(media_res: MediaClipRes) -> bool: return media_res is Display2DClipRes
