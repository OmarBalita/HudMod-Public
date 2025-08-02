extends Node


func popup_window(processing_node: Node, window_size:= Vector2i(400, 200), window_title:= "Window") -> MarginContainer:
	
	var window = Window.new()
	var margin = InterfaceServer.create_margin_container()
	var panel = InterfaceServer.create_panel_container(Vector2.ZERO, InterfaceServer.STYLE_BODY)
	var margin2 = InterfaceServer.create_margin_container()
	
	var processing_rect = create_processing_rect()
	
	window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	window.size = window_size
	window.title = window_title
	window.unresizable = true
	window.close_requested.connect(on_window_close_request.bind(window, processing_rect))
	
	processing_node.add_child(processing_rect)
	
	panel.add_child(margin2)
	margin.add_child(panel)
	window.add_child(margin)
	add_child(window)
	
	return margin2


func popup_borderless_window(processing_node: Control, window_size:= Vector2(400, 200), window_title:= "Window") -> Window:
	var window = popup_window(processing_node, window_size, window_title)
	window.borderless = true
	return window


func popup_accept_window(processing_node: Node, window_size:= Vector2(400, 200), window_title:= "Window", accept_pressed = null, cancel_pressed = null) -> BoxContainer:
	
	var window_container = WindowManager.popup_window(processing_node, window_size, window_title)
	
	var box = InterfaceServer.create_box_container(10, true)
	var accept_box = InterfaceServer.create_box_container()
	var accept_button = InterfaceServer.create_button("Accept", null, true, false, {size_flags_horizontal = Control.SIZE_EXPAND_FILL})
	var cancel_button = InterfaceServer.create_button("Cancel", null, false, false, {size_flags_horizontal = Control.SIZE_EXPAND_FILL})
	if accept_pressed != null: accept_button.pressed.connect(accept_pressed)
	if cancel_pressed != null: cancel_button.pressed.connect(cancel_pressed)
	accept_button.pressed.connect(emit_close_window.bind(window_container.get_window()))
	cancel_button.pressed.connect(emit_close_window.bind(window_container.get_window()))
	
	var on_child_changed = func(node: Node):
		#await get_tree().process_frame
		box.move_child.call_deferred(accept_box, box.get_child_count())
	
	box.child_entered_tree.connect(on_child_changed)
	box.child_exiting_tree.connect(on_child_changed)
	
	accept_box.add_child(accept_button)
	accept_box.add_child(cancel_button)
	box.add_child(accept_box)
	window_container.add_child(box)
	
	return box



func create_file_dialog_window(processing_node: Node, file_mode:= FileDialog.FILE_MODE_OPEN_FILES, filters:= PackedStringArray(), window_size:= Vector2(800, 500), title:= "Open Files") -> FileDialog:
	
	var file_dialog: FileDialog = FileDialog.new()
	var processing_rect = create_processing_rect()
	
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = file_mode
	for filter in filters:
		file_dialog.add_filter("*%s*" % filter)
	file_dialog.size = window_size
	file_dialog.title = title
	
	var close_func = on_window_close_request.bind(file_dialog, processing_rect)
	file_dialog.close_requested.connect(close_func)
	file_dialog.canceled.connect(close_func)
	file_dialog.confirmed.connect(close_func)
	file_dialog.dir_selected.connect(func(selected): close_func.call())
	file_dialog.file_selected.connect(func(selected): close_func.call())
	file_dialog.files_selected.connect(func(selected): close_func.call())
	
	processing_node.add_child(processing_rect)
	add_child(file_dialog)
	
	return file_dialog








func create_processing_rect() -> ColorRect:
	var rect = ProcessingControl.new()
	rect.color = Color(Color.BLACK, .5)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect








func emit_close_window(window: Window) -> void:
	window.close_requested.emit()







func on_window_close_request(window: Window, processing_rect: Node) -> void:
	window.queue_free()
	processing_rect.queue_free()
