class_name CompDistortionBulge extends PassShaderComponentRes

@export var center: Vector2
@export var force: float = .5
@export var radius: float = .5

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"center": export(vec2_args(center)),
		&"force": export(float_args(force, -1., 1., .001)),
		&"radius": export(float_args(radius, .0, 1., .001))
	}

func _process(frame: int) -> void:
	set_shader_prop(&"center", center)
	set_shader_prop(&"force", force)
	set_shader_prop(&"radius", radius)

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/DistBulge.gdshader")

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform vec2 {center};
#uniform float {force}: hint_range(-1., 1.);
#uniform float {radius}: hint_range(.0, 1.);
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {_center} = {center} + vec2(.5);
	#vec2 {uv} = UV - {_center};
	#float {dist} = length({uv});
	#
	#if ({dist} < {radius}) {
		#float {percent} = {dist} / {radius};
		#
		#if ({force} >= .0) {
			#{uv} *= mix(1., {percent}, {force} * (1. - {percent}));
		#} else {
			#{uv} /= mix(1., {percent}, -{force} * (1. - {percent}));
		#}
	#}
	#
	#vec4 {result} = texture(TEXTURE, {uv} + {_center});
	#color = {result}.rgb;
	#alpha = {result}.a;
#"

