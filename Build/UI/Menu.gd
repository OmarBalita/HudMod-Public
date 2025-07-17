class_name Menu extends Control

signal button_pressed(index: int)

@export var options: Array[MenuOption]

@export var is_vertical: bool

var focus_button: Button
var focus_index: int

var tweener: TweenerComponent
var buttons_container: BoxContainer
var focus_panel: Panel



func _ready() -> void:
	update()

func _draw() -> void:
	await get_tree().process_frame
	focus_panel.position = focus_button.position
	focus_panel.size = focus_button.size



func update() -> void:
	
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	for i in get_children(): i.queue_free()
	
	tweener = TweenerComponent.new()
	buttons_container = InterfaceServer.create_box_container(20, is_vertical)
	focus_panel = InterfaceServer.create_panel(InterfaceServer.STYLE_ACCENT)
	
	add_child(focus_panel)
	add_child(buttons_container)
	add_child(tweener)
	
	var focused_option_button: Button
	 
	for index in options.size():
		var option = options[index]
		var option_button = InterfaceServer.create_button(option.text, option.icon, true, false, {flat = true})
		option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_button.pressed.connect(on_option_button_pressed.bind(option_button, index))
		buttons_container.add_child(option_button)
		if index == 0: focused_option_button = option_button
	
	await get_tree().process_frame
	on_option_button_pressed(focused_option_button, 0)





func on_option_button_pressed(button: Button, index: int) -> void:
	
	if focus_button:
		InterfaceServer.set_font_from_label_settings(focus_button, InterfaceServer.LABEL_SETTINGS_MAIN)
	InterfaceServer.set_font_from_label_settings(button, InterfaceServer.LABEL_SETTINGS_HEADER)
	
	focus_button = button
	focus_index = index
	button_pressed.emit(index)
	
	tweener.play(focus_panel, "position", [focus_button.position], [.2], false, Tween.TRANS_QUART, Tween.EASE_OUT)
	tweener.play(focus_panel, "size", [focus_button.size], [.2])
