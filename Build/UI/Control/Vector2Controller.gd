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
class_name Vector2Controller extends BoxContainer

signal val_changed(new_val: Vector2)

@export var has_lock_button: bool = false

@export_group("Textures")
@export var locked_icon: Texture2D = preload("res://Asset/Icons/link.png")
@export var unlocked_icon: Texture2D = preload("res://Asset/Icons/unlink.png")

var x_edit: FloatController = IS.create_float_controller(curr_val.x, -INF, INF, .001, .01)
var y_edit: FloatController = IS.create_float_controller(curr_val.y, -INF, INF, .001, .01)

var lock_button: IS.CustomTextureButton = null

var curr_val: Vector2:
	set(val):
		curr_val = val
		if x_edit and y_edit:
			x_edit.set_curr_val_manually(val.x)
			y_edit.set_curr_val_manually(val.y)

var is_locked: bool = false
var aspact_retio: float = 1.

func _ready() -> void:
	IS.describe_box_container(self, 6, true)
	# var x_split: SplitContainer = IS.create_split_container(2, false, {custom_minimum_size = Vector2(0, 32.0), dragging_enabled = false})
	# var y_split: SplitContainer = IS.create_split_container(2, false, {custom_minimum_size = Vector2(0, 32.0), dragging_enabled = false})
	# var x_label: Label = IS.create_label("X", "", IS.label_settings_bold, {modulate = Color.RED})
	# var y_label: Label = IS.create_label("Y", "", IS.label_settings_bold, {modulate = Color.GREEN})
	
	if has_lock_button:
		is_locked = true
		lock_button = IS.create_texture_button(
			locked_icon, 
			locked_icon, 
			locked_icon, 
			"Lock X and Y values", 
			true, 
			{custom_minimum_size = Vector2(32.0, 32.0)}
		)
		lock_button.button_pressed = true
		lock_button.toggled.connect(_on_lock_toggled)
	
	# IS.add_children(x_split, [x_label, x_edit])
	# IS.add_children(y_split, [y_label, y_edit])

	x_edit.set_prefix("X:")
	y_edit.set_prefix("Y:")

	var inputs_vbox: VBoxContainer = VBoxContainer.new()
	IS.add_children(inputs_vbox, [
		x_edit, IS.create_color_rect(Color(Color.RED, .5), {custom_minimum_size = Vector2(.0, 2.0)}),
		y_edit, IS.create_color_rect(Color(Color.GREEN, .5), {custom_minimum_size = Vector2(.0, 2.0)})
	])
	inputs_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var main_hbox: HBoxContainer = HBoxContainer.new()
	main_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	IS.add_children(main_hbox, [lock_button, inputs_vbox])
	
	IS.add_children(self, [main_hbox])
	
	x_edit.val_changed.connect(_on_x_edit_val_changed)
	y_edit.val_changed.connect(_on_y_edit_val_changed)

func set_suffix(type: FloatController.SuffixType, color: Color = Color(IS.color_label, 0.5)):
	x_edit.set_suffix_by_type(type, color)
	y_edit.set_suffix_by_type(type, color)

func _on_x_edit_val_changed(new_val: float) -> void:
	if is_locked: set_curr_val(Vector2(new_val, new_val / aspact_retio))
	else: set_curr_val(Vector2(new_val, y_edit.curr_val))

func _on_y_edit_val_changed(new_val: float) -> void:
	if is_locked: set_curr_val(Vector2(new_val * aspact_retio, new_val))
	else: set_curr_val(Vector2(x_edit.curr_val, new_val))

func _on_lock_toggled(toggled_on: bool) -> void:
	is_locked = toggled_on
	var target_icon: Texture2D = locked_icon if is_locked else unlocked_icon

	lock_button.texture_normal = target_icon
	lock_button.texture_hover = target_icon
	
	if is_locked:
		aspact_retio = curr_val.x / curr_val.y

func set_curr_val(new_val: Vector2) -> void:
	curr_val = new_val
	val_changed.emit(curr_val)

func set_curr_val_manually(new_val: Vector2) -> void:
	curr_val = new_val
