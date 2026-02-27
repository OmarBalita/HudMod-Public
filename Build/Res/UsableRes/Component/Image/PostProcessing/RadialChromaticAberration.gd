class_name CompRadialChromaticAberration extends PassShaderComponentRes

@export var amount: float = 1.
@export var quality: int = 8

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"amount": export(float_args(amount, .0, 256.)),
		&"quality": export(int_args(quality, 1, 32))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/RadialChromaticAberration.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"amount", amount)
	set_shader_prop(&"quality", quality)
