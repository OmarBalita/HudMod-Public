@abstract class_name ShaderComponentRes extends ComponentRes

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

func has_method_type() -> bool:
	return false

func _ready_shader() -> void:
	pass

func set_shader_prop(prop_key: StringName, prop_val: Variant) -> void:
	pass

func set_shader_props(props: Dictionary[StringName, Variant]) -> void:
	for prop_key: StringName in props:
		set_shader_prop(prop_key, props[prop_key])
