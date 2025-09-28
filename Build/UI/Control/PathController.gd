class_name PathController extends HBoxContainer

signal undo_requested(undo_times: int)

func update(path: Array) -> void:
	for node: Node in get_children(): node.queue_free()
	
	for time in path.size() + 1:
		time -= 1
		
		var button = IS.create_button("", null, false, false, {flat = true})
		var folder_name = "Project"
		
		if time > -1:
			folder_name = path[time]
		
		var undo_times = path.size() - time - 1
		button.pressed.connect(emit_signal.bind("undo_requested", undo_times))
		
		button.text = folder_name
		add_child(button)
		add_child(IS.create_label("/"))

