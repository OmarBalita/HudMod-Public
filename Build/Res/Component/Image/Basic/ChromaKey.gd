class_name ChromaKey extends SnippetShaderComponentRes

@export var key_color: Color = Color.GREEN
@export var similarity: float = .4
@export var smoothness: float = .08
@export var spill_removal: float = .5

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"key_color": export(color_args(key_color)),
		&"similarity": export(float_args(similarity, .0, 1.)),
		&"smoothness": export(float_args(smoothness, .0, 1.)),
		&"spill_removal": export(float_args(spill_removal, .0, 1.)),
	}

func _process(frame: int) -> void:
	set_shader_prop(&"key_color", key_color)
	set_shader_prop(&"similarity", similarity)
	set_shader_prop(&"smoothness", smoothness)
	set_shader_prop(&"spill_removal", spill_removal)

func _get_shader_global_params_snip() -> String:
	return "
uniform vec4 {key_color}: source_color = vec4(.0, 1., .0, 1.);
uniform float {similarity}: hint_range(.0, 1.) = .4;
uniform float {smoothness}: hint_range(.0, 1.) = .08;
uniform float {spill_removal}: hint_range(.0, 1.) = .5;
"

func _get_shader_fragment_snip() -> String:
	return "
	float {chroma_dist} = distance(color, {key_color}.rgb);
	
	float {base_mask} = {chroma_dist} - {similarity};
	float {full_mask} = clamp({base_mask} / {smoothness}, .0, 1.);
	
	float {desat} = get_luminance(color);
	
	vec3 {spill_free_rgb} = mix(vec3({desat}), color, pow({full_mask}, {spill_removal}));
	
	vec4 {result} = vec4({spill_free_rgb}, alpha * {full_mask});
	color = {result}.rgb;
	alpha = {result}.a;
"




