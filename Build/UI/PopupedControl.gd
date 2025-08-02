class_name PopupedControl extends PanelContainer

signal popuped()
signal popdowned()

@export_group("Custom Properties")
@export var popdown_when_mouse_move: bool
@export var popdown_duration: float = 1.0
@export var popup_speed: float = .05
@export var popdown_speed: float = .05

var mouse_move_popdown_requested: bool

var tweener:= TweenerComponent.new()


func _ready() -> void:
	# Setup TweenerComponent
	tweener.easeType = Tween.EASE_OUT
	add_child(tweener)
	
	# Connections
	
	# Setup Base Settings
	hide()
	await get_tree().process_frame
	custom_minimum_size.x = size.x + 50
	custom_minimum_size.y = size.y




func _input(event: InputEvent) -> void:
	var mouse_in = get_global_rect().has_point(get_global_mouse_position())
	if event is InputEventMouseButton:
		if event.is_pressed() and not mouse_in:
			popdown()
	elif event is InputEventMouseMotion:
		if popdown_when_mouse_move and not mouse_move_popdown_requested:
			mouse_move_popdown_requested = true
			await get_tree().create_timer(popdown_duration).timeout
			if not mouse_in:
				popdown()
			mouse_move_popdown_requested = false


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
	tweener.play(self, "scale", [Vector2(.9, .9), Vector2.ONE], [.0, popup_speed])
	tweener.play(self, "modulate:a", [.0, 1.0], [.0, popup_speed])
	popuped.emit()


func popdown() -> void:
	set_meta("ended", true)
	tweener.play(self, "scale", [Vector2(.9, .9)], [popdown_speed])
	tweener.play(self, "modulate:a", [.0], [popdown_speed])
	await tweener.finished
	hide()
	
	queue_free()
	popdowned.emit()


