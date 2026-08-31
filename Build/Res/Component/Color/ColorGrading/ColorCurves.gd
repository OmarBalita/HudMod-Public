class_name CompColorCurves extends SnippetShaderComponentRes

@export var hue_vs_hue: CurveProfile = CurveProfile.preset_constant_line()
@export var hue_vs_sat: CurveProfile = CurveProfile.preset_constant_line()
@export var hue_vs_lum: CurveProfile = CurveProfile.preset_constant_line()
@export var lum_vs_sat: CurveProfile = CurveProfile.preset_constant_line()
@export var sat_vs_sat: CurveProfile = CurveProfile.preset_constant_line()
@export var sat_vs_lum: CurveProfile = CurveProfile.preset_constant_line()

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"Curves": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"hue_vs_hue": export([hue_vs_hue]),
		&"hue_vs_sat": export([hue_vs_sat]),
		&"hue_vs_lum": export([hue_vs_lum]),
		&"lum_vs_sat": export([lum_vs_sat]),
		&"sat_vs_sat": export([sat_vs_sat]),
		&"sat_vs_lum": export([sat_vs_lum]),
		&"_Curves": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	}

func has_color_correction_editor() -> bool: return true
func _get_color_correction_exported_props() -> Dictionary[StringName, Dictionary]:
	var color_curve_controller:= ColorCurvesController.new()
	color_curve_controller.color_curves = self
	return {
		&"color_curves_controller": export_method(ExportMethodType.METHOD_CUSTOM_EXPORT, [color_curve_controller])
	}

func _ready_shader() -> void:
	_connect_curve_profiles()

func _get_shader_global_params_snip() -> String:
	return "
uniform sampler2D {hue_vs_hue}: hint_default_white; // 1. Hue vs Hue
uniform sampler2D {hue_vs_sat}: hint_default_white; // 2. Hue vs Sat
uniform sampler2D {hue_vs_lum}: hint_default_white; // 3. Hue vs Lum
uniform sampler2D {lum_vs_sat}: hint_default_white; // 4. Lum vs Sat
uniform sampler2D {sat_vs_sat}: hint_default_white; // 5. Sat vs Sat
uniform sampler2D {sat_vs_lum}: hint_default_white; // 6. Sat vs Lum
"

func _get_shader_fragment_snip() -> String:
	return "
	vec3 {hsv} = rgb2hsv(color);
	float {lum} = get_luminance(color);
	
	float {h_h_shift} = texture({hue_vs_hue}, vec2({hsv}.x, .5)).r - .5;
	{hsv}.x = fract({hsv}.x + {h_h_shift});
	
	float {h_s_scale} = texture({hue_vs_sat}, vec2({hsv}.x, .5)).r * 2.;
	{hsv}.y *= {h_s_scale};
	
	float {h_l_scale} = texture({hue_vs_lum}, vec2({hsv}.x, .5)).r * 2.;
	{hsv}.z *= {h_l_scale};
	
	{lum} = get_luminance(hsv2rgb({hsv}));
	float {l_s_scale} = texture({lum_vs_sat}, vec2({lum}, .5)).r * 2.;
	{hsv}.y *= {l_s_scale};
	
	float {s_s_scale} = texture({sat_vs_sat}, vec2(clamp({hsv}.y, .0, 1.), .5)).r * 2.;
	{hsv}.y *= {s_s_scale};
	
	float {s_l_scale} = texture({sat_vs_lum}, vec2(clamp({hsv}.y, .0, 1.), .5)).r * 2.;
	{hsv}.z *= {s_l_scale};
	
	{hsv}.y = clamp({hsv}.y, .0, 1.);
	{hsv}.z = clamp({hsv}.z, .0, 1.);
	
	color = hsv2rgb({hsv});
"

func _connect_curve_profiles() -> void:
	_connect_curve_profile(&"hue_vs_hue")
	_connect_curve_profile(&"hue_vs_sat")
	_connect_curve_profile(&"hue_vs_lum")
	_connect_curve_profile(&"lum_vs_sat")
	_connect_curve_profile(&"sat_vs_sat")
	_connect_curve_profile(&"sat_vs_lum")

func _connect_curve_profile(curve_key: StringName) -> void:
	update_curve_texture(curve_key)
	get_prop(curve_key).res_changed.connect(update_curve_texture.bind(curve_key))

func update_curve_texture(curve_key: StringName) -> void:
	set_shader_prop(curve_key, get_prop(curve_key).create_image_texture())
	emit_res_changed()


