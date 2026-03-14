class_name CompLGG extends SnippetShaderComponentRes

@export var lift:= Color.BLACK
@export var gamma:= Color.WHITE
@export var gain:= Color.WHITE
@export var offset: float

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"lift": export(color_args(lift)),
		&"gamma": export(color_args(gamma)),
		&"gain": export(color_args(gain)),
		&"offset": export(float_args(offset, -1., 1., .001))
	}

func _process(frame: int) -> void:
	set_shader_prop(&"lift", lift)
	set_shader_prop(&"gamma", gamma)
	set_shader_prop(&"gain", gain)
	set_shader_prop(&"offset", offset)

func _get_shader_global_params_snip() -> String:
	return "
uniform vec3 {lift}: source_color;
uniform vec3 {gamma}: source_color = vec3(1.);
uniform vec3 {gain}: source_color = vec3(1.);
uniform float {offset}: hint_range(-1., 1.);
"

func _get_shader_fragment_snip() -> String:
	return "
	// LGG + Offset method
	color = pow(max(vec3(.0), color * {gain} + {lift} + {offset}), 1. / {gamma});
"

