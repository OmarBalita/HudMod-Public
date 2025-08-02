class_name OptionController extends Button


signal selected_option_changed(id: int, option: MenuOption)

@export var options_info: Array[Dictionary]
@export var default_index: int
@export var save_path: String

var options: Array

var selected_option: MenuOption
var selected_id: int

func _ready() -> void:
	pressed.connect(on_pressed)
	options = MenuOption.new_options_with_check_group(options_info, save_path, default_index)
	update()

func update(id = null) -> void:
	if id == null:
		if FileAccess.file_exists(save_path):
			id = ResourceLoader.load(save_path).checked_index
		else:
			id = default_index
	selected_option = options[id]
	selected_id = id
	update_display_option(id)
	selected_option_changed.emit(selected_id, selected_option)

func update_display_option(id: int) -> void:
	text = selected_option.text

func on_pressed() -> void:
	var menu = InterfaceServer.popup_menu(options, self)
	menu.menu_button_pressed.connect(on_menu_button_pressed)

func on_menu_button_pressed(id: int) -> void:
	update(id)
