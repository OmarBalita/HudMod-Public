class_name CompCanvasItem extends SnippetShaderComponentRes

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

@export var visible: bool = true
@export var modulate: Color = Color.WHITE
@export var opacity: float = 1.
@export var show_behind_parent: bool
@export var top_level: bool
@export var clip_children: ClipChildrenMode

@export var texture_filter: TextureFilter
@export var texture_repeat: TextureRepeat

func has_method_type() -> bool: return false

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"Visibility": export_method(ExportMethodType.METHOD_ENTER_CATEGORY),
		&"visible": export(bool_args(visible)),
		&"modulate": export(color_args(modulate)),
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
	submit_stacked_value_with_custom_method(&"visible", visible)
	submit_stacked_value_with_custom_method(&"show_behind_parent", show_behind_parent)
	submit_stacked_value_with_custom_method(&"top_level", top_level)
	submit_stacked_value(&"clip_children", clip_children)
	submit_stacked_value_with_custom_method(&"texture_filter", texture_filter)
	submit_stacked_value_with_custom_method(&"texture_repeat", texture_repeat)
	
	set_shader_prop(&"modulate", Color(modulate, opacity))

func _get_shader_global_params_snip() -> String:
	return "
uniform vec4 {modulate}: source_color;
"

func _get_shader_fragment_snip() -> String:
	return "
	color.rgb *= {modulate}.rgb;
	alpha *= {modulate}.a;
"

