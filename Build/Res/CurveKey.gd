class_name CurveKey extends Resource

enum ControlMode {
	CONTROL_MODE_FREE,
	CONTROL_MODE_ALIGNED,
	CONTROL_MODE_VECTOR,
	CONTROL_MODE_NONE
}

enum InterpolationMode {
	INTERPOLATION_MODE_CONSTANT,
	INTERPOLATION_MODE_LINEAR,
	INTERPOLATION_MODE_BEZIER_CURVE,
	INTERPOLATION_MODE_EASE_IN,
	INTERPOLATION_MODE_EASE_OUT,
	INTERPOLATION_MODE_EASE_IN_OUT,
	INTERPOLATION_MODE_EXPO_IN_OUT,
	INTERPOLATION_MODE_CIRC_IN_OUT,
	INTERPOLATION_MODE_CUBIC,
	INTERPOLATION_MODE_QUART,
	INTERPOLATION_MODE_QUINT,
	INTERPOLATION_MODE_ELASTIC,
	INTERPOLATION_MODE_BOUNCE
}

@export var value: float
@export var left_control: Vector2
@export var right_control: Vector2
@export var control_mode: ControlMode
@export var interpolation_mode: InterpolationMode

var interpolation_func: Callable

static func new_curve_key(_value: float, _left_control:= Vector2(-2.5, .0), _right_control:= Vector2(2.5, .0), _control_mode: ControlMode = 0, _interpolation_mode: InterpolationMode = 2) -> CurveKey:
	var curve_key:= CurveKey.new()
	curve_key.value = _value
	curve_key.left_control = _left_control
	curve_key.right_control = _right_control
	curve_key.control_mode = _control_mode
	curve_key.interpolation_mode = _interpolation_mode
	return curve_key

func get_value() -> float:
	return value

func set_value(new_value: float) -> void:
	value = new_value

func get_left_control() -> Vector2:
	return left_control

func set_left_control(new_val: Vector2, left_reset_dir: Vector2 = Vector2.LEFT) -> void:
	if control_mode == ControlMode.CONTROL_MODE_NONE: return
	left_control = new_val
	match control_mode:
		1: right_control = -left_control
		2: set_left_control_vector(left_reset_dir)

func get_right_control() -> Vector2:
	return right_control

func set_right_control(new_val: Vector2, right_reset_dir: Vector2 = Vector2.RIGHT) -> void:
	if control_mode == ControlMode.CONTROL_MODE_NONE: return
	right_control = new_val
	match control_mode:
		1: left_control = -right_control
		2: set_right_control_vector(right_reset_dir)

func set_left_control_vector(left_reset_dir: Vector2) -> void:
	left_reset_dir = left_reset_dir.normalized()
	left_control = left_reset_dir * left_control.length()

func set_right_control_vector(right_reset_dir: Vector2) -> void:
	right_reset_dir = right_reset_dir.normalized()
	right_control = right_reset_dir * right_control.length()

func get_control_mode() -> ControlMode:
	return control_mode

func set_control_mode(new_val: ControlMode, left_reset_dir:= Vector2.LEFT, right_reset_dir:= Vector2.RIGHT) -> void:
	control_mode = new_val
	
	match control_mode:
		0:
			pass
		1:
			right_control = -left_control
		2:
			set_left_control_vector(left_reset_dir)
			set_right_control_vector(right_reset_dir)
		3:
			left_control = Vector2.ZERO
			right_control = Vector2.ZERO

func move_control_mode(left_reset_dir: Vector2 = Vector2.LEFT, right_reset_dir:= Vector2.RIGHT) -> void:
	var new_control_mode: ControlMode = control_mode + 1
	if new_control_mode > ControlMode.size() - 1:
		new_control_mode = 0
	set_control_mode(new_control_mode, left_reset_dir, right_reset_dir)

func get_interpolation_mode() -> InterpolationMode:
	return interpolation_mode

func set_interpolation_mode(new_val: InterpolationMode) -> void:
	interpolation_mode = new_val

func get_interpolation_func() -> Callable:
	return interpolation_func

func set_interpolation_func(new_val: Callable) -> void:
	interpolation_func = new_val

