class_name ProcessingControl extends ColorRect

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
	draw_arc(pos, radius, time - back_offset, tail - back_offset, subdivision, Color(IS.color_accent, .5), width, true)
	draw_arc(pos, radius, time, tail, subdivision, IS.color_accent, width, true)
