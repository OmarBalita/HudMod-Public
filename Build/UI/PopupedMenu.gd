class_name PopupedMenu extends PanelContainer

signal menu_button_pressed(index: int)
signal global_menu_button_pressed(id: Array)

signal popuped()
signal popdowned()

@export var options: Array

var curr_pos: int:
	set(val):
		if val < 0:
			val = options.size() - 1
		elif val >= options.size():
			val = 0
		while options[val].is_separation_line:
			val += 1 if val > curr_pos else -1
		curr_pos = val
		update_cursor()


var tweener:= TweenerComponent.new()
var options_box:= InterfaceServer.create_box_container(0, true)
var cursor_rect: Panel

var forwarded: PopupedMenu





func _ready() -> void:
	hide()
	_setup()

func _input(event: InputEvent) -> void:
	
	if forwarded:
		return
	
	if event is InputEventKey:
		if event.is_pressed():
			match event.keycode:
				KEY_UP:
					curr_pos -= 1
				KEY_DOWN:
					curr_pos += 1
				KEY_RIGHT:
					pass
				KEY_LEFT:
					popdown()
				KEY_ENTER:
					on_button_pressed(curr_pos)
	
	elif event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		for index in options_box.get_child_count():
			var option = options_box.get_child(index)
			if option is BaseButton:
				if option.get_global_rect().has_point(mouse_pos):
					curr_pos = index
					break
	
	elif event is InputEventMouseButton:
		if not get_global_rect().has_point(get_global_mouse_position()):
			popdown()


func _setup() -> void:
	
	# Setup TweenerComponent
	tweener.easeType = Tween.EASE_OUT
	add_child(tweener)
	
	# Spawn Options
	var margin_container = InterfaceServer.create_margin_container()
	
	for index: int in options.size():
		var option = options[index]
		
		if option == null:
			continue
		
		if option.is_separation_line:
			var separation_line = InterfaceServer.create_h_line_panel(1)
			options_box.add_child(separation_line)
		else:
			var check_group = option.check_group
			var button = InterfaceServer.create_button(option.text, option.icon)
			button.custom_minimum_size.y = 30.0
			button.flat = true
			options_box.add_child(button)
			button.pressed.connect(on_button_pressed.bind(index))
			
			if check_group and check_group.checked_index == index:
				var color_rect = InterfaceServer.create_color_rect(Color.RED)
				color_rect.custom_minimum_size = Vector2(30, 30)
				button.add_child(color_rect)
	
	cursor_rect = InterfaceServer.create_panel()
	add_child(cursor_rect)
	
	margin_container.add_child(options_box)
	add_child(margin_container)
	
	await get_tree().process_frame
	custom_minimum_size.x = size.x + 50
	custom_minimum_size.y = size.y


func popup(pos = null) -> void:
	
	await get_tree().process_frame
	if pos == null:
		pos = get_global_mouse_position()
	
	var window_size = Vector2(get_window().size)
	var dist = pos + custom_minimum_size - window_size
	if dist.x > 0:
		pos.x -= dist.x
	if dist.y > 0:
		pos.y -= dist.y
	
	show()
	global_position = pos
	pivot_offset = size / 2
	tweener.play(self, "scale", [Vector2(.9, .9), Vector2.ONE], [.0, .05])
	await get_tree().process_frame
	curr_pos = 0
	update_cursor()
	popuped.emit()


func popdown() -> void:
	set_meta("ended", true)
	
	tweener.play(self, "scale", [Vector2(.9, .9)], [.05])
	await tweener.finished
	hide()
	
	queue_free()
	popdowned.emit()


func update_cursor() -> void:
	var curr_button = options_box.get_child(curr_pos)
	cursor_rect.global_position = curr_button.global_position
	cursor_rect.size = curr_button.size




func on_button_pressed(index: int) -> void:
	
	if has_meta("ended"):
		return
	
	menu_button_pressed.emit(index)
	
	var option = options[index]
	var forward = option.forward
	var group = option.check_group
	var button = options_box.get_child(index)
	
	if group:
		group.checked_index = index
		ResourceSaver.save(group, group.save_path)
	
	if forward.size():
		
		if forwarded:
			forwarded.queue_free()
		
		var popuped_menu = PopupedMenu.new()
		popuped_menu.options = forward
		popuped_menu.savable = false
		get_parent().add_child(popuped_menu)
		popuped_menu.popup(Vector2(size.x, button.global_position.y))
		
		forwarded = popuped_menu
		popuped_menu.global_menu_button_pressed.connect(on_global_menu_button_pressed)
		popuped_menu.tree_exited.connect(func() -> void: forwarded = null)
	
	else:
		popdown()
	
	global_menu_button_pressed.emit([index])


func on_global_menu_button_pressed(id: Array) -> void:
	id.append(curr_pos)
	global_menu_button_pressed.emit(id)
	popdown()




















