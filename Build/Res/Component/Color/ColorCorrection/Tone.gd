class_name CompTone extends SnippetShaderComponentRes

@export var exposure: float = .0
@export var contrast: float = 1.
@export var pivot: float = .5
@export var highlights: float = .0
@export var shadows: float = .0
@export var whites: float = .0
@export var blacks: float = .0

@export var advanced_settings: bool
@export var whites_range: float = .2
@export var blacks_range: float = .2


func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var adv_ui_cond: Array = [get.bind(&"advanced_settings"), [true]]
	return {
		&"exposure": export(float_args(exposure, -5., 5., .001)),
		&"contrast": export(float_args(contrast, .0, 3., .001)),
		&"pivot": export(float_args(pivot, .0, 1.)),
		&"highlights": export(float_args(highlights, -1., 1., .001)),
		&"shadows": export(float_args(shadows, -1., 1., .001)),
		&"whites": export(float_args(whites, -1., 1., .001)),
		&"blacks": export(float_args(blacks, -1., 1., .001)),
		&"advanced_settings": export(bool_args(advanced_settings)),
		&"whites_range": export(float_args(whites_range, .0, 1., .001), adv_ui_cond),
		&"blacks_range": export(float_args(blacks_range, .0, 1., .001), adv_ui_cond)
	}

func _process(frame: int) -> void:
	set_shader_props({
		&"exposure": exposure,
		&"contrast": contrast,
		&"pivot": pivot,
		&"highlights": highlights,
		&"shadows": shadows,
		&"whites": whites,
		&"blacks": blacks,
		&"whites_range": whites_range,
		&"blacks_range": blacks_range
	})

func _get_shader_global_params_snip() -> String:
	return "
uniform float {exposure}: hint_range(-5., 5.) = .0;
uniform float {contrast}: hint_range(.0, 3.) = 1.;
uniform float {pivot}: hint_range(.0, 1.) = .5;
uniform float {highlights}: hint_range(-1., 1.) = .0;
uniform float {shadows}: hint_range(-1., 1.) = .0;
uniform float {whites}: hint_range(-1., 1.) = .0;
uniform float {blacks}: hint_range(-1., 1.) = .0;

uniform float {whites_range}: hint_range(.0, 1.);
uniform float {blacks_range}: hint_range(.0, 1.);
"

func _get_shader_fragment_snip() -> String:
	return "
	// Exposure
	color *= pow(2., {exposure});
	
	// Contrast
	color = (color - {pivot}) * {contrast} + {pivot};
	
	float {luma} = dot(color, vec3(.2126, .7152, .0722));
	float {middle_mask} = smoothstep(.5, 1., {luma});
	
	// Highlights
	color += {middle_mask} * {highlights};
	
	// Shadows
	float {shadow_mask} = 1.0 - {middle_mask};
	color += {shadow_mask} * {shadows};
	
	// Whites
	float {white_mask} = smoothstep(1.0 - {whites_range}, 1.0, {luma});
	color += {white_mask} * {whites};
	
	// Blacks
	float {black_mask} = 1.0 - smoothstep(0.0, {blacks_range}, {luma});
	color += {black_mask} * {blacks};
"
