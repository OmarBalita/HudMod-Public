class_name PopupedCategoriesMenu extends PopupedControl

signal menu_button_pressed(option: MenuOption)

@export var categories_options: Dictionary[MenuOption, Array]

@export_group("Theme")
@export_subgroup("Text")
@export var search_line_text: String = "Search"
@export_subgroup("Texture")
@export var search_texture: Texture2D = load("res://Asset/Icons/magnifying-glass.png")

var categories_menu: Menu
var options_control: BoxContainer
var search_line: LineEdit
var scroll_container: ScrollContainer

var is_scroll_affect: bool = true


func _init(_categories_options: Dictionary[MenuOption, Array]) -> void:
	categories_options = _categories_options

func _ready() -> void:
	
	var margin_container: MarginContainer = IS.create_margin_container()
	var split_container: SplitContainer = IS.create_split_container()
	var left_control: PanelContainer = IS.create_panel_container(Vector2.ZERO, null, {custom_minimum_size = Vector2(200, .0)})
	var right_control: SplitContainer = IS.create_split_container(2, true)
	
	categories_menu = IS.create_menu(categories_options.keys(), true, true, {focus_style = IS.STYLE_ACCENT_LEFT})
	search_line = IS.create_line_edit(search_line_text, "", search_texture)
	scroll_container = IS.create_scroll_container(0)
	var right_margin_container: MarginContainer = IS.create_margin_container()
	options_control = IS.create_box_container(12, true)
	
	right_margin_container.add_child(options_control)
	scroll_container.add_child(right_margin_container)
	
	right_control.add_child(search_line)
	right_control.add_child(scroll_container)
	
	IS.add_childs(split_container, [left_control, right_control])
	margin_container.add_child(split_container)
	add_child(margin_container)
	
	var category_size: Vector2 = Vector2(400.0,.0)
	var categories_count: int = categories_options.size()
	for index: int in categories_count:
		var category_key: MenuOption = categories_options.keys()[index]
		var category_options: Array = categories_options[category_key]
		var category_box: Category = IS.create_category(true, category_key.text, Color.BLACK, category_size)
		category_box.is_expanded = true
		category_box.has_custom_color = false
		#IS.add_childs(category_box, [IS.create_name_label(category_key.text), IS.create_h_line_panel()])
		for option: MenuOption in category_options:
			var button: Button = IS.create_button(option.text, option.icon, false, true, {custom_minimum_size = Vector2(category_size.x, 35.0)})
			button.pressed.connect(on_option_button_pressed.bind(option))
			category_box.add_content(button)
		options_control.add_child(category_box)
	
	search_line.text_changed.connect(on_search_line_text_changed)
	
	await get_tree().process_frame
	
	var scroll_to: Callable = func(y_pos: float) -> void:
		var tween:= create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(scroll_container, "scroll_vertical", y_pos, .2)
		tween.play()
		is_scroll_affect = false
		await tween.finished
		is_scroll_affect = true
	
	for index: int in categories_options.size():
		var category_option: MenuOption = categories_options.keys()[index]
		var control_pos: float = options_control.get_child(index).position.y
		category_option.function = scroll_to.bind(control_pos)
	
	left_control.add_child(categories_menu)
	
	await super()
	custom_minimum_size = Vector2(600, 400)
	
	IS.expand(right_margin_container)
	search_line.grab_focus()


func _input(event: InputEvent) -> void:
	super(event)
	if is_scroll_affect:
		var categories_scopes: Array[float] = [.0]
		var curr_scroll_vertical: float = scroll_container.scroll_vertical
		for index: int in options_control.get_child_count():
			var category_box: Category = options_control.get_child(index)
			categories_scopes.append(category_box.position.y + category_box.size.y)
			if curr_scroll_vertical > categories_scopes[index] and curr_scroll_vertical < categories_scopes[index + 1]:
				categories_menu.set_focus_index(index)
				break

func on_search_line_text_changed(new_text: String) -> void:
	var categories_is_expanded: bool = not new_text.is_empty()
	for category_box: Category in options_control.get_children():
		category_box.is_expanded = categories_is_expanded
		var buttons_visibled: int
		for control: Control in category_box.get_contents():
			var is_visible: bool = control.text.containsn(new_text) or new_text.is_empty()
			control.visible = is_visible
			buttons_visibled += int(is_visible)
		category_box.visible = buttons_visibled != 0

func on_option_button_pressed(menu_option: MenuOption) -> void:
	menu_button_pressed.emit(menu_option)
	var embeded_func: Callable = menu_option.function
	if embeded_func.is_valid(): embeded_func.call()
	popdown()
