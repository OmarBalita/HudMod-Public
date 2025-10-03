class_name ShaderNode extends Resource

@export var properties: Dictionary[StringName, Variant]
@export var inputs: Array[Dictionary]
@export var outputs: Array[Dictionary]

func get_properties() -> Dictionary[StringName, Variant]:
	return properties

func set_properties(_properties: Dictionary[StringName, Variant]) -> void:
	properties = _properties

func get_inputs() -> Array[Dictionary]:
	return inputs

func set_inputs(_inputs: Array[Dictionary]) -> void:
	inputs = _inputs

func get_outputs() -> Array[Dictionary]:
	return outputs

func set_outputs(_outputs: Array[Dictionary]) -> void:
	outputs = _outputs

func _get_module() -> String:
	return ""


