class_name CompDistortionTwirl extends PassShaderComponentRes

@export var center: Vector2
@export var rotation: float = 3.
@export var radius: float = .5

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"center": export(vec2_args(center)),
		&"rotation": export(float_args(rotation, -10., 10., .001)),
		&"radius": export(float_args(radius, .0, 1., .001))
	}

func _process(frame: int) -> void:
	set_shader_prop(&"center", center)
	set_shader_prop(&"rotation", rotation)
	set_shader_prop(&"radius", radius)

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/DistTwirl.gdshader")

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform vec2 {center};
#uniform float {rotation}: hint_range(-10., 10.);
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
		#float {percent} = ({radius} - {dist}) / {radius};
		#float {angle} = {percent} * {percent} * {rotation};
		#
		#float {s} = sin({angle});
		#float {c} = cos({angle});
		#mat2 {rotation_matrix} = mat2(vec2({c}, -{s}), vec2({s}, {c}));
		#
		#{uv} = {rotation_matrix} * {uv};
	#}
	#{uv} += {_center};
	#
	#vec4 {result} = texture(TEXTURE, {uv});
	#color = {result}.rgb;
	#alpha = {result}.a;
#"
