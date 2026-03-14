class_name PopupedCategoriesMenu extends PopupedControl

signal menu_button_pressed(option: MenuOption)
signal categories_menu_popuped()

@export var categories_options: Dictionary[MenuOption, Array]

@export_group("Theme")
@export_subgroup("Text")
@export var search_line_text: String = "Search"
@export_subgroup("Texture")
@export var search_texture: Texture2D = load("res://Asset/Icons/magnifying-glass.png")

var categories_menu: Menu
var options_control: BoxContainer
var search_line: LineEdit
var right_scroll_container: ScrollContainer
var focus_panel: Panel

var option_buttons_visibled: Array[Node]

var is_scroll_affect: bool = true

var focused_index: int:
	set(val):
		focused_index = clamp(val, 0, option_buttons_visibled.size() - 1)
		focus_panel.visible = focused_index != -1
		if focused_index == -1: return
		focused_option_btn = option_buttons_visibled[focused_index]
		_update_focus_panel_transform(focused_option_btn)
		_update_left_side()

var focused_option_btn: Button


func _init(_categories_options: Dictionary[MenuOption, Array]) -> void:
	categories_options = _categories_options

func _ready() -> void:
	
	var margin_container: MarginContainer = IS.create_margin_container()
	var split_container: SplitContainer = IS.create_split_container()
	var left_control: PanelContainer = IS.create_panel_container(Vector2.ZERO, null, {custom_minimum_size = Vector2(250, .0)})
	var right_control: SplitContainer = IS.create_split_container(2, true)
	
	categories_menu = IS.create_menu(categories_options.keys(), true, true, {focus_style = IS.STYLE_ACCENT_LEFT})
	categories_menu.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	search_line = IS.create_line_edit(search_line_text, "", search_texture)
	right_scroll_container = IS.create_scroll_container(0)
	var right_margin_container: MarginContainer = IS.create_margin_container()
	options_control = IS.create_box_container(12, true)
	
	focus_panel = IS.create_panel(IS.STYLE_BODY)
	right_margin_container.add_child(focus_panel)
	
	right_margin_container.add_child(options_control)
	right_scroll_container.add_child(right_margin_container)
	
	right_control.add_child(search_line)
	right_control.add_child(right_scroll_container)
	
	IS.add_children(split_container, [left_control, right_control])
	margin_container.add_child(split_container)
	add_child(margin_container)
	
	var category_size: Vector2 = Vector2(450., .0)
	var categories_count: int = categories_options.size()
	
	for index: int in categories_count:
		
		var category_key: MenuOption = categories_options.keys()[index]
		var category_options: Array = categories_options[category_key]
		var category: Category = IS.create_category(true, category_key.text, Color.BLACK, category_size)
		category.is_expanded = true
		category.has_custom_color = false
		
		for option: MenuOption in category_options:
			var button: Button = IS.create_button(option.text, option.icon, false, true, {custom_minimum_size = Vector2(category_size.x, 35.0)})
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.mouse_entered.connect(on_option_button_mouse_entered.bind(button))
			button.pressed.connect(on_option_button_pressed.bind(option))
			category.add_content(button)
		
		options_control.add_child(category)
	
	options_control.add_child(IS.create_empty_control(.0, 250.))
	
	search_line.text_changed.connect(on_search_line_text_changed)
	
	await get_tree().process_frame
	
	var scroll_to: Callable = func(y_pos: float) -> void:
		var tween:= create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(right_scroll_container, "scroll_vertical", y_pos, .2)
		tween.play()
		is_scroll_affect = false
		await tween.finished
		is_scroll_affect = true
	
	for index: int in categories_options.size():
		var category_option: MenuOption = categories_options.keys()[index]
		var control_pos: float = options_control.get_child(index).position.y
		category_option.function = scroll_to.bind(control_pos)
	
	left_control.add_child(categories_menu)
	
	custom_minimum_size = Vector2(600., 400.)
	
	IS.expand(right_margin_container)
	
	await super()
	categories_menu_popuped.emit()
	
	search_line.grab_focus()
	
	await get_tree().process_frame
	_search(search_line.text)

func _input(event: InputEvent) -> void:
	super(event)
	
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		
		if is_scroll_affect:
			_update_left_side()
	
	elif event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_DOWN:
				focused_index += 1
			KEY_UP:
				focused_index -= 1
			KEY_ENTER:
				if focus_panel.visible:
					focused_option_btn.pressed.emit()

func _update_left_side() -> void:
	var categories_scopes: Array[float] = [.0]
	var curr_scroll_vertical: float = right_scroll_container.scroll_vertical
	for index: int in options_control.get_child_count():
		var control: Control = options_control.get_child(index)
		if control is not Category:
			continue
		categories_scopes.append(control.position.y + control.size.y)
		if curr_scroll_vertical > categories_scopes[index] and curr_scroll_vertical < categories_scopes[index + 1]:
			categories_menu.set_focus_index(index)
			break

func _search(new_text: String) -> void:
	new_text = new_text.to_lower()
	
	option_buttons_visibled.clear()
	
	for category: Control in options_control.get_children():
		if category is not Category:
			continue
		
		var buttons_visibled: int
		
		for button: Button in category.get_contents():
			var is_visible: bool = StringHelper.fuzzy_search(new_text, button.text.to_lower())
			button.visible = is_visible
			buttons_visibled += int(is_visible)
			if is_visible:
				button.set_meta(&"index", option_buttons_visibled.size())
				option_buttons_visibled.append(button)
		
		category.visible = buttons_visibled != 0
	
	focused_index = 0

func _update_focus_panel_transform(control: Control) -> void:
	await get_tree().process_frame
	
	focus_panel.global_position = control.global_position
	focus_panel.size = control.size
	
	var pos_y: float = focus_panel.global_position.y
	var limit_up: float = right_scroll_container.global_position.y
	var limit_down: float = limit_up + right_scroll_container.size.y
	
	if pos_y < limit_up:
		right_scroll_container.scroll_vertical += pos_y - limit_up
	elif pos_y > limit_down:
		right_scroll_container.scroll_vertical += pos_y - limit_down + focus_panel.size.y


func on_search_line_text_changed(new_text: String) -> void:
	_search(new_text)
	focused_index = 0

func on_option_button_mouse_entered(button: Button) -> void:
	focused_index = button.get_meta(&"index")

func on_option_button_pressed(menu_option: MenuOption) -> void:
	menu_button_pressed.emit(menu_option)
	var embeded_func: Callable = menu_option.function
	if embeded_func.is_valid(): embeded_func.call()
	popdown()

