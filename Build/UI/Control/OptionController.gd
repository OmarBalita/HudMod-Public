class_name OptionController extends Button

signal selected_option_changed(id: int, option: MenuOption)

@export var save_path: String

var options: Array

var selected_id: int:
	set(val):
		selected_id = val
		if options.size() > val:
			selected_option = options[val]
			if is_node_ready():
				update_display_option(val)

var selected_option: MenuOption

func _ready() -> void:
	pressed.connect(on_pressed)
	update_display_option(selected_id)

func update_display_option(id: int) -> void:
	text = options[id].text

func get_selected_id() -> int:
	return selected_id

func set_selected_id(new_selected_id: int) -> void:
	selected_id = new_selected_id
	selected_option_changed.emit(selected_id, selected_option)

func set_selected_id_manually(new_selected_id: int) -> void:
	selected_id = new_selected_id

func on_pressed() -> void:
	var menu: PopupedMenu = IS.popup_menu(options, self, get_window())
	menu.menu_button_pressed.connect(on_menu_button_pressed)

func on_menu_button_pressed(id: int) -> void:
	set_selected_id(id)
