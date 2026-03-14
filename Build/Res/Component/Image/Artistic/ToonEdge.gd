class_name CompToonEdge extends PassShaderComponentRes

@export var line_thickness: int = 4
@export var sensitivity: float = .2
@export var line_color: Color = Color.BLACK

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"line_thickness": export(int_args(line_thickness, 0, 50)),
		&"sensitivity": export(float_args(sensitivity, .0, 1.)),
		&"line_color": export(color_args(line_color))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/ToonEdge.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"line_thickness", line_thickness)
	set_shader_prop(&"sensitivity", sensitivity)
	set_shader_prop(&"line_color", line_color)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {line_thickness}: hint_range(.0, 50.);
#uniform float {sensitivity}: hint_range(.0, 1.);
#uniform vec4 {line_color}: source_color;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {size} = vec2(textureSize(TEXTURE, 0));
	#float {x} = {line_thickness} / {size}.x;
	#float {y} = {line_thickness} / {size}.y;
	#
	#vec3 {center} = texture(TEXTURE, UV).rgb;
	#vec3 {left} = texture(TEXTURE, UV + vec2(-{x}, .0)).rgb;
	#vec3 {right} = texture(TEXTURE, UV + vec2({x}, .0)).rgb;
	#vec3 {top} = texture(TEXTURE, UV + vec2(.0, -{y})).rgb;
	#vec3 {bottom} = texture(TEXTURE, UV + vec2(.0, {y})).rgb;
	#
	#float {b_center} = get_brightness({center});
	#float {diff} = .0;
	#{diff} += abs({b_center} - get_brightness({left}));
	#{diff} += abs({b_center} - get_brightness({right}));
	#{diff} += abs({b_center} - get_brightness({top}));
	#{diff} += abs({b_center} - get_brightness({bottom}));
	#
	#if ({diff} > {sensitivity}) {
		#color = {line_color}.rgb;
		#alpha = {line_color}.a;
	#}
#"
