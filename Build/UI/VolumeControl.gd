class_name VolumeControl extends Control

@export var color_range: ColorRangeRes
@export var step_size: float = 4.0
@export var step_between_space: float = 2.0
@export var margin_y: float = 7.5

var volume_steps: int

var energy_left: float
var energy_right: float

var analyzer: AudioEffectSpectrumAnalyzerInstance

func update() -> void:
	var magnitude: Vector2 = analyzer.get_magnitude_for_frequency_range(0, 22000, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX)
	energy_left = clamp((linear_to_db(magnitude.x) + 60.) / 60., .0, 1.0)
	energy_right = clamp((linear_to_db(magnitude.y) + 60.) / 60., .0, 1.0)
	queue_redraw()

func stop() -> void:
	await get_tree().create_timer(.2).timeout
	energy_left = .0
	energy_right = .0
	queue_redraw()

func _init(_color_range: ColorRangeRes = null, _step_size: float = 4.0, _step_between_space: float = 2.0) -> void:
	if color_range:
		color_range = _color_range
	else:
		color_range = ColorRangeRes.new()
		color_range.keys.clear()
		color_range.add_key(0.0, Color.LIME_GREEN)
		color_range.add_key(0.45, Color.YELLOW)
		color_range.add_key(0.75, Color.ORANGE)
		color_range.add_key(1.0, Color.DARK_RED)
	step_size = _step_size
	step_between_space = _step_between_space
	
	custom_minimum_size.x = 50.
	IS.expand(self, true, true)

func _ready():
	var bus_index: int = AudioServer.get_bus_index("Master")
	analyzer = AudioServer.get_bus_effect_instance(bus_index, 0)

func _draw() -> void:
	
	var rect_offset_x: float = 20.0
	var size_half: Vector2 = (size - Vector2(rect_offset_x, .0)) / 2.0
	
	volume_steps = size_half.x / step_size
	
	var step_offset: float = (size.x - rect_offset_x) / float(volume_steps)
	var step_size: float = step_offset - step_between_space
	
	var rect_size_l:= Vector2(max(1., step_size), size_half.y - margin_y - 2)
	var rect_size_r:= Vector2(max(1., step_size), size_half.y - margin_y)
	
	var font:= IS.LABEL_SETTINGS_MAIN.font
	draw_multiline_string(font, Vector2(.0, size_half.y - 5.), "L")
	draw_multiline_string(font, Vector2(.0, size_half.y + 20.), "R")
	
	for step: int in volume_steps:
		var rect_pos_x: float = rect_offset_x + step * step_offset
		var step_ratio: float = step / float(volume_steps)
		
		var curr_color: Color = color_range.sample(step_ratio)
		var left_color: Color = Color(curr_color, 1.0 if energy_left > step_ratio else .25)
		var right_color: Color = Color(curr_color, 1.0 if energy_right > step_ratio else .25)
		
		draw_rect(Rect2(
				Vector2(rect_pos_x, margin_y),
				rect_size_l
			), left_color
		)
		
		draw_rect(Rect2(
				Vector2(rect_pos_x, size_half.y + 2),
				rect_size_r
			), right_color
		)



