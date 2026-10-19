#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
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
class_name MediaClipResPath extends UsableRes

signal media_res_changed(old_one: MediaClipRes, new_one: MediaClipRes)

# Reverse index: target clip instance id -> WeakRefs of the paths pointing to it.
static var _refs_index: Dictionary[int, Array] = {}

@export var cond_method_name: StringName
@export var media_res: MediaClipRes:
	set(val):
		var old_one: MediaClipRes = media_res
		media_res = val
		if old_one != val:
			_unregister_ref(old_one)
			_register_ref(val)
		emit_res_changed()
		if old_one != val: media_res_changed.emit(old_one, val)
		_try_update_editor()

func _register_ref(target: MediaClipRes) -> void:
	if target == null: return
	_refs_index.get_or_add(target.get_instance_id(), []).append(weakref(self))

func _unregister_ref(target: MediaClipRes) -> void:
	if target == null: return
	var id: int = target.get_instance_id()
	if not _refs_index.has(id): return
	var refs: Array = _refs_index[id]
	for idx: int in range(refs.size() - 1, -1, -1):
		var path: MediaClipResPath = refs[idx].get_ref()
		if path == null or path == self: refs.remove_at(idx)
	if refs.is_empty(): _refs_index.erase(id)

# Repoints every path that targets a key of refs_map to its value. Cost depends only on refs_map size.
static func remap_refs(refs_map: Dictionary[MediaClipRes, MediaClipRes]) -> void:
	for old_target: MediaClipRes in refs_map:
		var id: int = old_target.get_instance_id()
		if not _refs_index.has(id): continue
		for ref: WeakRef in _refs_index[id].duplicate():
			var path: MediaClipResPath = ref.get_ref()
			if path and path.media_res == old_target:
				path.media_res = refs_map[old_target]

static func new_mediares_path(_media_res: MediaClipRes = null, _cond_method_name: StringName = &"any_cond") -> MediaClipResPath:
	var new_one:= MediaClipResPath.new()
	new_one.media_res = _media_res
	new_one.cond_method_name = _cond_method_name
	return new_one

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	var path_box: BoxContainer = IS.create_box_container(12)
	var path_line: LineEdit = IS.create_line_edit("[Empty]")
	var media_res_picker_button: IS.CustomTextureButton = IS.create_texture_button(preload("res://Asset/Icons/tool.png"), null, null, "Pick", true)
	var delete_button: IS.CustomTextureButton = IS.create_texture_button(preload("res://Asset/Icons/trash-can.png"), null, null, "Delete")
	
	path_line.editable = false
	
	path_box.add_child(path_line)
	path_box.add_child(media_res_picker_button)
	path_box.add_child(delete_button)
	
	media_res_picker_button.pressed.connect(_on_media_res_picker_button_pressed.bind(media_res_picker_button))
	delete_button.pressed.connect(_on_delete_button)
	
	return {
		&"path_ctrlr": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, method_custom_args(path_box)),
	}

func _custom_editor_spawned(edit_cont: EditContainer, props_editors: Dictionary[StringName, Control]) -> void:
	#var panel_container: PanelContainer = main_edit.get_child(0)
	#panel_container.add_theme_stylebox_override(&"panel", IS.style_box_empty)
	_try_update_editor()

func _try_update_editor() -> void:
	
	if EditorServer.usable_ress_editors_has_editor_with_idx(self, 0):
		var path_edit: BoxContainer = EditorServer.usable_ress_editors_get_prop_edit_cont(self, 0, &"path_ctrlr")
		var path_line: LineEdit = path_edit.get_child(0)
		
		if media_res: path_line.text = media_res.get_display_name()
		else: path_line.clear()
		
		path_edit.get_child(1).visible = media_res == null
		path_edit.get_child(2).visible = media_res != null


func _on_media_res_picker_button_pressed(media_res_picker_button: IS.CustomTextureButton) -> void:
	
	if media_res_picker_button.button_pressed:
		
		EditorServer.picking_clip = true
		
		var drawable_rect: DrawableRect = EditorServer.drawable_rect
		
		var media_clips_focused: Array[MediaServer.ClipPanel] = EditorServer.media_clips_focused
		
		var font: Font = IS.label_settings_main.font
		
		await Engine.get_main_loop().process_frame
		await Engine.get_main_loop().process_frame
		
		while not Input.is_action_just_released("left_btn"):
			drawable_rect.clear_drawn_entities()
			if media_clips_focused.size():
				var str_pos: Vector2 = drawable_rect.get_global_mouse_position() + Vector2(.0, -10.)
				var str: String = media_clips_focused[0].clip_res.get_display_name()
				drawable_rect.draw_new_string_outline(font, str_pos, str, 0, 20, 4, Color.BLACK)
				drawable_rect.draw_new_string(font, str_pos, str, 0, 20, Color(Color.WHITE, .8))
			await Engine.get_main_loop().process_frame
		
		if media_clips_focused.size():
			var target_res: MediaClipRes = media_clips_focused[0].clip_res
			if has_method(cond_method_name) and call(cond_method_name, target_res) == true:
				for res: MediaClipResPath in EditorServer.usable_ress_editors_get_shared_ress_with_idx(self, 0):
					res.media_res = target_res
		
		drawable_rect.clear_drawn_entities()
		
		if media_res_picker_button:
			media_res_picker_button.button_pressed = false
			media_res_picker_button.update_button()
		
		EditorServer.picking_clip = false

func _on_delete_button() -> void:
	media_res = null
	_try_update_editor()

func get_media_res() -> MediaClipRes: return media_res
func set_media_res(new_val: MediaClipRes) -> void: media_res = new_val

func is_null() -> bool: return media_res == null
func is_empty() -> bool: return media_res == null or media_res.curr_node == null
func is_valid() -> bool: return media_res != null and media_res.curr_node != null

static func any_cond(media_res: MediaClipRes) -> bool: return true
static func display2d_cond(media_res: MediaClipRes) -> bool: return media_res is Display2DClipRes
static func renderpass_cond(media_res: MediaClipRes) -> bool: return media_res is RenderPassClipRes


