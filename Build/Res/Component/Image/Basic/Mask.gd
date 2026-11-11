#############################################################################
##  This file is part of: HudMod Video Editor                              ##
##  https://omar-top.itch.io/hudmod-video-editor                           ##
## ----------------------------------------------------------------------- ##
##  Founded by Omar Mohammed Balita.                                       ##
##  Copyright © 2026 Omar Mohammed Balita, Malek Youssef Elatek.           ##
## ----------------------------------------------------------------------- ##
##  GPLv3                                                                  ##
#############################################################################
class_name CompMask extends SnippetShaderComponentRes

enum MaskType {
	TYPE_CIRCLE,
	TYPE_RECTANGLE,
	TYPE_TRIANGLE,
	TYPE_MIRROR,
	TYPE_POLYGON,
	#TYPE_TEXTURE
}

const POLYGON_MAX_POINTS: int = 64
const POLYGON_MIN_POINTS: int = 3

@export var mask_type: MaskType
@export var center: Vector2
@export var rotation: float
@export var size: Vector2 = Vector2(.2, .2)
@export var polygon_points: Array = [Vector2(-1., -1.), Vector2(1., -1.), Vector2(1., 1.), Vector2(-1., 1.)]
@export var feather: float
@export var reverse: bool
@export var mask_texture: String

func _get_exported_props() -> Dictionary[StringName, Dictionary]:
	return {
		&"mask_type": export(options_args(mask_type, MaskType)),
		&"center": export(vec2_args(center)),
		&"rotation": export(float_args(rotation, -INF, INF, .01, .5, 10.)),
		&"size": export(vec2_args(size, false, true)),
		&"polygon_points": export(list_args(polygon_points, &"Vector2", true, true, true, true, POLYGON_MIN_POINTS), [get.bind(&"mask_type"), [MaskType.TYPE_POLYGON]]),
		&"feather": export(float_args(feather, .0, 10., .001, .01, 1., IS.FloatControllerType.TYPE_SLIDER)),
		&"reverse": export(bool_args(reverse)),
		&"mask_texture": export(string_args(mask_texture), [get.bind(&"mask_type"), [5]])
	}

func _process(frame: int) -> void:
	set_shader_prop(&"mask_type", mask_type)
	set_shader_prop(&"center", center)
	set_shader_prop(&"rotation", rotation)
	set_shader_prop(&"size", size)
	set_shader_prop(&"feather", feather)
	set_shader_prop(&"reverse", reverse)
	
	var points: PackedVector2Array
	points.resize(POLYGON_MAX_POINTS)
	var points_count: int = mini(polygon_points.size(), POLYGON_MAX_POINTS)
	for index: int in points_count:
		points[index] = polygon_points[index]
	set_shader_prop(&"polygon_points", points)
	set_shader_prop(&"polygon_count", points_count)

func _get_shader_global_params_snip() -> String:
	return '
uniform int {mask_type}: hint_enum("Circle", "Rectangle", "Triangle", "Mirror", "Polygon", "Texture") = 0;
uniform vec2 {center};
uniform float {rotation};
uniform vec2 {size};
uniform float {feather};
uniform bool {reverse};
uniform sampler2D {mask_texture}: source_color;
uniform vec2 {polygon_points}[64];
uniform int {polygon_count};
'

func _get_shader_fragment_snip() -> String:
	return "
	vec2 {_center} = {center} + vec2(.5, .5);

	vec2 {tex_size} = vec2(textureSize(TEXTURE, 0));
	float {aspect} = {tex_size}.x / {tex_size}.y;

	vec2 {uv_corrected} = UV;
	{uv_corrected}.x *= {aspect};

	vec2 {center_corrected} = {_center};
	{center_corrected}.x *= {aspect};

	vec2 {p} = {uv_corrected} - {center_corrected};

	float {rad} = radians({rotation});
	float {cos_a} = cos({rad});
	float {sin_a} = sin({rad});
	mat2 {rot_mat} = mat2(vec2({cos_a}, -{sin_a}), vec2({sin_a}, {cos_a}));
	{p} = {rot_mat} * {p};

	float {mask} = .0;

	switch ({mask_type}) {
		case 0: // Circle
			float {dist_circle} = length({p} / {size});
			{mask} = smoothstep(1. + {feather}, 1., {dist_circle});
			break;
		case 1: // Rectangle
			vec2 {d_rect} = abs({p}) - {size};
			float {dist_rect} = length(max({d_rect}, .0)) + min(max({d_rect}.x, {d_rect}.y), .0);
			{mask} = smoothstep({feather}, .0, {dist_rect});
			break;
		case 2: // Triangle
			vec2 {p_tri} = {p} / {size};
			float {dist_tri} = max(abs({p_tri}.x) * .866025 + {p_tri}.y * .5, -{p_tri}.y) - .5;
			{mask} = smoothstep({feather}, .0, {dist_tri});
			break;
		case 3: // Mirror
			float {dist_mirror} = abs({p}.y);
			{mask} = smoothstep({size}.y + {feather}, {size}.y, {dist_mirror});
			break;
		case 4: // Polygon
			float {d_poly} = 1e10;
			float {s_poly} = 1.;
			for (int {i} = 0; {i} < 64; {i}++) {
				if ({i} >= {polygon_count}) break;
				int {j} = ({i} == 0) ? {polygon_count} - 1 : {i} - 1;
				vec2 {vi} = {polygon_points}[{i}] * {size};
				vec2 {vj} = {polygon_points}[{j}] * {size};
				vec2 {e} = {vj} - {vi};
				vec2 {w} = {p} - {vi};
				vec2 {b} = {w} - {e} * clamp(dot({w}, {e}) / max(dot({e}, {e}), 1e-8), .0, 1.);
				{d_poly} = min({d_poly}, dot({b}, {b}));
				bool {c1} = {p}.y >= {vi}.y;
				bool {c2} = {p}.y < {vj}.y;
				bool {c3} = {e}.x * {w}.y > {e}.y * {w}.x;
				if (({c1} && {c2} && {c3}) || (!{c1} && !{c2} && !{c3})) {s_poly} = -{s_poly};
			}
			float {dist_poly} = {polygon_count} >= 3 ? {s_poly} * sqrt({d_poly}) : 1e10;
			{mask} = smoothstep({feather}, .0, {dist_poly});
			break;
		case 5: // Texture
			vec2 {tex_uv} = ({p} / ({size} * 2.)) + vec2(.5);
			if ({tex_uv}.x < .0 || {tex_uv}.x > 1. || {tex_uv}.y < .0 || {tex_uv}.y > 1.) {
				{mask} = .0;
			} else {
				{mask} = texture({mask_texture}, {tex_uv}).a;
				float {edge_f} = smoothstep(.5 + {feather}, .5, length({p}/{size}) - .5);
				{mask} *= {edge_f};
			}
			break;
	}
	if ({reverse}) {mask} = 1. - {mask};
	alpha *= {mask};
"
