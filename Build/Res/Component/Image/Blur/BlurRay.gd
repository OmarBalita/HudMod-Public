class_name CompBlurRay extends PassShaderComponentRes

@export var center: Vector2 = Vector2.ZERO
@export var power: float = .2
@export var quality: int = 12
@export var edge_scale: float = .8

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"center": export(vec2_args(center)),
		&"power": export(float_args(power, .0, 1., .001)),
		&"quality": export(int_args(quality, 1, 64)),
		&"edge_scale": export(float_args(edge_scale, .0, 1.))
	}

func _process(frame: int) -> void:
	set_shader_prop(&"center", center)
	set_shader_prop(&"power", power)
	set_shader_prop(&"quality", quality)
	set_shader_prop(&"edge_scale", edge_scale)

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/BlurRay.gdshader")

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform vec2 {pivot} = vec2(.0);
#uniform float {power}: hint_range(.0, 1.) = .2;
#uniform int {quality}: hint_range(1, 64) = 12;
#uniform float {edge_scale}: hint_range(.0, 1.) = .8;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {direction} = UV - ({pivot} + vec2(.5));
	#vec3 {c} = vec3(.0);
	#float {f} = 1. / float({quality});
	#
	#for (int i = 0; i < {quality}; i++) {
		#{c} += texture(TEXTURE, UV - {power} / float({quality}) * {direction} * float(i)).rgb * {f};
	#}
	#
	#float {mix_val} = smoothstep(.0, 1. - {edge_scale}, distance(({pivot} + vec2(.5)), UV));
	#vec3 {result} = mix(texture(TEXTURE, UV).rgb, {c}, {mix_val});
	#color.rgb = {result};
#"
