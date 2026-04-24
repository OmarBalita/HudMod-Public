class_name CompHSLPerColor extends SnippetShaderComponentRes

@export_range(.1, 1., .001) var smoothness: float = .3

@export_group("Saturation", "sat")
@export var sat_red: float = 1.
@export var sat_orange: float = 1.
@export var sat_yellow: float = 1.
@export var sat_green: float = 1.
@export var sat_aqua: float = 1.
@export var sat_blue: float = 1.
@export var sat_purple: float = 1.
@export var sat_magenta: float = 1.

@export_group("Luminance", "lum")
@export var lum_red: float = 1.
@export var lum_orange: float = 1.
@export var lum_yellow: float = 1.
@export var lum_green: float = 1.
@export var lum_aqua: float = 1.
@export var lum_blue: float = 1.
@export var lum_purple: float = 1.
@export var lum_magenta: float = 1.

@export_group("Hue", "hue")
@export var hue_red: float = .0
@export var hue_orange: float = .0
@export var hue_yellow: float = .0
@export var hue_green: float = .0
@export var hue_aqua: float = .0
@export var hue_blue: float = .0
@export var hue_purple: float = .0
@export var hue_magenta: float = .0

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"smoothness": export(float_args(smoothness, .1, 1., .001)),
		
		&"Saturation": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"sat_red": export(float_args(sat_red, .0, 5., .001)),
		&"sat_orange": export(float_args(sat_orange, .0, 5., .001)),
		&"sat_yellow": export(float_args(sat_yellow, .0, 5., .001)),
		&"sat_green": export(float_args(sat_green, .0, 5., .001)),
		&"sat_aqua": export(float_args(sat_aqua, .0, 5., .001)),
		&"sat_blue": export(float_args(sat_blue, .0, 5., .001)),
		&"sat_purple": export(float_args(sat_purple, .0, 5., .001)),
		&"sat_magenta": export(float_args(sat_magenta, .0, 5., .001)),
		&"_Saturation": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Luminance": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"lum_red": export(float_args(lum_red, .0, 5., .001)),
		&"lum_orange": export(float_args(lum_orange, .0, 5., .001)),
		&"lum_yellow": export(float_args(lum_yellow, .0, 5., .001)),
		&"lum_green": export(float_args(lum_green, .0, 5., .001)),
		&"lum_aqua": export(float_args(lum_aqua, .0, 5., .001)),
		&"lum_blue": export(float_args(lum_blue, .0, 5., .001)),
		&"lum_purple": export(float_args(lum_purple, .0, 5., .001)),
		&"lum_magenta": export(float_args(lum_magenta, .0, 5., .001)),
		&"_Luminance": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Hue": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"hue_red": export(float_args(hue_red, -5., 5., .001)),
		&"hue_orange": export(float_args(hue_orange, -5., 5., .001)),
		&"hue_yellow": export(float_args(hue_yellow, -5., 5., .001)),
		&"hue_green": export(float_args(hue_green, -5., 5., .001)),
		&"hue_aqua": export(float_args(hue_aqua, -5., 5., .001)),
		&"hue_blue": export(float_args(hue_blue, -5., 5., .001)),
		&"hue_purple": export(float_args(hue_purple, -5., 5., .001)),
		&"hue_magenta": export(float_args(hue_magenta, -5., 5., .001)),
		&"_Hue": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	}

func _process(frame: int) -> void:
	set_shader_props({
		&"smoothness": smoothness,
		
		&"sat_red": sat_red,
		&"sat_orange": sat_orange,
		&"sat_yellow": sat_yellow,
		&"sat_green": sat_green,
		&"sat_aqua": sat_aqua,
		&"sat_blue": sat_blue,
		&"sat_purple": sat_purple,
		&"sat_magenta": sat_magenta,
		
		&"lum_red": lum_red,
		&"lum_orange": lum_orange,
		&"lum_yellow": lum_yellow,
		&"lum_green": lum_green,
		&"lum_aqua": lum_aqua,
		&"lum_blue": lum_blue,
		&"lum_purple": lum_purple,
		&"lum_magenta": lum_magenta,
		
		&"hue_red": hue_red,
		&"hue_orange": hue_orange,
		&"hue_yellow": hue_yellow,
		&"hue_green": hue_green,
		&"hue_aqua": hue_aqua,
		&"hue_blue": hue_blue,
		&"hue_purple": hue_purple,
		&"hue_magenta": hue_magenta,
	})


