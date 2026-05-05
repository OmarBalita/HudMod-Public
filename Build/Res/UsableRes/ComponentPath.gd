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
class_name ComponentPath extends UsableRes

signal component_path_changed(new_comp: ComponentRes)

@export var clip: MediaClipResPath = MediaClipResPath.new():
	set(val):
		if val: val.media_res_changed.connect(_on_clip_media_res_val_changed)
		clip = val

@export var component: ComponentRes:
	set(val):
		component = val
		component_path_changed.emit(val)

var owner: ComponentRes:
	set(val):
		clip.owner = val.owner
		owner = val

var cond_func: Callable
var comps_ignored: Array[ComponentRes]

func get_clip() -> MediaClipResPath: return clip
func set_clip(new_val: MediaClipResPath) -> void: clip = new_val

func get_component() -> ComponentRes: return component
func set_component(new_val: ComponentRes) -> void: component = new_val

func get_owner() -> ComponentRes: return owner
func set_owner(new_val: ComponentRes) -> void: owner = new_val

func get_cond_func() -> Callable: return cond_func
func set_cond_func(new_val: Callable) -> void: cond_func = new_val


func _init() -> void:
	clip.media_res_changed.connect(_on_clip_media_res_val_changed)

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	
	var search_box: BoxContainer = IS.create_box_container(12)
	var line: LineEdit = IS.create_line_edit("[Empty]")
	var button: Button = IS.create_button("", IS.TEXTURE_SEARCH, "Search for components")
	
	line.editable = false
	IS.add_children(search_box, [line, button])
	
	button.pressed.connect(_on_component_search_button_pressed)
	
	return {
		&"clip": export([clip]),
		&"Component": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, [search_box], [func() -> bool: return clip.media_res != null, [true]])
	}


func _exported_props_controllers_created(main_edit: EditContainer, props_controls: Dictionary[StringName, Control]) -> void:
	_try_update_editor()

func _on_clip_media_res_val_changed(old_one: MediaClipRes, new_one: MediaClipRes) -> void:
	await EditorServer.get_tree().process_frame
	if component and clip.media_res != component.owner:
		component = null
	_try_update_editor()

var target_comp: ComponentRes

func get_target_comp() -> ComponentRes: return target_comp
func set_target_comp(new_val: ComponentRes) -> void: target_comp = new_val

func _on_component_search_button_pressed() -> void:
	
	if clip.is_null(): return
	
	const SFC: String = "Search for Component"
	
	var search_line: LineEdit = IS.create_line_edit(SFC, "", IS.TEXTURE_SEARCH)
	var scroll_cont: ScrollContainer = IS.create_scroll_container()
	var comp_btns_box: BoxContainer = IS.create_box_container(2, true)
	
	var select_func: Callable = func() -> void:
		_on_component_selected(target_comp)
		target_comp = null
	
	var search_cont: BoxContainer = WindowManager.popup_accept_window(EditorServer.get_window(), Vector2i(600, 400), SFC, select_func)
	var win: WindowManager.AcceptWindow = search_cont.get_window()
	
	win.accept_button.text = "Select"
	search_cont.alignment = BoxContainer.ALIGNMENT_BEGIN
	comp_btns_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	IS.expand(scroll_cont, true, true)
	IS.expand(comp_btns_box, true, true)
	
	scroll_cont.add_child(comp_btns_box)
	search_cont.add_child(search_line)
	search_cont.add_child(scroll_cont)
	
	var media_res: MediaClipRes = clip.media_res
	
	var button_group:= ButtonGroup.new()
	
	search_line.text_changed.connect(
		func(new_text: String) -> void:
			new_text = new_text.to_lower()
			var finded_btns: Array[Button]
			for btn: Button in comp_btns_box.get_children():
				var finded: bool = StringHelper.fuzzy_search(new_text, btn.text.to_lower())
				btn.visible = finded
				if finded: finded_btns.append(btn)
			if finded_btns:
				var target_btn: Button = finded_btns[0]
				target_btn.button_pressed = true
				target_comp = target_btn.get_meta(&"comp")
			else:
				target_comp = null
	)
	
	media_res.loop_components(
		func(comp: ComponentRes) -> void:
			if (cond_func.is_null() or cond_func.call(comp)) and not comps_ignored.has(comp):
				var comp_classname: StringName = comp.get_classname()
				var btn: Button = IS.create_button(comp_classname, ClassServer.classname_get_icon(comp_classname), String(comp_classname), false)
				btn.toggle_mode = true
				btn.button_group = button_group
				btn.set_meta(&"comp", comp)
				btn.pressed.connect(set_target_comp.bind(comp))
				comp_btns_box.add_child(btn)
	)
	
	search_line.grab_focus()
	
	while win:
		if Input.is_action_just_pressed("enter") and target_comp:
			select_func.call()
			win.queue_free()
		await EditorServer.get_tree().process_frame

func _on_component_selected(comp: ComponentRes) -> void:
	
	var shared_ress: Array[UsableRes] = EditorServer.get_usable_res_shared_ress(self)
	
	for res: ComponentPath in shared_ress:
		res.clip.media_res = clip.media_res
		res.component = comp
	
	_try_update_editor()

func _try_update_editor() -> void:
	
	if not EditorServer.has_usable_res_controllers(self):
		return
	
	EditorServer.update_usable_res_ui_profile(self)
	
	var comp_control: BoxContainer = EditorServer.get_usable_res_property_controller(self, &"Component")
	var line: LineEdit = comp_control.get_child(0)
	
	if component:
		var comp_classname: StringName = component.get_classname()
		line.text = comp_classname
		line.right_icon = ClassServer.classname_get_icon(comp_classname)
	else:
		line.clear()
		line.right_icon = null


static func any_cond(comp_res: ComponentRes) -> bool: return true

