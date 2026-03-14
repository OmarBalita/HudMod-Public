class_name CompBars extends SnippetShaderComponentRes

@export var aspect_ratio: float = .2
@export var smoothness: float
@export var curve_strength: float
@export var rotation_degrees: float
@export var bars_color: Color

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"aspect_ratio": export(float_args(aspect_ratio, -1., 1.)),
		&"smoothness": export(float_args(smoothness, .0, 1.)),
		&"curve_strength": export(float_args(curve_strength, -5., 5.)),
		&"rotation_degrees": export(float_args(rotation_degrees)),
		&"bars_color": export(color_args(bars_color))
	}

func _process(frame: int) -> void:
	set_shader_props({
		&"aspect_ratio": aspect_ratio,
		&"smoothness": smoothness,
		&"curve_strength": curve_strength,
		&"rotation_degrees": rotation_degrees,
		&"bars_color": bars_color,
	})

func _get_shader_global_params_snip() -> String:
	return "
uniform float {aspect_ratio}: hint_range(-1., 1.); 
uniform float {smoothness}: hint_range(.0, 1.);
uniform float {curve_strength}: hint_range(-5., 5.);
uniform float {rotation_degrees};
uniform vec4 {bars_color}: source_color;
"

func _get_shader_fragment_snip() -> String:
	return "
	float {angle} = radians({rotation_degrees});
	vec2 {uv} = UV - .5;
	float {cos_a} = cos({angle});
	float {sin_a} = sin({angle});
	mat2 {rotation_matrix} = mat2(vec2({cos_a}, -{sin_a}), vec2({sin_a}, {cos_a}));
	{uv} = {rotation_matrix} * {uv} + .5;
	
	float {x_dist} = abs({uv}.x - .5);
	float {offset} = pow({x_dist}, 2.) * {curve_strength};
	float {low} = ({aspect_ratio} * .5) + {offset};
	float {high} = 1. - {low};
	float {mask} = smoothstep({low}, {low} + {smoothness}, {uv}.y) * (1. - smoothstep({high} - {smoothness}, {high}, {uv}.y));
	color = mix({bars_color}.rgb, color, {mask});
"

