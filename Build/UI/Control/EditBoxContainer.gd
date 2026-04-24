class_name EditBoxContainer extends BoxContainer

signal val_changed(usable_res: UsableRes, key: StringName, new_val: Variant)
signal keyframe_sended(usable_res: UsableRes, key: StringName, new_val: Variant)

enum KeyframeMethod {
	KEYFRAME_ADD,
	KEYFRAME_REMOVE
}

static var texture_add_keyframe: Texture2D = preload("res://Asset/Icons/keyframe_add.png")
static var texture_remove_keyframe: Texture2D = preload("res://Asset/Icons/keyframe_remove.png")
static var texture_reset: Texture2D = preload("res://Asset/Icons/reset.png")
static var texture_copy: Texture2D = preload("res://Asset/Icons/copy.png")
static var texture_past: Texture2D = preload("res://Asset/Icons/clipboard.png")

@export var curr_val: Variant:
	set(val):
		curr_val = val
		if emit_change:
			val_changed.emit(null, &"", curr_val)

@export var default_val: Variant

@export var keyframable: bool = false
@export var resetable: bool = false
@export var copypast: bool = false
@export var keyframe_method: KeyframeMethod:
	set(val):
		keyframe_method = val
		var texture: Texture2D
		match val:
			0: texture = texture_add_keyframe
			1: texture = texture_remove_keyframe
		if keyframe_button:
			keyframe_button.texture_normal = texture
@export var value_comp_method: Callable
@export var emit_change: bool = true

var controller_set_ids: Dictionary[StringName, Variant] = {method = null, method_manual = null, vari = null}

@onready var keyframe_button: TextureButton
@onready var reset_button: TextureButton

var header: BoxContainer = IS.create_box_container()
var name_label: Label = IS.create_name_label("")
var controller: Control

func _ready() -> void:
	
	IS.expand(name_label)
	header.add_child(name_label)
	header.move_child(name_label, 0)
	
	name_label.gui_input.connect(_on_name_label_gui_input)
	
	if resetable:
		
		reset_button = IS.create_texture_button(texture_reset)
		reset_button.pressed.connect(_on_reset_button_pressed)
		
		header.add_child(reset_button)
		header.move_child(reset_button, 1)
	
	if keyframable:
		
		keyframe_button = IS.create_texture_button(null)
		keyframe_button.pressed.connect(_on_keyframe_button_pressed)
		keyframe_button.use_theme_main_color = false
		
		header.add_child(keyframe_button)
		header.move_child(keyframe_button, 2)
	
	IS.expand(header)
	
	add_child(header)
	move_child(header, 0)
	
	set_keyframe_method(0)
	update_ui()

func _on_name_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			try_popup_context_menu()


func try_popup_context_menu() -> void:
	if not copypast:
		return
	
	var popup_menu: PopupMenu = IS.create_popup_menu([
		{text = "Copy value", icon = texture_copy},
		{text = "Past value", icon = texture_past}
	])
	popup_menu.always_on_top = true
	popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)
	
	get_tree().get_current_scene().add_child(popup_menu)
	
	var popup_pos: Vector2i = Vector2i(get_global_mouse_position()) + get_window().position
	popup_menu.popup(Rect2i(popup_pos, Vector2i.ZERO))
	
	popup_menu.popup_hide.connect(popup_menu.queue_free)

func copy_value() -> void:
	var copied_val: Variant
	if curr_val is UsableRes: copied_val = curr_val.duplicate_deep(Resource.DEEP_DUPLICATE_ALL)
	else: copied_val = curr_val
	EditorServer.copied_value = copied_val

func past_value() -> void:
	if ClassServer.value_get_classname(curr_val) != ClassServer.value_get_classname(EditorServer.copied_value): return
	set_curr_val(EditorServer.copied_value, true)


func get_curr_val() -> Variant:
	return curr_val

func set_curr_val(new_val: Variant, update_controller: bool = false, _emit_change: bool = true) -> void:
	if not _emit_change:
		emit_change = false
	curr_val = new_val
	emit_change = true
	if update_controller:
		set_controller_val(new_val)
	update_ui()

func set_controller_val(new_val: Variant) -> void:
	var method: Variant = controller_set_ids.method
	var vari: Variant = controller_set_ids.vari
	if method: controller.call_deferred(method, new_val)
	elif vari: controller.set(vari, new_val)

func set_controller_val_manually(new_val: Variant) -> void:
	var method: Variant = controller_set_ids.method_manual
	if method: controller.call_deferred(method, new_val)
	else: set_controller_val(new_val)

func set_keyframe_method(what: KeyframeMethod) -> void:
	keyframe_method = what

func update_ui() -> void:
	
	if default_val == null:
		return
	
	var reset: bool
	if value_comp_method.is_valid(): reset = not value_comp_method.call(default_val, curr_val)
	else: reset = curr_val != default_val
	
	if not reset_button:
		return
	
	reset_button.visible = reset

func _on_keyframe_button_pressed() -> void:
	keyframe_sended.emit(null, &"", curr_val)

func _on_reset_button_pressed() -> void:
	set_curr_val(default_val, true)

func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		0: copy_value()
		1: past_value()

