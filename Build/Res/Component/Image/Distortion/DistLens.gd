class_name CompDistortionLens extends PassShaderComponentRes

@export var force: float = .2
@export var zoom: float = 1.

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"force": export(float_args(force, -5., 5.)),
		&"zoom": export(float_args(zoom, -2., 2.))
	}

func _process(frame: int) -> void:
	set_shader_prop(&"force", force)
	set_shader_prop(&"zoom", zoom)

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/DistLens.gdshader")


#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {force}: hint_range(-.3, 5.);
#uniform float {zoom}: hint_range(-2., 2.);
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {p} = UV * 2. - 1.;
	#float {r2} = dot({p}, {p});
	#float {f} = 1. + {force} * {r2};
	#{p} *= {f} / (1. + {force} * {zoom});
	#vec2 {final_uv} = ({p} + 1.) / 2.;
	#vec4 {color} = texture(TEXTURE, {final_uv});
	#if ({final_uv}.x < .0 || {final_uv}.x > 1. || {final_uv}.y < .0 || {final_uv}.y > 1.) {
		#{color} = vec4(.0, .0, .0, 1.);
	#}
	#color = {color}.rgb;
	#alpha = {color}.a;
#"
