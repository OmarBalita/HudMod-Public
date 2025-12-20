class_name Menu extends Control

signal focus_index_changed(index: int)
signal updated()

@export var options: Array
@export var is_vertical: bool
@export var focus_style: StyleBox = IS.STYLE_ACCENT

var focus_index: int:
	set(val):
		focus_index = val
		
		if val < 0: val = options.size() - 1
		elif val > options.size() - 1: val = 0
		
		if buttons_container:
			var new_focus_button = buttons_container.get_child(val)
			if focus_button: IS.set_font_from_label_settings(focus_button, IS.LABEL_SETTINGS_MAIN)
			if new_focus_button: IS.set_font_from_label_settings(new_focus_button, IS.LABEL_SETTINGS_HEADER)
			focus_button = new_focus_button
			
			await get_tree().process_frame
			if use_tween:
				tweener.play(focus_panel, "position", [focus_button.position], [.2], false, Tween.TRANS_QUART, Tween.EASE_OUT)
				focus_panel.size = focus_button.size
			else:
				set_focus_panel_transform()
		
		focus_index_changed.emit(focus_index)

var use_tween: bool

var tweener: TweenerComponent

var buttons_container: BoxContainer

var focus_panel: Panel
var focus_button: Button

func _ready() -> void:
	update()

func _draw() -> void:
	await get_tree().process_frame
	set_focus_panel_transform()

func update() -> void:
	for i: Node in get_children():
		i.queue_free()
	
	tweener = TweenerComponent.new()
	buttons_container = IS.create_box_container(12, is_vertical)
	focus_panel = IS.create_panel(focus_style)
	
	add_child(focus_panel)
	add_child(buttons_container)
	add_child(tweener)
	
	var focused_option_button: Button
	 
	for index: int in options.size():
		var option: MenuOption = options[index]
		var option_button: Button = IS.create_button(option.text, option.icon, true, false, {flat = true, expand_icon = true})
		option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_button.pressed.connect(set_focus_index.bind(index))
		if not option.function.is_null(): option_button.pressed.connect(option.function)
		for key: StringName in option.get_meta_list():
			var val = option.get_meta(key)
			option_button.set(key, val)
		buttons_container.add_child(option_button)
		if index == focus_index:
			focused_option_button = option_button
	
	set_focus_index(focus_index, false)
	custom_minimum_size = buttons_container.size
	
	updated.emit()

func get_focus_index() -> int:
	return focus_index

func set_focus_index(new_focus_index: int, _use_tween: bool = true) -> void:
	use_tween = _use_tween
	focus_index = new_focus_index

func set_focus_panel_transform() -> void:
	if focus_panel and focus_button:
		focus_panel.position = focus_button.position
		focus_panel.size = focus_button.size

