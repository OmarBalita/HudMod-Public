class_name PopupedMenu extends PopupedControl

signal menu_button_pressed(index: int)
signal global_menu_button_pressed(id: Array)

@export var options: Array

@export var texture_forward: Texture2D = IS.TEXTURE_RIGHT

var curr_pos: int:
	set(val):
		if val < 0:
			val = options.size() - 1
		elif val >= options.size():
			val = 0
		while options[val].is_separation_line:
			val += 1 if val > curr_pos else -1
		if curr_pos != val:
			curr_pos = val
			update_cursor()

var options_box:= IS.create_box_container(0, true)
var cursor_rect: Panel

var forwarded: PopupedMenu


func _ready() -> void:
	super()
	_setup()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if forwarded:
			return
		if event.is_pressed():
			match event.keycode:
				KEY_UP:
					curr_pos -= 1
				KEY_DOWN:
					curr_pos += 1
				KEY_RIGHT:
					on_button_forward(curr_pos)
				KEY_LEFT:
					popdown()
				KEY_ENTER:
					on_button_pressed(curr_pos)
	
	elif event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		for index in options_box.get_child_count():
			var option = options_box.get_child(index)
			if option is BoxContainer:
				if option.get_global_rect().has_point(mouse_pos):
					curr_pos = index
					break
	else:
		super(event)

func _setup() -> void:
	
	# Spawn Options
	var margin_container = IS.create_margin_container()
	
	for index: int in options.size():
		var option: MenuOption = options[index]
		
		if option == null:
			continue
		
		if option.is_separation_line:
			var separation_line:= IS.create_h_line_panel(1)
			options_box.add_child(separation_line)
		
		else:
			var check_group:= option.check_group
			var option_box:= IS.create_box_container()
			var button:= IS.create_button(option.text, option.icon)
			
			if check_group and check_group.checked_index == index:
				var color_rect:= IS.create_color_rect(Color.RED)
				color_rect.custom_minimum_size.x = 10.0
				option_box.add_child(color_rect)
			
			if option.forward:
				var forward_texture_rect:= IS.create_texture_rect(texture_forward)
				forward_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
				forward_texture_rect.position.x = size.x - texture_forward.get_width() - 10.
				button.add_child(forward_texture_rect)
			
			button.flat = true
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.pressed.connect(on_button_pressed.bind(index))
			option_box.add_child(button)
			
			options_box.add_child(option_box)
	
	cursor_rect = IS.create_panel(IS.STYLE_BODY)
	add_child(cursor_rect)
	
	margin_container.add_child(options_box)
	add_child(margin_container)


func popup(pos = null) -> void:
	await super(pos)
	await get_tree().process_frame
	curr_pos = 0
	update_cursor()


func update_cursor() -> void:
	var curr_button = options_box.get_child(curr_pos)
	cursor_rect.show()
	cursor_rect.global_position = curr_button.global_position
	cursor_rect.size = curr_button.size



func on_button_pressed(index: int) -> void:
	if has_meta("ended"):
		return
	
	var option: MenuOption = options[index]
	var function: Callable = option.function
	var forward: Array[MenuOption] = option.forward
	var group: CheckGroup = option.check_group
	var button = options_box.get_child(index)
	
	if not function.is_null():
		function.call()
	
	if group:
		group.checked_index = index
		if not group.save_path.is_empty():
			ResourceSaver.save(group, group.save_path)
	
	if forward:
		on_button_forward(index)
	else:
		popdown()
	
	menu_button_pressed.emit(index)
	global_menu_button_pressed.emit([index])

func on_button_forward(index: int) -> void:
	var option: MenuOption = options[index]
	var forward: Array[MenuOption] = option.forward
	
	if not forward:
		return
	
	if forwarded:
		forwarded.queue_free()
	
	var popuped_menu:= IS.create_popuped_menu(forward)
	get_parent().add_child(popuped_menu)
	popuped_menu.popup(Vector2(position.x + size.x, options_box.get_child(index).global_position.y))
	
	forwarded = popuped_menu
	popuped_menu.global_menu_button_pressed.connect(on_global_menu_button_pressed)
	popuped_menu.tree_exited.connect(func() -> void: forwarded = null)


func on_global_menu_button_pressed(id: Array) -> void:
	id.append(curr_pos)
	global_menu_button_pressed.emit(id)
	popdown()

