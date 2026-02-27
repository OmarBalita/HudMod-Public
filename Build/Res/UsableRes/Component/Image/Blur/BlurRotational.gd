class_name CompBlurRotational extends PassShaderComponentRes

@export var auto: bool = false
@export var center: Vector2 = Vector2.ZERO
@export var blur_amount: float = .05
@export var quality: int = 8
@export var clip_border: bool = false
@export var transparancy: bool = true

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"auto": export(bool_args(auto)),
		&"center": export(vec2_args(center)),
		&"blur_amount": export(float_args(blur_amount, -PI, PI, .001)),
		&"quality": export(int_args(quality, 1, 128)),
		&"clip_border": export(bool_args(clip_border)),
		&"transparancy": export(bool_args(transparancy))
	}

func _postprocess(frame: int) -> void:
	var _blur_amount: float
	
	if auto:
		var dict: Dictionary[StringName, Array] = owner.shared_data_get_stacked_at(frame - 1)
		var rot_key: StringName = &"rotation_degrees"
		if dict.has(rot_key):
			var delta: float = owner.get_stacked_values_key_result(rot_key) - owner.get_custom_stacked_values_key_result(dict, rot_key)
			_blur_amount = delta * blur_amount
	else:
		_blur_amount = blur_amount
	
	set_shader_props({
		&"center": center,
		&"blur_amount": _blur_amount,
		&"quality": quality,
		&"clip_border": clip_border,
		&"transparancy": transparancy,
	})

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/BlurRotational.gdshader")

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform vec2 {center};
#uniform float {blur_amount}: hint_range(-3.141592, 3.141592);
#uniform int {quality}: hint_range(1, 128);
#uniform bool {clip_border};
#uniform bool {transparancy};
#
#const float {ROOT_TWO} = 1.41421356237;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#float {in_square} = inside_unit_square(UV);
	#float {num_samples} = {in_square};
	#float {step_size} = {blur_amount} / (float({quality}));
	#
	#vec4 {color} = texture(TEXTURE, UV) * {in_square};
	#
	#vec2 {uv};
	#
	#for (int i = 1; i <= {quality}; i++) {
		#{uv} = rotate(UV, {center} + .5, float(i) * {step_size});
		#{in_square} = inside_unit_square({uv});
		#{num_samples} += {in_square};
		#{color} += texture(TEXTURE, {uv}) * {in_square};
		#
		#{uv} = rotate(UV, {center} + .5, -float(i) * {step_size});
		#{in_square} = inside_unit_square({uv});
		#{num_samples} += {in_square};
		#{color} += texture(TEXTURE, {uv}) * {in_square};
	#}
	#
	#{color}.rgb = {color}.rgb / {num_samples};
	#if ({transparancy}) {
		#{color}.a /= float({quality}) * 2. + 1.;
	#}
	#
	#color.rgb = {color}.rgb;
	#alpha = {color}.a;
#"
#
#func _get_shader_vertex_snip() -> String:
	#return "
	#if ({clip_border} == false) {
		#vec2 {vertex} = TEXTURE_PIXEL_SIZE * vertex;
		#{vertex} = {vertex} * (2. * length({center}) + {ROOT_TWO}) + {center};
		#vertex = {vertex} / TEXTURE_PIXEL_SIZE;
		#vertex += {center};
		#uv = (uv - .5) * (2. * length({center}) + {ROOT_TWO}) + {center} + .5;
	#}
#"
