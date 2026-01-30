class_name CompWave2D extends ComponentRes

enum WaveMethod {
	WAVE_METHOD_SIN,
	WAVE_METHOD_COS
}

@export var enable_x: bool = false
@export var enable_y: bool = true
@export var method: WaveMethod
@export var speed: float = 10.
@export var domain: float = 100.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var enabled_cond: Array = [
		func() -> bool:
			return self.enable_x or self.enable_y,
		[true]
	]
	return {
		&"enable_x": export(bool_args(enable_x)),
		&"enable_y": export(bool_args(enable_y)),
		&"method": export(options_args(method, WaveMethod)),
		&"speed": export(float_args(speed), enabled_cond),
		&"domain": export(float_args(domain), enabled_cond)
	}

func _process(frame: int) -> void:
	
	var method: Callable
	if method_type == 0:
		method = sin
	else:
		method = cos
	
	var result: float = method.call(deg_to_rad(frame) * speed) * domain
	var submitted_result: Vector2
	
	if enable_x: submitted_result.x = result
	if enable_y: submitted_result.y = result
	
	submit_stacked_value(&"position", submitted_result)
