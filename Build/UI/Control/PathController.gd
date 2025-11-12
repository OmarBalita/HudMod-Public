class_name PathController extends HBoxContainer

signal undo_requested(undo_times: int)

@export var root_name: String = "Project"

func get_root_name() -> String:
	return root_name

func set_root_name(new_val: String) -> void:
	root_name = new_val

func update(path: Array) -> void:
	for node: Node in get_children(): node.queue_free()
	
	for time: int in path.size() + 1:
		time -= 1
		
		var button: Button = IS.create_button("", null, false, false, {flat = true})
		var folder_name: String = root_name
		
		if time > -1:
			folder_name = path[time]
		
		var undo_times: int = path.size() - time - 1
		
		button.mouse_entered.connect(change_button_text.bind(button, underline_text(folder_name)))
		button.mouse_exited.connect(change_button_text.bind(button, folder_name))
		button.pressed.connect(emit_signal.bind("undo_requested", undo_times))
		
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

