class_name CompDistortionRipple extends PassShaderComponentRes

@export var center: Vector2
@export var force: float = .05
@export var size: float = .5
@export var thickness: float = .1
@export var speed: float = .5

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"center": export(vec2_args(center)),
		&"force": export(float_args(force, -1., 1., .001)),
		&"size": export(float_args(size, .0, 2., .001)),
		&"thickness": export(float_args(thickness, .0, 1., .001)),
		&"speed": export(float_args(speed, .0, 10., .001))
	}

func _process(frame: int) -> void:
	set_shader_props({
		&"center": center,
		&"force": force,
		&"size": size,
		&"thickness": thickness,
		&"speed": speed,
	})

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/DistRipple.gdshader")

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform vec2 {center} = vec2(.0);
#uniform float {force}: hint_range(-1., 1.);
#uniform float {size}: hint_range(.0, 2.);
#uniform float {thickness}: hint_range(.0, 1.);
#uniform float {speed}: hint_range(.0, 10.);
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {_center} = {center} + vec2(.5);
	#float {ratio} = TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y;
	#float {dist} = distance(UV, {_center});
	#float {mask} = (1. - smoothstep({size} - {thickness}, {size}, {dist})) * smoothstep({size} - {thickness} * 2., {size} - {thickness}, {dist});
	#float {ripple} = sin({dist} * 50. - time * {speed}) * {force} * {mask};
	#vec2 {distorted_uv} = UV + normalize(UV - {_center}) * {ripple};
	#vec4 {result} = texture(TEXTURE, {distorted_uv});
	#color = {result}.rgb;
	#alpha = {result}.a;
#"

