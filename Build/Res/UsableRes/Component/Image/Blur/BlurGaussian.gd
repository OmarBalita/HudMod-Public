class_name CompBlurGaussian extends PassShaderComponentRes

@export var blur_amount: float = .02
@export var quality: int = 4
@export var transparancy: bool = true

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"blur_amount": export(float_args(blur_amount, .0, 1., .001)),
		&"quality": export(int_args(quality, 1, 32)),
		&"transparancy": export(bool_args(transparancy))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/BlurGaussian.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"blur_amount", blur_amount)
	set_shader_prop(&"quality", quality)
	set_shader_prop(&"transparancy", transparancy)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {blur_amount}: hint_range(.0, 1.) = .02;
#uniform int {quality}: hint_range(1, 12) = 3;
#uniform bool {transparancy} = true;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec4 {color} = vec4(.0);
	#float {total_samples} = .0;
	#float {count} = float(({quality} * 2 + 1) * ({quality} * 2 + 1));
	#
	#float {ratio} = float(TEXTURE_PIXEL_SIZE.x) / float(TEXTURE_PIXEL_SIZE.y);
	#vec2 {step_size} = vec2({blur_amount} * {ratio}, {blur_amount}) / float({quality});
	#
	#for(int x = -{quality}; x <= {quality}; x++) {
		#for(int y = -{quality}; y <= {quality}; y++) {
			#vec2 {offset} = vec2(float(x), float(y)) * {step_size};
			#vec2 {target_uv} = UV + {offset};
			#
			#float {in_square} = inside_unit_square({target_uv});
			#
			#{color} += texture(TEXTURE, {target_uv}) * {in_square};
			#{total_samples} += {in_square};
		#}
	#}
	#
	#if ({total_samples} > .0) {
		#{color}.rgb /= {total_samples};
		#
		#if ({transparancy}) {
			#{color}.a /= {count};
		#} else {
			#{color}.a = ({color}.a / {total_samples});
		#}
	#}
	#
	#if ({transparancy}) {
		#{color}.a *= {color}.a;
	#}
	#
	#color.rgb = {color}.rgb;
	#alpha = {color}.a;
#"
#
#func _get_shader_vertex_snip() -> String:
	#return "
	#if ({transparancy}) {
		#float {blur_size} = ({blur_amount} + 1.);
		#vertex *= {blur_size};
		#uv = (uv - .5) * {blur_size} + .5;
	#}
#"
