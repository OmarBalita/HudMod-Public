class_name CompTextBounce extends Text2DComponentRes

@export var jump_height: float = 50.
@export var speed: float = 15.
@export var phase_shift: float = 20.
@export var pause_duration: float = 1.
@export var squish_fly: bool = true
@export var squish_ground: bool = true
@export var squish_scale: float = 1.

const MOVE_PERIOD: float = 180.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"jump_height": export(float_args(jump_height)),
		&"speed": export(float_args(speed)),
		&"phase_shift": export(float_args(phase_shift)),
		&"pause_duration": export(float_args(pause_duration)),
		&"Squish": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"squish_fly": export(bool_args(squish_fly)),
		&"squish_ground": export(bool_args(squish_ground)),
		&"squish_scale": export(float_args(squish_scale, .01, 2., .001), [func() -> bool: return squish_fly or squish_ground, [true]]),
		&"_Squish": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	}

func _process_char_fx(line_idx: int, line_data: Text2DClipRes.LineData, idx: int, global_idx: int, glyph: Dictionary, char: CharFXTransform) -> void:
	var wait_period: float = MOVE_PERIOD * pause_duration
	var total_period: float = MOVE_PERIOD + wait_period
	
	var curr_time: float = fmod(global_idx * phase_shift + char.elapsed_time * speed, total_period)
	var curr_time_rad: float = deg_to_rad(curr_time)
	
	var bounce: float
	var s_factor: float
	
	if curr_time < MOVE_PERIOD:
		var sin_time: float = sin(curr_time_rad)
		bounce = sin_time * jump_height
		if squish_fly:
			s_factor = -sin_time
	else:
		bounce = .0
		if squish_ground:
			s_factor = sin((curr_time_rad - PI) / pause_duration)
	
	char.offset.y -= bounce
	
	s_factor *= squish_scale * .5
	char.transform.x.x += s_factor
	char.transform.y.y -= s_factor
	char.offset.y += line_data.height / 2. * s_factor

