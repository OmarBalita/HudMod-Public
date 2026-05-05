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
class_name EditContainer extends SplitContainer

signal val_changed(value: Variant)
signal keyframe_sended(value: Variant)

enum KeyframeMethod {
	KEYFRAME_METHOD_ADD,
	KEYFRAME_METHOD_REMOVE
}

static var texture_add_keyframe: Texture2D = preload("res://Asset/Icons/keyframe_add.png")
static var texture_remove_keyframe: Texture2D = preload("res://Asset/Icons/keyframe_remove.png")
static var texture_reset: Texture2D = preload("res://Asset/Icons/reset.png")
static var texture_copy: Texture2D = preload("res://Asset/Icons/copy.png")
static var texture_past: Texture2D = preload("res://Asset/Icons/clipboard.png")

var header_cont: BoxContainer = IS.create_box_container(8)
var name_label: Label = IS.create_name_label("")
var keyframe_button: TextureButton
var reset_button: TextureButton
var controller: Control

@export var curr_val: Variant
@export var default_val: Variant

@export var keyframable: bool

@export var resetable: bool
@export var copypast: bool

@export var keyframe_method: KeyframeMethod = 0:
	set(val):
		keyframe_method = val
		var texture: Texture2D
		match val:
			0: texture = texture_add_keyframe
			1: texture = texture_remove_keyframe
		if keyframe_button:
			keyframe_button.texture_normal = texture

var method_set: Callable
var method_set_manually: Callable
var method_compare: Callable

func _init() -> void:
	dragging_enabled = false
	dragger_visibility = SplitContainer.DraggerVisibility.DRAGGER_HIDDEN

func _ready() -> void:
	
	header_cont.add_child(name_label)
	header_cont.move_child(name_label, 0)
	
	add_child(header_cont)
	move_child(header_cont, 0)
	
	IS.expand(name_label)
	IS.expand(header_cont)
	
	if resetable:
		
		reset_button = IS.create_texture_button(texture_reset, null, null, "Reset")
		reset_button.pressed.connect(_on_reset_button_pressed)
		
		header_cont.add_child(reset_button)
		header_cont.move_child(reset_button, 1)
	
	if keyframable:
		
		keyframe_button = IS.create_texture_button(null, null, null, "Add key")
		keyframe_button.pressed.connect(_on_keyframe_button_pressed)
		keyframe_button.use_theme_main_color = false
		
		header_cont.add_child(keyframe_button)
		header_cont.move_child(keyframe_button, 2)
	
	name_label.gui_input.connect(_on_name_label_gui_input)
	
	update_ui()

func _on_name_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			try_popup_context_menu()


func set_curr_value(value: Variant) -> void:
	curr_val = value
	val_changed.emit(value)
	update_ui()

func set_curr_value_manually(value: Variant) -> void:
	curr_val = value
	update_ui()

func set_controller_curr_value_manually(value: Variant) -> void:
	if value == null: return
	if method_set_manually.is_valid(): method_set_manually.call(value)
	elif method_set: method_set.call(value)

func set_keyframe_method(_keyframe_method: KeyframeMethod) -> void:
	keyframe_method = _keyframe_method

func copy_value() -> void:
	var copied_val: Variant
	if curr_val is UsableRes: copied_val = curr_val.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	else: copied_val = curr_val
	EditorServer.copied_value = copied_val

func past_value() -> void:
	if ClassServer.value_get_classname(curr_val) != ClassServer.value_get_classname(EditorServer.copied_value): return
	set_curr_value(EditorServer.copied_value)
	set_controller_curr_value_manually(curr_val)

func update_ui() -> void:
	
	if keyframe_button:
		keyframe_button.texture_normal = texture_add_keyframe if keyframe_method == KeyframeMethod.KEYFRAME_METHOD_ADD else texture_remove_keyframe
	
	if reset_button:
		var same_val: bool = method_compare.call(default_val, curr_val) if method_compare.is_valid() else default_val == curr_val
		reset_button.visible = not same_val



func try_popup_context_menu() -> void:
	if not copypast:
		return
	
	var popup_menu: PopupMenu = IS.create_popup_menu([
		{text = "Copy value", icon = texture_copy},
		{text = "Past value", icon = texture_past}
	])
	popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)
	
	get_tree().get_current_scene().add_child(popup_menu)
	
	var popup_pos: Vector2i = Vector2i(get_global_mouse_position() * get_window().content_scale_factor) + get_window().position
	popup_menu.popup(Rect2i(popup_pos, Vector2i.ZERO))
	
	popup_menu.popup_hide.connect(popup_menu.queue_free)


func _on_keyframe_button_pressed() -> void:
	keyframe_sended.emit(curr_val)

func _on_reset_button_pressed() -> void:
	set_curr_value(default_val)
	set_controller_curr_value_manually(default_val)

func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		0: copy_value()
		1: past_value()


