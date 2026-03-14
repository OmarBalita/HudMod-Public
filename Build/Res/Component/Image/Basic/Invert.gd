class_name CompInvert extends SnippetShaderComponentRes

@export var invert_red: bool = true
@export var invert_green: bool = true
@export var invert_blue: bool = true
@export var invert_alpha: bool

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"invert_red": export(bool_args(invert_red)),
		&"invert_green": export(bool_args(invert_green)),
		&"invert_blue": export(bool_args(invert_blue)),
		&"invert_alpha": export(bool_args(invert_alpha))
	}

func _process(frame: int) -> void:
	set_shader_prop(&"invert_red", invert_red)
	set_shader_prop(&"invert_green", invert_green)
	set_shader_prop(&"invert_blue", invert_blue)
	set_shader_prop(&"invert_alpha", invert_alpha)

func _get_shader_global_params_snip() -> String:
	return "
uniform bool {invert_red};
uniform bool {invert_green};
uniform bool {invert_blue};
uniform bool {invert_alpha};
"

func _get_shader_fragment_snip() -> String:
	return "
	if ({invert_red}) color.r = 1. - color.r;
	if ({invert_green}) color.g = 1. - color.g;
	if ({invert_blue}) color.b = 1. - color.b;
	if ({invert_alpha}) alpha = 1. - alpha;
"

