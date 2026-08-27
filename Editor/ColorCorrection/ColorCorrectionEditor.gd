#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
##	GPLv3																   ##
#############################################################################
class_name ColorCorrectionEditor extends EditorControl

#var curr_color_comps_info: Array[Properties2.ComponentInfo]
#var curr_shown_comp_idx: int = -1

var curr_color_comps_info: Dictionary[Properties2.ComponentInfo, Dictionary]
var curr_focused_comp_info: Properties2.ComponentInfo:
	set(val):
		curr_focused_comp_info = val
		_display_comp_edit(val)

var current_edit_container: EditContainer
var no_comp_label: Label
var header_menu: Menu

func _ready_editor() -> void:
	super()
	
	no_comp_label = IS.create_label("Select a clip with a color correction component to edit it here.")
	no_comp_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.add_child(no_comp_label)
	
	EditorServer.properties.properties_updated.connect(_on_properties_updated)
	_update_color_comps_info()

func _update_color_comps_info() -> void:
	var new_color_comps_info: Dictionary[Properties2.ComponentInfo, Dictionary]
	var curr_displayed_comps: Dictionary[StringName, Array] = EditorServer.properties.curr_displayed_components

	for section_key: StringName in curr_displayed_comps:
		for comp_info: Properties2.ComponentInfo in curr_displayed_comps[section_key]:
			var comp_owner: UsableRes = comp_info.component_res_owner
			if comp_owner is SnippetShaderComponentRes:
				var exported_props: Dictionary[StringName, Dictionary] = comp_owner.get_color_correction_exported_props()
				if exported_props.is_empty(): continue
				new_color_comps_info[comp_info] = exported_props
	
	curr_color_comps_info = new_color_comps_info
	curr_focused_comp_info = null if new_color_comps_info.is_empty() else curr_color_comps_info.keys()[0]
	
	_respawn_header_menu()
	_display_comp_edit(curr_focused_comp_info)

func _respawn_header_menu() -> void:
	if header_menu:
		header_menu.queue_free()
		header_menu = null
	
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

func _display_comp_edit(comp_info: Properties2.ComponentInfo) -> void:
	if current_edit_container:
		current_edit_container.queue_free()
		current_edit_container = null
	
	no_comp_label.visible = comp_info == null
	if comp_info == null: return
	
	var target_comp: ComponentRes = comp_info.component_res_owner
	var comp_res_id: StringName = comp_info.component_res_id
	var exported_props: Dictionary[StringName, Dictionary] = target_comp.get_color_correction_exported_props()
	
	current_edit_container = target_comp.create_custom_edit(comp_res_id, target_comp, comp_info.components_ress, null, false, true, exported_props)
	IS.expand(current_edit_container, true, true)

	if current_edit_container:
		if current_edit_container.header_cont:
			current_edit_container.header_cont.hide()
		body.add_child(current_edit_container)

func _on_comps_menu_focus_index_changed(index: int) -> void:
	_display_comp_edit(header_menu.options[index].get_meta(&"comp_info"))

func _on_properties_updated() -> void:
	_update_color_comps_info()