func _get_shader_global_params_snip() -> String:
	return "
uniform float {sat_red}: hint_range(.0, 5.) = 1.;
uniform float {sat_orange}: hint_range(.0, 5.) = 1.;
uniform float {sat_yellow}: hint_range(.0, 5.) = 1.;
uniform float {sat_green}: hint_range(.0, 5.) = 1.;
uniform float {sat_aqua}: hint_range(.0, 5.) = 1.;
uniform float {sat_blue}: hint_range(.0, 5.) = 1.;
uniform float {sat_purple}: hint_range(.0, 5.) = 1.;
uniform float {sat_magenta}: hint_range(.0, 5.) = 1.;

uniform float {lum_red}: hint_range(.0, 5.) = 1.;
uniform float {lum_orange}: hint_range(.0, 5.) = 1.;
uniform float {lum_yellow}: hint_range(.0, 5.) = 1.;
uniform float {lum_green}: hint_range(.0, 5.) = 1.;
uniform float {lum_aqua}: hint_range(.0, 5.) = 1.;
uniform float {lum_blue}: hint_range(.0, 5.) = 1.;
uniform float {lum_purple}: hint_range(.0, 5.) = 1.;
uniform float {lum_magenta}: hint_range(.0, 5.) = 1.;

uniform float {hue_red}: hint_range(-.5, .5) = .0;
uniform float {hue_orange}: hint_range(-.5, .5) = .0;
uniform float {hue_yellow}: hint_range(-.5, .5) = .0;
uniform float {hue_green}: hint_range(-.5, .5) = .0;
uniform float {hue_aqua}: hint_range(-.5, .5) = .0;
uniform float {hue_blue}: hint_range(-.5, .5) = .0;
uniform float {hue_purple}: hint_range(-.5, .5) = .0;
uniform float {hue_magenta}: hint_range(-.5, .5) = .0;

uniform float {smoothness}: hint_range(.1, 1.) = .3;
"

func _get_shader_fragment_snip() -> String:
	return "
	float {h} = .0;
	float {max_c} = max(color.r, max(color.g, color.b));
	float {min_c} = min(color.r, min(color.g, color.b));
	float {delta} = {max_c} - {min_c};
	
	if ({delta} > .0) {
		if ({max_c} == color.r) {h} = mod((color.g - color.b) / {delta}, 6.);
		else if ({max_c} == color.g) {h} = ((color.b - color.r) / {delta}) + 2.;
		else {h} = ((color.r - color.g) / {delta}) + 4.;
		{h} /= 6.;
	}
	
	float {centers}[9]  = float[](.0, .08, .15, .31, .50, .64, .79, .92, 1.);
	
	float {lums}[9] = float[]({lum_red}, {lum_orange}, {lum_yellow}, {lum_green}, {lum_aqua}, {lum_blue}, {lum_purple}, {lum_magenta}, {lum_red});
	float {sats}[9] = float[]({sat_red}, {sat_orange}, {sat_yellow}, {sat_green}, {sat_aqua}, {sat_blue}, {sat_purple}, {sat_magenta}, {sat_red});
	float {hues}[9] = float[]({hue_red}, {hue_orange}, {hue_yellow}, {hue_green}, {hue_aqua}, {hue_blue}, {hue_purple}, {hue_magenta}, {hue_red});
	
	float {final_lum} = .0;
	float {final_sat} = .0;
	float {final_hue} = .0;
	float {total_weight} = .0;
	
	for (int i = 0; i < 9; i++) {
		float {dist} = abs({h} - {centers}[i]);
		float {weight} = 1. - smoothstep(.0, {smoothness}, {dist});
		
		{final_lum} += {lums}[i] * {weight};
		{final_sat} += {sats}[i] * {weight};
		{final_hue} += {hues}[i] * {weight};
		{total_weight} += {weight};
	}
	
	{final_lum} /= {total_weight};
	{final_sat} /= {total_weight};
	{final_hue} /= {total_weight};
	
	if (abs({final_hue}) > .001) {
		color = apply_hue(color, {final_hue});
	}
	color *= {final_lum};
	color = apply_sat(color, {final_sat});
"
