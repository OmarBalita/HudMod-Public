class_name CompKawahara extends PassShaderComponentRes

@export_range(0, 10) var radius: int = 3

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {&"radius": export(int_args(radius, 0, 10))}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Kawahara.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"radius", radius)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform int {radius} : hint_range(0, 10);
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {tex_size} = vec2(textureSize(TEXTURE, 0));
	#vec2 {uv} = UV;
	#
	#vec3 {mean}[4];
	#vec3 {std_dev}[4];
	#for (int i = 0; i < 4; i++) {
		#{mean}[i] = vec3(.0);
		#{std_dev}[i] = vec3(.0);
	#}
	#
	#int {n} = ({radius} + 1) * ({radius} + 1);
	#float {f_n} = float({n});
	#
	#int {bounds}[16] = int[](
		#-{radius}, 0, -{radius}, 0,
		#0, {radius}, -{radius}, 0,
		#-{radius}, 0, 0, {radius},
		#0, {radius}, 0, {radius}
	#);
	#
	#for (int i = 0; i < 4; i++) {
		#for (int x = {bounds}[i*4]; x <= {bounds}[i*4+1]; x++) {
			#for (int y = {bounds}[i*4+2]; y <= {bounds}[i*4+3]; y++) {
				#vec3 {c} = texture(TEXTURE, {uv} + vec2(float(x), float(y)) / {tex_size}).rgb;
				#{mean}[i] += {c};
				#{std_dev}[i] += {c} * {c};
			#}
		#}
	#}
	#
	#float {min_sigma2} = 1e+2;
	#vec3 {final_color} = vec3(.0);
	#
	#for (int i = 0; i < 4; i++) {
		#{mean}[i] /= {f_n};
		#{std_dev}[i] = abs({std_dev}[i] / {f_n} - {mean}[i] * {mean}[i]);
		#float {sigma2} = {std_dev}[i].r + {std_dev}[i].g + {std_dev}[i].b;
		#
		#if ({sigma2} < {min_sigma2}) {
			#{min_sigma2} = {sigma2};
			#{final_color} = {mean}[i];
		#}
	#}
	#
	#color = {final_color};
#"
