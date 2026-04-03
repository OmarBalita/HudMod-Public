class_name CompCanvasItem extends SnippetShaderComponentRes

enum BlendMode {
	NORMAL,
	DARKEN,
	MULTIPLY,
	COLOR_BURN,
	LINEAR_BURN,
	LIGHTEN,
	SCREEN,
	COLOR_DODGE,
	LINEAR_DODGE,
	OVERLAY,
	SOFT_LIGHT,
	HARD_LIGHT,
	VIVID_LIGHT,
	DIFFERENCE,
	EXCLUSION,
	SUBTRACT
}

enum ClipChildrenMode {
	CLIP_CHILDREN_DISABLED,
	CLIP_CHILDREN_ONLY,
	CLIP_CHILDREN_AND_DRAW
}

enum TextureFilter {
	INHERIT,
	NEAREST,
	LINEAR,
	NEAREST_MIPMAP,
	LINEAR_MIPMAP,
	NEAREST_MIPMAP_ANISOTROPIC,
	LINEAR_MIPMAP_ANISOTROPIC
}

enum TextureRepeat {
	INHERIT,
	DISABLE,
	ENABLE,
	MIRROR
}


@export var position: Vector2
@export var rotation_degrees: float
@export var scale: Vector2 = Vector2.ONE
@export var skew: float

@export var visible: bool = true
@export var modulate: Color = Color.WHITE
@export var blend_mode: BlendMode
@export var opacity: float = 1.

@export var show_behind_parent: bool
@export var top_level: bool
@export var clip_children: ClipChildrenMode

@export var texture_filter: TextureFilter
@export var texture_repeat: TextureRepeat

func has_method_type() -> bool: return false

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	
	return {
		&"Transform": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"position": export(vec2_args(position)),
		&"rotation_degrees": export(float_args(rotation_degrees)),
		&"scale": export(vec2_args(scale)),
		&"skew": export(float_args(skew)),
		&"_Transform": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Visibility": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"visible": export(bool_args(visible)),
		&"modulate": export(color_args(modulate)),
		&"blend_mode": export(options_args(blend_mode, BlendMode)),
		&"opacity": export(float_args(opacity, .0, 1., .001, .01, .1, IS.FloatControllerType.TYPE_SLIDER)),
		&"show_behind_parent": export(bool_args(show_behind_parent)),
		&"top_level": export(bool_args(top_level)),
		&"clip_children": export(options_args(clip_children, ClipChildrenMode)),
		&"_Visibility": export_method(ExportMethodType.METHOD_EXIT_CATEGORY),
		
		&"Texture": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"texture_filter": export(options_args(texture_filter, TextureFilter)),
		&"texture_repeat": export(options_args(texture_repeat, TextureRepeat)),
		&"_Texture": export_method(ExportMethodType.METHOD_EXIT_CATEGORY)
	}

func _process(frame: int) -> void:
	
	submit_stacked_value(&"position", position)
	submit_stacked_value(&"rotation_degrees", rotation_degrees)
	submit_stacked_value(&"scale", scale)
	submit_stacked_value(&"skew", skew)
	
	submit_stacked_value_with_custom_method(&"visible", visible)
	submit_stacked_value_with_custom_method(&"show_behind_parent", show_behind_parent)
	submit_stacked_value_with_custom_method(&"top_level", top_level)
	submit_stacked_value(&"clip_children", clip_children)
	submit_stacked_value_with_custom_method(&"texture_filter", texture_filter)
	submit_stacked_value_with_custom_method(&"texture_repeat", texture_repeat)
	
	set_shader_prop(&"modulate", modulate)
	set_shader_prop(&"blend_mode", blend_mode)
	set_shader_prop(&"opacity", opacity)


func _apply_custom_stacked_values(frame: int, dict: Dictionary[StringName, Array]) -> void:
	apply_stacked_value(dict, &"position", sample_or_get(self, &"position", frame))
	apply_stacked_value(dict, &"rotation_degrees", sample_or_get(self, &"rotation_degrees", frame))
	apply_stacked_value(dict, &"scale", sample_or_get(self, &"scale", frame))


func _get_shader_global_params_snip() -> String:
	return "
uniform vec4 {modulate}: source_color = vec4(1., 1., 1., 1.);
uniform int {blend_mode}: hint_range(0, 15) = 0;
uniform float {opacity}: hint_range(.0, 1.) = 1.;

uniform sampler2D {SCREEN_TEXTURE}: hint_screen_texture, filter_linear_mipmap;
"

func _get_shader_fragment_snip() -> String:
	return "
	vec4 {tex_color} = vec4(color, alpha);
	
	{tex_color}.rgb *= {modulate}.rgb;
	{tex_color}.a *= {modulate}.a;
	
	float {final_alpha} = {tex_color}.a * {opacity};
	
	if ({blend_mode} == 0) {
		
		color = {tex_color}.rgb;
		alpha = {final_alpha};
		
	} else {
		
		vec4 {screen_col} = texture({SCREEN_TEXTURE}, SCREEN_UV);
		
		vec3 {base} = {screen_col}.rgb;
		vec3 {blend} = {tex_color}.rgb;
		vec3 {result} = {blend};
		
		switch ({blend_mode}) {
			case 0: // Normal
				{result} = {blend};
				break;
			
			case 1: // Darken
				{result} = min({base}, {blend});
				break;
			case 2: // Multiply
				{result} = {base} * {blend};
				break;
			case 3: // Color Burn
				{result} = vec3(color_burn({base}.r, {blend}.r), color_burn({base}.g, {blend}.g), color_burn({base}.b, {blend}.b));
				break;
			case 4: // Linear Burn
				{result} = max(vec3(0.0), {base} + {blend} - vec3(1.0));
				break;
				
			case 5: // Lighten
				{result} = max({base}, {blend});
				break;
			case 6: // Screen
				{result} = 1.0 - (1.0 - {base}) * (1.0 - {blend});
				break;
			case 7: // Color Dodge
				{result} = vec3(color_dodge({base}.r, {blend}.r), color_dodge({base}.g, {blend}.g), color_dodge({base}.b, {blend}.b));
				break;
			case 8: // Linear Dodge (Add)
				{result} = min(vec3(1.0), {base} + {blend});
				break;
			
			case 9: // Overlay
				{result} = vec3(overlay({base}.r, {blend}.r), overlay({base}.g, {blend}.g), overlay({base}.b, {blend}.b));
				break;
			case 10: // Soft Light
				{result} = vec3(soft_light({base}.r, {blend}.r), soft_light({base}.g, {blend}.g), soft_light({base}.b, {blend}.b));
				break;
			case 11: // Hard Light
				{result} = vec3(overlay({blend}.r, {base}.r), overlay({blend}.g, {base}.g), overlay({blend}.b, {base}.b));
				break;
			case 12: // Vivid Light
				{result} = vec3(vivid_light({base}.r, {blend}.r), vivid_light({base}.g, {blend}.g), vivid_light({base}.b, {blend}.b));
				break;
				
			case 13: // Difference
				{result} = abs({base} - {blend});
				break;
			case 14: // Exclusion
				{result} = {base} + {blend} - 2. * {base} * {blend};
				break;
			case 15: // Subtract
				{result} = max(vec3(.0), {base} - {blend});
				break;
		
		}
		
		color.rgb = mix({base}, clamp({result}, .0, 1.), {final_alpha});
		alpha = {tex_color}.a;
	}
"



