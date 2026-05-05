#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Copyright © 2026 Omar Mohammed Balita.                                 ##
## ----------------------------------------------------------------------- ##
## GPLv3                                                                   ##
#############################################################################
class_name CompWhiteBalance extends SnippetShaderComponentRes

@export var temp: float = .0
@export var tint: float = .0
@export var use_curves: bool
@export var red_curve:= CurveProfile.preset_linear()
@export var green_curve:= CurveProfile.preset_linear()
@export var blue_curve:= CurveProfile.preset_linear()
@export var rgb_curve:= CurveProfile.preset_linear()

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"temp": export(float_args(temp, -1., 1., .001)),
		&"tint": export(float_args(tint, -1., 1., .001)),
		&"use_curves": export(bool_args(use_curves)),
		&"Curves": export_method(ExportMethodType.METHOD_ENTER_CATEGORY, [], [get.bind(&"use_curves"), [true]]),
		&"red_curve": export([red_curve]),
		&"green_curve": export([green_curve]),
		&"blue_curve": export([blue_curve]),
		&"rgb_curve": export([rgb_curve]),
		&"_Curves": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
	}

func _process(frame: int) -> void:
	super(frame)
	set_shader_prop(&"temp", temp)
	set_shader_prop(&"tint", tint)
	set_shader_prop(&"use_curves", use_curves)

func _ready_shader() -> void:
	_connect_curve_profiles()

func _get_shader_global_params_snip() -> String:
	return super() + "
uniform float {temp}: hint_range(-1., 1.) = .0;
uniform float {tint}: hint_range(-1., 1.) = .0;

uniform bool {use_curves} = false;

uniform sampler2D {red_curve}: hint_default_white;
uniform sampler2D {green_curve}: hint_default_white;
uniform sampler2D {blue_curve}: hint_default_white;
uniform sampler2D {rgb_curve}: hint_default_white;
"

func _get_shader_fragment_snip() -> String:
	return super() + "
	// White Balance
	vec3 {warm_cool} = vec3(1. + {temp}, 1., 1. - {temp});
	vec3 {green_magenta} = vec3(1. + {tint} * .5, 1. - {tint}, 1. + {tint} * .5);
	
	color *= {warm_cool};
	color *= {green_magenta};
	
	// Curves Application
	if ({use_curves}) {
		color.r = texture({rgb_curve}, vec2(color.r, .5)).r;
		color.g = texture({rgb_curve}, vec2(color.g, .5)).g;
		color.b = texture({rgb_curve}, vec2(color.b, .5)).b;
		
		color.r = texture({red_curve}, vec2(color.r, .5)).r;
		color.g = texture({green_curve}, vec2(color.g, .5)).g;
		color.b = texture({blue_curve}, vec2(color.b, .5)).b;
	}
"

func _connect_curve_profiles() -> void:
	_connect_curve_profile(&"red_curve")
	_connect_curve_profile(&"green_curve")
	_connect_curve_profile(&"blue_curve")
	_connect_curve_profile(&"rgb_curve")

func _connect_curve_profile(curve_key: StringName) -> void:
	update_curve_texture(curve_key)
	get_prop(curve_key).res_changed.connect(update_curve_texture.bind(curve_key))

func update_curve_texture(curve_key: StringName) -> void:
	set_shader_prop(curve_key, get_prop(curve_key).create_image_texture())
	emit_res_changed()
