class_name ShaderComponentRes extends ComponentRes

enum ShaderBlendMethod {
	SET,
	NORMAL,
	ADD,
	MULTIPLY,
	SCREEN,
	OVERLAY,
	SOFT_LIGHT,
	HARD_LIGHT,
	DIFFERENCE
}

enum ShaderParamIdentifier {
	PARAM_IDENTIFIER_CONST,
	PARAM_IDENTIFIER_UNIFORM,
	PARAM_IDENTIFIER_VARYING
}

enum ShaderParamType {
	PARAM_TYPE_BOOL, PARAM_TYPE_INT, PARAM_TYPE_UINT, PARAM_TYPE_FLOAT,
	PARAM_TYPE_VEC2, PARAM_TYPE_VEC3, PARAM_TYPE_VEC4,
	PARAM_TYPE_BVEC2, PARAM_TYPE_BVEC3, PARAM_TYPE_BVEC4,
	PARAM_TYPE_IVEC2, PARAM_TYPE_IVEC3, PARAM_TYPE_IVEC4,
	PARAM_TYPE_UVEC2, PARAM_TYPE_UVEC3, PARAM_TYPE_UVEC4,
	PARAM_TYPE_MAT2, PARAM_TYPE_MAT3, PARAM_TYPE_MAT4,
	PARAM_TYPE_HEIGHP, PARAM_TYPE_LOWP, PARAM_TYPE_MEDIUMP,
	PARAM_TYPE_SAMPLER_2D, PARAM_TYPE_SAMPLER_2D_ARRAY, PARAM_TYPE_SAMPLER_3D,
	PARAM_TYPE_CUBE, PARAM_TYPE_CUBE_ARRAY,
	PARAM_TYPE_EXTERNAL_OES,
	PARAM_TYPE_ISAMPLER_2D, PARAM_TYPE_ISAMPLER_2D_ARRAY, PARAM_TYPE_ISAMPLER_3D,
	PARAM_TYPE_USAMPLER_2D, PARAM_TYPE_USAMPLER_2D_ARRAY, PARAM_TYPE_USAMPLER_3D
}

const SHADER_PARAM_IDENTIFIER: Dictionary[int, StringName] = {
	ShaderParamIdentifier.PARAM_IDENTIFIER_CONST: "const",
	ShaderParamIdentifier.PARAM_IDENTIFIER_UNIFORM: "uniform",
	ShaderParamIdentifier.PARAM_IDENTIFIER_VARYING: "varying"
}

const SHADER_PARAM_TYPE_STRING_INDEXER: Dictionary[int, String] = {
	ShaderParamType.PARAM_TYPE_BOOL: "bool",
	ShaderParamType.PARAM_TYPE_INT: "int",
	ShaderParamType.PARAM_TYPE_UINT: "uint",
	ShaderParamType.PARAM_TYPE_FLOAT: "float",
	
	ShaderParamType.PARAM_TYPE_VEC2: "vec2",
	ShaderParamType.PARAM_TYPE_VEC3: "vec3",
	ShaderParamType.PARAM_TYPE_VEC4: "vec4",
	
	ShaderParamType.PARAM_TYPE_BVEC2: "bvec2",
	ShaderParamType.PARAM_TYPE_BVEC3: "bvec3",
	ShaderParamType.PARAM_TYPE_BVEC4: "bvec4",
	
	ShaderParamType.PARAM_TYPE_IVEC2: "ivec2",
	ShaderParamType.PARAM_TYPE_IVEC3: "ivec3",
	ShaderParamType.PARAM_TYPE_IVEC4: "ivec4",
	
	ShaderParamType.PARAM_TYPE_UVEC2: "uvec2",
	ShaderParamType.PARAM_TYPE_UVEC3: "uvec3",
	ShaderParamType.PARAM_TYPE_UVEC4: "uvec4",
	
	ShaderParamType.PARAM_TYPE_MAT2: "mat2",
	ShaderParamType.PARAM_TYPE_MAT3: "mat3",
	ShaderParamType.PARAM_TYPE_MAT4: "mat4",
	
	ShaderParamType.PARAM_TYPE_HEIGHP: "highp",
	ShaderParamType.PARAM_TYPE_LOWP: "lowp",
	ShaderParamType.PARAM_TYPE_MEDIUMP: "mediump",
	
	ShaderParamType.PARAM_TYPE_SAMPLER_2D: "sampler2D",
	ShaderParamType.PARAM_TYPE_SAMPLER_2D_ARRAY: "sampler2DArray",
	ShaderParamType.PARAM_TYPE_SAMPLER_3D: "sampler3D",
	
	ShaderParamType.PARAM_TYPE_CUBE: "samplerCube",
	ShaderParamType.PARAM_TYPE_CUBE_ARRAY: "samplerCubeArray",
	
	ShaderParamType.PARAM_TYPE_EXTERNAL_OES: "samplerExternalOES",
	
	ShaderParamType.PARAM_TYPE_ISAMPLER_2D: "isampler2D",
	ShaderParamType.PARAM_TYPE_ISAMPLER_2D_ARRAY: "isampler2DArray",
	ShaderParamType.PARAM_TYPE_ISAMPLER_3D: "isampler3D",
	
	ShaderParamType.PARAM_TYPE_USAMPLER_2D: "usampler2D",
	ShaderParamType.PARAM_TYPE_USAMPLER_2D_ARRAY: "usampler2DArray",
	ShaderParamType.PARAM_TYPE_USAMPLER_3D: "usampler3D"
}

