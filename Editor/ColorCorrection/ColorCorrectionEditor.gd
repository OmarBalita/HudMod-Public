#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
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
class_name ColorCorrectionEditor extends EditorControl

var curr_color_comps_info: Array[Properties2.ComponentInfo]
var curr_focused_comp_info: Properties2.ComponentInfo:
	set(val):
		if curr_focused_comp_info == val: return
		curr_focused_comp_info = val
		_spawn_comp_edit(val)

var header_menu: Menu
var curr_edit_cont: EditContainer
var no_comp_label: Label

func _ready_editor() -> void:
	super()
	
	no_comp_label = IS.create_label("Select a Clip with a color correction component to edit it here.")
	no_comp_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.add_child(no_comp_label)
	
	EditorServer.properties.properties_updated.connect(_on_properties_properties_updated)

func _update_color_comps_info() -> void:
	
	var new_color_comps_info: Array[Properties2.ComponentInfo]
	var curr_displayed_comps: Dictionary[StringName, Array] = EditorServer.properties.curr_displayed_components

	for section_key: StringName in curr_displayed_comps:
		for comp_info: Properties2.ComponentInfo in curr_displayed_comps[section_key]:
			var comp_owner: UsableRes = comp_info.component_res_owner
			if comp_owner is ShaderComponentRes:
				if comp_owner.has_color_correction_editor():
					new_color_comps_info.append(comp_info)
	
	curr_color_comps_info = new_color_comps_info
	curr_focused_comp_info = null if new_color_comps_info.is_empty() else curr_color_comps_info[0]
	
	_respawn_header_menu()

func _respawn_header_menu() -> void:
	if header_menu: header_menu.queue_free()
	
	if curr_color_comps_info.is_empty():
		return
	
	var options: Array[MenuOption]
	for comp_info: Properties2.ComponentInfo in curr_color_comps_info:
		var classname: StringName = comp_info.component_res_id
		var option: MenuOption = MenuOption.new(classname.capitalize(), ClassServer.classname_get_icon(classname))
		option.set_meta(&"comp_info", comp_info)
		options.append(option)
	
	header_menu = IS.create_menu(options)
	header_menu.focus_index_changed.connect(_on_comps_menu_focus_index_changed)
	header.add_child(header_menu)

func _spawn_comp_edit(comp_info: Properties2.ComponentInfo) -> void:
	
	if curr_edit_cont:
		curr_edit_cont.queue_free()
		curr_edit_cont = null
	
	no_comp_label.visible = comp_info == null
	if comp_info == null: return
	
	var target_comp: ComponentRes = comp_info.component_res_owner
	var exported_props: Dictionary[StringName, Dictionary] = target_comp._get_color_correction_exported_props()
	
	curr_edit_cont = target_comp.create_custom_edit(comp_info.component_res_id, target_comp, comp_info.components_ress, exported_props, null, false)
	IS.expand(curr_edit_cont, true, true)
	
	if curr_edit_cont:
		if curr_edit_cont.header_cont:
			curr_edit_cont.header_cont.hide()
		body.add_child(curr_edit_cont)

func _on_comps_menu_focus_index_changed(index: int) -> void:
	curr_focused_comp_info = header_menu.options[index].get_meta(&"comp_info")

func _on_properties_properties_updated() -> void:
	_update_color_comps_info()
