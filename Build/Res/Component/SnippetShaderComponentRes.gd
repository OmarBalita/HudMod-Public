@abstract class_name SnippetShaderComponentRes extends ShaderComponentRes

var shader_params_names_list: Dictionary[String, String]

func set_shader_prop(prop_key: StringName, prop_val: Variant) -> void:
	owner.get_shader_material().set_shader_parameter(get_shader_param_code_name(prop_key), prop_val)

func get_shader_params_names_list() -> Dictionary[String, String]:
	return shader_params_names_list

func set_shader_params_names_list(new_val: Dictionary[String, String]) -> void:
	shader_params_names_list = new_val

func get_shader_param_code_name(display_name: String) -> String:
	return shader_params_names_list[display_name]

func _get_shader_global_params_snip() -> String: return ""
func _get_shader_fragment_snip() -> String: return ""
func _get_shader_vertex_snip() -> String: return ""
