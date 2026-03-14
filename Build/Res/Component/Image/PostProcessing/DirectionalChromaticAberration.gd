class_name CompDirectionalChromaticAberration extends PassShaderComponentRes

@export var direction: Vector2 = Vector2.RIGHT
@export var amount: float = .02
@export var quality: int = 8

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"direction": export(vec2_args(direction)),
		&"amount": export(float_args(amount)),
		&"quality": export(int_args(quality, 1, 32))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/DirectionalChromaticAberration.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"direction", direction)
	set_shader_prop(&"amount", amount)
	set_shader_prop(&"quality", quality)

