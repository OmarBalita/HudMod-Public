class_name PathController extends HBoxContainer

signal root_requested()
signal undo_requested(undo_times: int)

@export var path: Array
@export var root_name: StringName = &"Project"

func get_root_name() -> StringName:
	return root_name

func set_root_name(new_val: StringName) -> void:
	root_name = new_val

func update(_path: Array) -> void:
	path = _path
	
	for node: Node in get_children():
		node.queue_free()
	
	for time: int in path.size() + 1:
		time -= 1
		
		var button: Button = IS.create_button("", null, false, false, false, {flat = true})
		var folder_name: String = root_name
		
		if time > -1:
			folder_name = path[time]
		
		var undo_times: int = path.size() - time - 1
		
		button.mouse_entered.connect(change_button_text.bind(button, underline_text(folder_name)))
		button.mouse_exited.connect(change_button_text.bind(button, folder_name))
		button.pressed.connect(on_button_pressed.bind(undo_times))
		
		button.text = folder_name
		add_child(button)
		add_child(IS.create_label("/"))

func underline_text(text: String) -> String:
	var result: String = ""
	var underline_char: String = "\u0332"
	for c: String in text:
		result += c + underline_char
	return result

func change_button_text(button: Button, new_text: String) -> void:
	button.set_text(new_text)

func on_button_pressed(undo_times: int) -> void:
	
	await get_tree().process_frame
	
	if path.size() == 0:
		open_root_menu()
		root_requested.emit()
	else:
		undo_requested.emit(undo_times)

func open_root_menu() -> void:
	pass

