extends Node

@export var editor_windows_folder: Node = Node.new()

func _ready() -> void:
	add_child(editor_windows_folder)

func popup_window_base(processing_node: Node, window_size: Vector2, window_title: String, is_processing_rect_hidden: bool = false) -> MarginContainer:
	var window: Window = AcceptWindow.new()
	var margin: MarginContainer = IS.create_margin_container()
	
	ObjectServer.describe(window, {
		initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN,
		size = window_size,
		title = window_title,
	})
	
	var processing_rect: ProcessingControl = create_processing_rect(is_processing_rect_hidden)
	window.close_requested.connect(on_window_close_request.bind(window, processing_rect))
	window.tree_exited.connect(processing_rect.queue_free)
	processing_node.add_child(processing_rect)
	
	window.add_child(margin)
	add_child(window)
	
	return margin

func popup_window(processing_node: Node, window_size:= Vector2i(400, 200), window_title:= "Window") -> MarginContainer:
	
	var margin: MarginContainer = popup_window_base(processing_node, window_size, window_title)
	var panel: PanelContainer = IS.create_panel_container(Vector2.ZERO, IS.STYLE_BODY)
	var margin2: MarginContainer = IS.create_margin_container()
	
	panel.add_child(margin2)
	margin.add_child(panel)
	
	return margin2

func popup_borderless_window(processing_node: Node, window_size:= Vector2(400, 200), window_title:= "Window") -> MarginContainer:
	var margin: MarginContainer = popup_window(processing_node, window_size, window_title)
	margin.get_window().borderless = true
	return margin

func popup_accept_window(processing_node: Node, window_size:= Vector2(400, 200), window_title:= "Window", accept_pressed: Callable = Callable(), cancel_pressed: Callable = Callable()) -> BoxContainer:
	
	var window_container: MarginContainer = WindowManager.popup_window(processing_node, window_size, window_title)
	var window: AcceptWindow = window_container.get_window()
	
	var box: BoxContainer = IS.create_box_container(10, true)
	var scroll_cont: ScrollContainer = IS.create_scroll_container()
	var box2: BoxContainer = IS.create_box_container(10, true)
	var accept_box: BoxContainer = IS.create_box_container()
	var accept_button: Button = IS.create_button("Accept", null, true, false, {size_flags_horizontal = Control.SIZE_EXPAND_FILL})
	var cancel_button: Button = IS.create_button("Cancel", null, false, false, {size_flags_horizontal = Control.SIZE_EXPAND_FILL})
	if accept_pressed.is_valid():
		accept_button.pressed.connect(accept_pressed)
	if cancel_pressed.is_valid():
		cancel_button.pressed.connect(cancel_pressed)
		window.close_requested.connect(cancel_pressed)
	
	accept_button.pressed.connect(func() -> void: if window: window.emit_accept())
	cancel_button.pressed.connect(func() -> void: if window: window.emit_cancel())
	
	var on_child_changed: Callable = func(node: Node) -> void:
		box.move_child.call_deferred(accept_box, box.get_child_count())
	
	box.child_entered_tree.connect(on_child_changed)
	box.child_exiting_tree.connect(on_child_changed)
	
	IS.expand(scroll_cont, true, true)
	IS.expand(box2, true, true)
	
	accept_box.add_child(accept_button)
	accept_box.add_child(cancel_button)
	
	scroll_cont.add_child(box2)
	box.add_child(scroll_cont)
	box.add_child(accept_box)
	window_container.add_child(box)
	
	if window:
		window.accept_button = accept_button
		window.cancel_button = cancel_button
	
	return box2

func popup_color_controller_window(processing_node: Node, main_color: Color, on_color_changed: Callable = Callable()) -> PopupedColorController:
	var window_container: MarginContainer = WindowManager.popup_window_base(processing_node, Vector2i(350.0, 650.0), "Pick a Color", true)
	
	var color_controller: PopupedColorController = IS.create_popuped_color_controller(main_color)
	if on_color_changed.is_valid(): color_controller.color_changed.connect(on_color_changed)
	color_controller.poppable_down = false
	color_controller.hidden_on_start = false
	
	window_container.add_child(color_controller)
	
	return color_controller

func create_file_dialog_window(processing_node: Node, file_mode:= FileDialog.FILE_MODE_OPEN_FILES, filters:= PackedStringArray(), window_size:= Vector2(800, 500), title:= "Open Files") -> FileDialog:
	
	var file_dialog: FileDialog = FileDialog.new()
	var processing_rect: ProcessingControl = create_processing_rect()
	
	file_dialog.always_on_top = true
	
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
	file_dialog.dir_selected.connect(func(selected) -> void: close_func.call())
	file_dialog.file_selected.connect(func(selected) -> void: close_func.call())
	file_dialog.files_selected.connect(func(selected) -> void: close_func.call())
	
	processing_node.add_child(processing_rect)
	add_child(file_dialog)
	
	return file_dialog

func create_processing_rect(is_hidden: bool = false) -> ColorRect:
	var rect:= ProcessingControl.new()
	if is_hidden:
		var t: Color = Color.TRANSPARENT
		ObjectServer.describe(rect, {
			color = t,
			back_color = t,
			forward_color = t
		})
	else:
		rect.color = Color(Color.BLACK, .2)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect

func on_window_close_request(window: Window, processing_rect: Node) -> void:
	window.queue_free()
	processing_rect.queue_free()



class AcceptWindow extends Window:
	
	var accept_button: Button
	var cancel_button: Button
	
	signal accepted()
	signal canceled()
	
	func _init() -> void:
		always_on_top = true
	
	func emit_accept() -> void:
		accepted.emit()
		queue_free()
	
	func emit_cancel() -> void:
		canceled.emit()
		close_requested.emit()






