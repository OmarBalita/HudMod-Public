class_name CompWhiteBalance extends ShaderComponentRes

@export var temp: float = .0:
	set(val):
		temp = val
		_set_shader_prop(&"temp", temp)

@export var tint: float = .0:
	set(val):
		tint = val
		_set_shader_prop(&"tint", tint)

@export var use_curves: bool:
	set(val):
		use_curves = val
		_set_shader_prop(&"use_curves", use_curves)

@export var red_curve:= CurveProfile.preset_linear():
	set(val):
		red_curve = val
		_connect_curve_profile(&"red_curve")

@export var green_curve:= CurveProfile.preset_linear():
	set(val):
		green_curve = val
		_connect_curve_profile(&"green_curve")

@export var blue_curve:= CurveProfile.preset_linear():
	set(val):
		blue_curve = val
		_connect_curve_profile(&"blue_curve")

@export var rgb_curve:= CurveProfile.preset_linear():
	set(val):
		rgb_curve = val
		_connect_curve_profile(&"rgb_curve")

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	var curve_ui_cond: Array = [get.bind(&"use_curves"), [true]]
	return super().merged({
		&"temp": export(float_args(temp, -1., 1., .01)),
		&"tint": export(float_args(tint, -1., 1., .01)),
		&"Curves": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"use_curves": export(bool_args(use_curves)),
		&"red_curve": export([red_curve], curve_ui_cond),
		&"green_curve": export([green_curve], curve_ui_cond),
		&"blue_curve": export([blue_curve], curve_ui_cond),
		&"rgb_curve": export([rgb_curve], curve_ui_cond),
		&"_Curves": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	})

func _get_shader_init_params() -> Dictionary[StringName, Variant]:
	return super().merged({
		&"temp": temp,
		&"tint": tint,
		&"use_curves": use_curves
	})

func _ready_shader() -> void:
	_connect_curve_profiles()

func _get_shader_global_params_snip() -> String:
	return super() + "
uniform float {temp} : hint_range(-1.0, 1.0) = 0.0;
uniform float {tint} : hint_range(-1.0, 1.0) = 0.0;

uniform bool {use_curves} = false;

uniform sampler2D {red_curve} : hint_default_white;
uniform sampler2D {green_curve} : hint_default_white;
uniform sampler2D {blue_curve} : hint_default_white;
uniform sampler2D {rgb_curve} : hint_default_white;
"

func _get_shader_fragment_snip() -> String:
	return "
	vec4 {tex_color} = COLOR;
	vec3 {color} = {tex_color}.rgb;
	
	vec3 {warm_cool} = vec3(1.0 + {temp}, 1.0, 1.0 - {temp});
	
	vec3 {green_magenta} = vec3(1.0 + {tint} * 0.5, 1.0 - {tint}, 1.0 + {tint} * 0.5);
	
	{color} *= {warm_cool};
	{color} *= {green_magenta};
	
	float {old_luma} = dot({tex_color}.rgb, vec3(0.2126, 0.7152, 0.0722));
	float {new_luma} = dot({color}, vec3(0.2126, 0.7152, 0.0722));
	{color} *= ({old_luma} / max({new_luma}, 0.001));
	
	if ({use_curves}) {
		{color}.r = texture({rgb_curve}, vec2({color}.r, 0.5)).r;
		{color}.g = texture({rgb_curve}, vec2({color}.g, 0.5)).g;
		{color}.b = texture({rgb_curve}, vec2({color}.b, 0.5)).b;
		
		{color}.r = texture({red_curve}, vec2({color}.r, 0.5)).r;
		{color}.g = texture({green_curve}, vec2({color}.g, 0.5)).g;
		{color}.b = texture({blue_curve}, vec2({color}.b, 0.5)).b;
	}
	
	vec4 {result} = vec4(clamp({color}, 0.0, 1.0), {tex_color}.a);
	
" + _get_shader_blend_snip("COLOR", "result", effect_blend_method)

func _connect_curve_profiles() -> void:
	_connect_curve_profile(&"red_curve")
	_connect_curve_profile(&"green_curve")
	_connect_curve_profile(&"blue_curve")
	_connect_curve_profile(&"rgb_curve")

func _connect_curve_profile(curve_key: StringName) -> void:
	update_curve_texture(curve_key)
	get_prop(curve_key).res_changed.connect(update_curve_texture.bind(curve_key))

func update_curve_texture(curve_key: StringName) -> void:
	_set_shader_prop(curve_key, get_prop(curve_key).create_image_texture())
	emit_res_changed()
