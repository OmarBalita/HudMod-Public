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
class_name ListController extends PanelContainer


signal list_changed()
signal list_val_changed(index: int, new_val: Variant)
signal focus_index_changed(index: int)

signal list_button_pressed(index: int)

@export var list: Array:
	set(val):
		list = val
		if not on_element_entered.is_valid():
			return
		for index: int in list:
			on_element_entered.call(index, list[index])

@export var types: Array[StringName]

@export_group("Properties")
@export var min_elements_count: int:
	set(val): min_elements_count = max(0, val)
@export_subgroup("Permissions", "can")
@export var can_add_element: bool = true
@export var can_remove_element: bool = true
@export var can_duplicate_element: bool = true
@export var can_change_element_priority: bool = true

@export_group("Theme")
@export_subgroup("Texture")
@export var texture_add: Texture2D = preload("res://Asset/Icons/add.png")
@export var texture_sub: Texture2D = preload("res://Asset/Icons/minus.png")
@export var texture_duplicate: Texture2D = preload("res://Asset/Icons/duplicate.png")
@export var texture_up: Texture2D = preload("res://Asset/Icons/up.png")
@export var texture_down: Texture2D = preload("res://Asset/Icons/down.png")
@export var texture_settings: Texture2D = preload("res://Asset/Icons/setting.png")

@onready var display_name_func: Callable = get_main_display_name:
	set(val):
		display_name_func = val
		update_display_ui()
@onready var display_icon_func: Callable:
	set(val):
		display_icon_func = val
		update_display_ui()

var on_element_entered: Callable

# RealTime Variables
var focus_index: int = -1:
	set(val):
		focus_index = val
		
		if list.size() > 0 and val != -1:
			await get_tree().process_frame
			focus_button = list_box_container.get_child(val).get_child(0)
			focus_button.button_pressed = true
		
		update_type_edit(focus_index)
		focus_index_changed.emit(val)

# RealTime Nodes
var focus_button: Button

var list_box_container: BoxContainer
var controller_container: MarginContainer
var curr_edit_cont: Control


func _ready() -> void:
	_ready_ui()
	# Connections
	list_changed.connect(on_list_changed)

func _ready_ui() -> void:
	IS.set_base_panel_settings(self, IS.style_body)
	
	var margin_container: MarginContainer = IS.create_margin_container(8,8,8,8)
	var vbox_container: BoxContainer = IS.create_box_container(12, true)
	var hsplit_container: SplitContainer = IS.create_split_container()
	controller_container = IS.create_margin_container(0,0,0,0)
	
	var scroll_box_container: ScrollContainer = IS.create_scroll_container(0, 1, {custom_minimum_size = Vector2(.0, 120.)})
	list_box_container = IS.create_box_container(4, true, {})
	var margin2_container: MarginContainer = IS.create_margin_container(0,0,0,0)
	var options_box_container: BoxContainer = IS.create_box_container(12, true, {})
	
	if can_add_element:
		var append_button = IS.create_texture_button(texture_add, null, null, "Add")
		append_button.pressed.connect(on_append_button_pressed)
		options_box_container.add_child(append_button)
	if can_remove_element:
		var erase_button = IS.create_texture_button(texture_sub, null, null, "Erase")
		erase_button.pressed.connect(on_erase_button_pressed)
		options_box_container.add_child(erase_button)
	if can_duplicate_element:
		var duplicate_button = IS.create_texture_button(texture_duplicate, null, null, "Duplicate")
		duplicate_button.pressed.connect(on_duplicate_button_pressed)
		options_box_container.add_child(duplicate_button)
	
	if can_add_element or can_remove_element or can_duplicate_element:
		options_box_container.add_child(IS.create_h_line_panel())
	
	if can_change_element_priority:
		var move_up_button = IS.create_texture_button(texture_up, null, null, "Move up")
		var move_dowm_button = IS.create_texture_button(texture_down, null, null, "Move down")
		move_up_button.pressed.connect(on_move_up_button_pressed)
		move_dowm_button.pressed.connect(on_move_down_button_pressed)
		options_box_container.add_child(move_up_button)
		options_box_container.add_child(move_dowm_button)
	
	margin2_container.add_child(list_box_container)
	scroll_box_container.add_child(margin2_container)
	
	hsplit_container.add_child(scroll_box_container)
	hsplit_container.add_child(options_box_container)
	
	vbox_container.add_child(hsplit_container)
	vbox_container.add_child(IS.create_h_line_panel())
	vbox_container.add_child(controller_container)
	
	margin_container.add_child(vbox_container)
	add_child(margin_container)
	
	IS.expand(hsplit_container, true, true)
	IS.expand(scroll_box_container, true, true)
	IS.expand(margin2_container)
	
	update_display_ui()


