#############################################################################
##	This file is part of: HudMod Video Editor							   ##
##	https://omar-top.itch.io/hudmod-video-editor						   ##
## ----------------------------------------------------------------------- ##
##	Copyright © 2026 Omar Mohammed Balita.								   ##
## ----------------------------------------------------------------------- ##
##	GPLv3																   ##
#############################################################################
class_name ColorCorrectionEditor extends EditorControl

@export var properties: Properties2 

var curr_color_comps_info: Array[Properties2.ComponentInfo]
var curr_shown_comp_idx: int = -1

var current_edit_container: EditContainer
var no_comp_label: Label
var comps_menu: Menu


func _ready_editor() -> void:
	super()
	
	no_comp_label = IS.create_label("Select a clip with a color correction component to edit it here.")
	no_comp_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.add_child(no_comp_label)
	
	if properties == null: properties = EditorServer.properties
	properties.properties_updated.connect(_on_properties_updated)
	
	_refresh_color_comps()


func set_focus_component(comp_info: Properties2.ComponentInfo) -> void:
	if not curr_color_comps_info.has(comp_info):
		_refresh_color_comps()
	
	var index: int = curr_color_comps_info.find(comp_info)
	if index == -1: return
	
	comps_menu.set_focus_index(index)
	_display_comp_edit(index)



func _refresh_color_comps() -> void:
	var new_color_comps_info: Array[Properties2.ComponentInfo] = []
	
	for section_key: StringName in properties.curr_displayed_components:
		for comp_info: Properties2.ComponentInfo in properties.curr_displayed_components[section_key]:
			var comp_owner: UsableRes = comp_info.component_res_owner
			if comp_owner.is_support_custom_exported_props() and comp_owner is SnippetShaderComponentRes:
				new_color_comps_info.append(comp_info)
	
	if curr_color_comps_info == new_color_comps_info: return
	curr_color_comps_info = new_color_comps_info
	
	_rebuild_header_menu()
	_display_comp_edit(curr_shown_comp_idx)


func _rebuild_header_menu() -> void:
	if comps_menu:
		comps_menu.queue_free()
		comps_menu = null
	
	if curr_color_comps_info.is_empty():
		return
	
	var options: Array[MenuOption]
	for comp_info: Properties2.ComponentInfo in curr_color_comps_info:
		var classname: StringName = comp_info.component_res_id
		options.append(MenuOption.new(classname.capitalize(), ClassServer.classname_get_icon(classname)))
	
	comps_menu = IS.create_menu(options)
	comps_menu.focus_index_changed.connect(_on_comps_menu_focus_index_changed)
	header.add_child(comps_menu)


func _display_comp_edit(index: int) -> void:
	curr_shown_comp_idx = index
	
	if current_edit_container:
		current_edit_container.queue_free()
		current_edit_container = null
	
	if index < 0 or index >= curr_color_comps_info.size():
		no_comp_label.show()
		return
	
	no_comp_label.hide()
	
	var comp_info: Properties2.ComponentInfo = curr_color_comps_info[index]
	var target_comp: ComponentRes = comp_info.component_res_owner
	var comp_res_id: StringName = comp_info.component_res_id
	var exported_props: Dictionary[StringName, UsableRes.ExportInfo]

	if target_comp is SnippetShaderComponentRes:
		exported_props = target_comp.get_color_correction_exported_props()
	
	if exported_props.is_empty(): return
	
	current_edit_container = target_comp.create_custom_edit(
		comp_res_id,
		target_comp,
		comp_info.components_ress,
		null,
		false,
		true,
		exported_props
	)
	
	if current_edit_container:
		if current_edit_container.header_cont:
			current_edit_container.header_cont.hide()
		
		current_edit_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		current_edit_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(current_edit_container)


func _on_comps_menu_focus_index_changed(index: int) -> void:
	_display_comp_edit(index)

func _on_properties_updated() -> void:
	_refresh_color_comps()
