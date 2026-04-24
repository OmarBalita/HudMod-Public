class_name PopupedMenu extends PopupedControl

signal menu_button_pressed(index: int)
signal global_menu_button_pressed(id: Array)

@export var options: Array
@export var texture_forward: Texture2D = IS.TEXTURE_RIGHT
@export var max_height_ratio: float = .95

var curr_pos: int:
	set(val):
		if options.is_empty(): return
		var old_val = curr_pos
		if val < 0: val = options.size() - 1
		elif val >= options.size(): val = 0
		
		while options[val].is_separation_line:
			val += 1 if val >= old_val else -1
			if val < 0 or val >= options.size(): break
			
		curr_pos = val
		update_cursor()

var options_box:= IS.create_box_container(0, true)
var scroll_container: ScrollContainer
var focus_panel: Panel
var forwarded: PopupedMenu

func _ready() -> void:
	super()
	_setup()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if forwarded: return
		if event.is_pressed():
			match event.keycode:
				KEY_UP: curr_pos -= 1
				KEY_DOWN: curr_pos += 1
				KEY_RIGHT: on_button_forward(curr_pos)
				KEY_LEFT: popdown()
				KEY_ENTER: on_button_pressed(curr_pos)
	
	else:
		if event is InputEventMouseMotion:
			if get_rect().has_point(get_local_mouse_position()):
				update_cursor(false)
		super(event)


func _setup() -> void:
	clip_contents = true
	
	var margin_container: MarginContainer = IS.create_margin_container()
	scroll_container = ScrollContainer.new()
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	
	focus_panel = IS.create_panel(IS.style_body)
	focus_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_panel.visible = false
	add_child(focus_panel)
	
	for index: int in options.size():
		var option: MenuOption = options[index]
		if option == null: continue
		
		if option.is_separation_line:
			options_box.add_child(IS.create_h_line_panel(1))
		else:
			var option_box:= IS.create_box_container()
			var button:= IS.create_button(option.text, option.icon)
			
			button.flat = true
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.mouse_entered.connect(on_button_mouse_entered.bind(index))
			button.pressed.connect(on_button_pressed.bind(index))
			if option.hidden:
				button.disabled = true
			else:
				IS.set_font_from_label_settings(button, IS.label_settings_bold)
				button.modulate.a = .7
			option_box.add_child(button)
			
			if option.check_group and option.check_group.checked_index == index:
				var color_rect:= IS.create_color_rect(Color.RED)
				color_rect.custom_minimum_size.x = 19.0
				option_box.add_child(color_rect)
			
			if option.forward:
				var tr:= IS.create_texture_rect(texture_forward)
				tr.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
				tr.position.x = -20
				button.add_child(tr)
			
			options_box.add_child(option_box)
	
	IS.expand(options_box)
	
	scroll_container.add_child(options_box)
	margin_container.add_child(scroll_container)
	add_child(margin_container)
	
	var screen_h = get_window().size.y * max_height_ratio
	scroll_container.custom_minimum_size.y = min(options_box.get_combined_minimum_size().y, screen_h)
	size = margin_container.get_combined_minimum_size()

func loop_options(method: Callable) -> void:
	var options_boxes: Array[Node] = options_box.get_children()
	for option_box: BoxContainer in options_boxes:
		method.call(option_box)

func update_cursor(auto_scroll: bool = true) -> void:
	
	var curr_button = options_box.get_child(curr_pos)
	focus_panel.global_position = curr_button.global_position
	focus_panel.size = curr_button.size
	focus_panel.show()
	
	if auto_scroll:
		var pos_y: float = focus_panel.global_position.y
		var limit_up: float = scroll_container.global_position.y
		var limit_down: float = limit_up + scroll_container.size.y
		
		if pos_y < limit_up:
			scroll_container.scroll_vertical += pos_y - limit_up
		elif pos_y > limit_down:
			scroll_container.scroll_vertical += pos_y - limit_down + focus_panel.size.y
		
		await get_tree().process_frame
		update_cursor(false)

func on_button_mouse_entered(index: int) -> void:
	curr_pos = index

func on_button_pressed(index: int) -> void:
	if has_meta("ended"): return
	
	var option: MenuOption = options[index]
	var function: Callable = option.function
	var forward: Array = option.forward
	var group: CheckGroup = option.check_group
	
	if not function.is_null():
		function.call()
	
	if group:
		group.checked_index = index
		if not group.save_path.is_empty():
			ResourceSaver.save(group, group.save_path)
	
	if forward and not forward.is_empty():
		on_button_forward(index)
	else:
		popdown()
	
	menu_button_pressed.emit(index)
	global_menu_button_pressed.emit([index])

func on_button_forward(index: int) -> void:
	var option: MenuOption = options[index]
	var forward: Array = option.forward
	
	if not forward or forward.is_empty():
		return
	
	if forwarded:
		forwarded.queue_free()
	
	var popuped_menu := IS.create_popuped_menu(forward)
	get_parent().add_child(popuped_menu)
	
	var target_pos = Vector2(global_position.x + size.x + 5, options_box.get_child(index).global_position.y)
	popuped_menu.popup(target_pos)
	
	forwarded = popuped_menu
	popuped_menu.global_menu_button_pressed.connect(on_global_menu_button_pressed)
	popuped_menu.tree_exited.connect(func() -> void: forwarded = null)

func on_global_menu_button_pressed(id: Array) -> void:
	id.append(curr_pos)
	global_menu_button_pressed.emit(id)
	popdown()