func get_display_name_func() -> Callable:
	return display_name_func

func set_display_name_func(new_func: Callable) -> void:
	display_name_func = new_func

func get_display_icon_func() -> Callable:
	return display_icon_func

func set_display_icon_func(new_func: Callable) -> void:
	display_icon_func = new_func


func update_display_ui() -> void:
	if not is_node_ready():
		return
	
	var is_dynamic: bool = types.size() != 1
	
	for button: SplitContainer in list_box_container.get_children():
		button.queue_free()
	
	var button_group:= ButtonGroup.new()
	
	for index: int in list.size():
		
		var element: Variant = list[index]
		
		var split: SplitContainer = IS.create_split_container()
		var button: Button = IS.create_button("", null, "", false, false, true, {toggle_mode = true, button_group = button_group, text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS})
		button.set_expand_icon(true)
		
		set_button_display(index, element, button, true)
		
		button.pressed.connect(on_list_button_pressed.bind(index))
		if is_dynamic:
			split.mouse_entered.connect(on_list_button_mouse_entered.bind(index, button))
			split.mouse_exited.connect(on_list_button_mouse_exited.bind(index, button))
		
		split.add_child(button)
		list_box_container.add_child(split)
		
		IS.expand(button)
		
		if index == focus_index:
			button.button_pressed = true


func update_type_edit(index: int) -> void:
	if curr_edit_cont:
		curr_edit_cont.queue_free()
	
	if not list.size():
		return
	if index == -1:
		return
	
	var curr_val: Variant = list[index]
	var edit_cont: EditContainer = ClassServer.create_prop_editor(&"index %s" % index, curr_val)
	
	if edit_cont:
		edit_cont.val_changed.connect(on_type_controller_val_changed)
		controller_container.add_child(edit_cont)
		curr_edit_cont = edit_cont



func get_main_display_name(index: int, element: Variant, ready_update: bool) -> String:
	if element is UsableRes:
		return "%s %s" % [element.get_classname(), index]
	return str(element)

func get_absolute_index(index_from: int) -> int:
	return clamp(index_from, 0, list.size())

func get_main_val() -> Variant:
	var types_count: int = types.size()
	if types_count >= 1:
		return ClassServer.classname_new(types[0])
	else:
		return null

func get_list() -> Array:
	return list

func set_list(new_list: Array) -> void:
	list = new_list
	list_changed.emit()

func set_list_manually(new_list: Array) -> void:
	list = new_list

func set_button_display(index: int, value: Variant, button: Button, ready_update: bool) -> void:
	var is_dynamic = types.size() != 1
	
	var display_name: String
	var display_icon: Texture2D
	
	if not display_name_func.is_null():
		display_name = await display_name_func.call(index, value, ready_update)
	else:
		display_name = str(value)
	tooltip_text = display_name
	
	if is_dynamic:
		display_icon = ClassServer.classname_get_icon(ClassServer.value_get_classname(value))
	elif not display_icon_func.is_null():
		display_icon = await display_icon_func.call(index, value, ready_update)
	
	if not ready_update and focus_index != index:
		return
	
	if button != null and is_instance_valid(button):
		button.set_text(display_name)
		button.icon = display_icon

