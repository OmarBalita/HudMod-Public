class_name CompEmboss extends PassShaderComponentRes

@export var light_dir: Vector2 = Vector2.RIGHT
@export var intensity: float = .005
@export var highlight_color: Color = Color.WHITE
@export var shadow_color: Color = Color.BLACK

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"light_dir": export(vec2_args(light_dir)),
		&"intensity": export(float_args(intensity, .0, .02, .001, .0001)),
		&"highlight_color": export(color_args(highlight_color)),
		&"shadow_color": export(color_args(shadow_color))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Emboss.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"light_dir", light_dir)
	set_shader_prop(&"intensity", intensity)
	set_shader_prop(&"highlight_color", highlight_color)
	set_shader_prop(&"shadow_color", shadow_color)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform vec2 {light_dir};
#uniform float {intensity}: hint_range(.0, .02);
#uniform vec4 {highlight_color}: source_color;
#uniform vec4 {shadow_color}: source_color;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {dir} = normalize({light_dir}) * {intensity};
	#
	#float {sample_plus} = get_luminance(texture(TEXTURE, UV + {dir}).rgb);
	#float {sample_minus} = get_luminance(texture(TEXTURE, UV - {dir}).rgb);
	#
	#float {diff} = {sample_plus} - {sample_minus};
	#
	#vec4 {base} = vec4(color, alpha);
	#vec4 {final} = {base};
	#
	#if ({diff} > .0) {
		#{final} = mix({final}, {highlight_color}, clamp({diff} * 5., .0, 1.));
	#} else {
		#{final} = mix({final}, {shadow_color}, clamp(abs({diff}) * 5., .0, 1.));
	#}
	#
	#color = {final}.rgb;
	#alpha = {final}.a;
#"
