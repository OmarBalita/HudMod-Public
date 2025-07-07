class_name ProcessingControl extends ColorRect

@export var forward_color:= Color("73c4ff99")
@export var back_color:= Color("3b487364")
@export var radius: float = 30.0
@export var width: float = 5.0
@export var speed: float = .01
@export var back_offset: float = 1.0
@export_range(3, 100) var subdivision: int = 24

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var time = Time.get_ticks_msec() * speed
	var pos = size/2
	var tail = 3.15 + time
	draw_arc(pos, radius, time - back_offset, tail - back_offset, subdivision, back_color, width)
	draw_arc(pos, radius, time, tail, subdivision, forward_color, width)