func add_element(element: Variant, index: int, emit_changes: bool = true) -> void:
	var absolute_new_index: int = get_absolute_index(index)
	if on_element_entered.is_valid():
		on_element_entered.call(absolute_new_index, element)
	list.insert(absolute_new_index, element)
	focus_index = index
	if emit_changes:
		list_changed.emit()

func remove_element(index: int, emit_changes: bool = true) -> void:
	if list.size() <= min_elements_count:
		return
	list.remove_at(index)
	focus_index = get_absolute_index(index - 1)
	if emit_changes:
		list_changed.emit()

func duplicate_element(index: int) -> void:
	if index > list.size() - 1:
		return
	var element = list[index]
	if element is Array: element = element.duplicate(true)
	elif element is Resource: element = element.duplicate(false)
	add_element(element, index + 1)

func move_element(index: int, new_index: int) -> void:
	if index == -1 or (not index and new_index < index) or (index >= list.size() - 1 and new_index > index):
		return
	
	var element = list[index]
	
	remove_element(index, false)
	add_element(element, new_index, false)
	list_changed.emit()

func replace_element(index: int, value: Variant) -> void:
	if index == -1:
		return
	remove_element(index, false)
	add_element(value, index, false)
	list_changed.emit()

func edit_element(index: int, new_val: Variant) -> void:
	list[index] = new_val
	
	await get_tree().process_frame
	var button = list_box_container.get_child(index).get_child(0)
	set_button_display(index, new_val, button, false)


func on_list_changed() -> void:
	update_display_ui()
	update_type_edit(focus_index)


func on_list_button_pressed(index: int) -> void:
	if focus_index == index:
		var button: Button = list_box_container.get_child(index).get_child(0)
		button.button_pressed = false
		focus_index = -1
	else:
		focus_index = index

func on_list_button_mouse_entered(index: int, button: Button) -> void:
	var type_button: IS.CustomTextureButton = IS.create_texture_button(texture_settings, null, null, "Change type", false)
	button.get_parent().add_child(type_button)
	button.set_meta("type_button", type_button)
	
	type_button.pressed.connect(on_type_button_pressed.bind(index, type_button))

func on_list_button_mouse_exited(index: int, button: Button) -> void:
	var type_button = button.get_meta("type_button")
	type_button.queue_free()

func on_type_button_pressed(index: int, type_button: TextureButton) -> void:
	#var types:= TypeServer.get_types(types)
	#var main_type_index:= ClassServer.get_type_from_name(ClassServer.value_get_classname(list[index]), types)
	#var types_menu = IS.popup_menu(MenuOption.new_options_with_check_group(types, "", main_type_index), type_button)
	#types_menu.menu_button_pressed.connect(
		#func(menu_index: int) -> void:
			#var type_name = types_menu.options[menu_index].text
			#var new_type_index = TypeServer.get_type_from_name(type_name)
			#var default_val = TypeServer.get_type_default_val(new_type_index)
			#replace_element(index, default_val)
	#)
	pass


func on_append_button_pressed() -> void:
	add_element(get_main_val(), focus_index + (1 if list.size() else 0))

func on_erase_button_pressed() -> void:
	remove_element(focus_index)

func on_duplicate_button_pressed() -> void:
	duplicate_element(focus_index)

func on_move_up_button_pressed() -> void:
	move_element(focus_index, focus_index - 1)

func on_move_down_button_pressed() -> void:
	move_element(focus_index, focus_index + 1)


func on_type_controller_val_changed(usable_res: UsableRes, prop_key: StringName, new_val: Variant) -> void:
	if prop_key.is_empty():
		edit_element(focus_index, new_val)
	list_val_changed.emit(focus_index, new_val)