@export var effect_blend_method: ShaderBlendMethod:
	set(val):
		effect_blend_method = val
		owner.compile_shader_snips()

@export var effect_weight: float = .5:
	set(val):
		effect_weight = val
		_set_shader_prop(&"effect_weight", effect_weight)

var shader_params_names_list: Dictionary[String, String]

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"Effect": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"effect_blend_method": export(options_args(effect_blend_method, ShaderBlendMethod)),
		&"effect_weight": export(float_args(effect_weight, .0, 1.)),
		&"_Effect": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	}

func _ready_shader() -> void:
	pass

func _set_shader_prop(prop_key: StringName, prop_val: Variant) -> void:
	owner.get_shader_material().set_shader_parameter(get_shader_param_code_name(prop_key), prop_val)

func _get_shader_init_params() -> Dictionary[StringName, Variant]:
	return {&"effect_weight": effect_weight}

func get_shader_params_names_list() -> Dictionary[String, String]:
	return shader_params_names_list

func set_shader_params_names_list(new_val: Dictionary[String, String]) -> void:
	shader_params_names_list = new_val

func get_shader_param_code_name(display_name: String) -> String:
	return shader_params_names_list[display_name]

func _get_shader_global_params_snip() -> String:
	return "
uniform float {effect_weight};
\n"
func _get_shader_fragment_snip() -> String: return ""
func _get_shader_vertex_snip() -> String: return ""


func _get_shader_blend_snip(a_arg: String, b_arg: String, blend_method: ShaderBlendMethod = -1) -> String:
	if blend_method == -1:
		blend_method = effect_blend_method
	
	var result: String
	var r_side: String
	
	match blend_method:
		0: r_side = "[b]"
		1: r_side = "mix([a], [b], {effect_weight})"
		2: r_side = "[a] + [b] * {effect_weight}"
		3: r_side = "[a] * [b]"
		4: r_side = "1.0 - (1.0 - [a]) * (1.0 - [b])"
		5: r_side = "
	mix(
		2.0 * [a] * [b],
		1.0 - 2.0 * (1.0 - [a]) * (1.0 - [b]),
		step(0.5, [a])
	)
"
		6: r_side = "[a] + ([b] - 0.5) * (1.0 - abs(2.0 * [a] - 1.0))"
		7: r_side = "
	mix(
		2.0 * [a] * [b],
		1.0 - 2.0 * (1.0 - [a]) * (1.0 - [b]),
		step(0.5, [b])
	)
"
		8: r_side = "abs([a] - [b])"
	
	r_side = r_side.format({
		"a" = a_arg,
		"b" = "{" + b_arg + "}"
	}, "[_]")
	
	result = "	%s = mix(%s, %s, {effect_weight});" % [a_arg, a_arg, r_side]
	
	return result
