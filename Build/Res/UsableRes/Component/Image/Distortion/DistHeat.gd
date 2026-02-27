class_name CompDistortionHeat extends PassShaderComponentRes

@export var noise_texture: NoiseTexture2D = GlobalServer.global_usable_res.noise_texture_seamless
@export var direction: Vector2 = Vector2.UP
@export var speed: float = .1
@export var force: float = .02

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"direction": export(vec2_args(direction)),
		&"speed": export(float_args(speed, .0, 1., .0001)),
		&"force": export(float_args(force, .0, .1, .0001))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/DistHeat.gdshader")

func _process(frame: int) -> void:
	set_shader_prop(&"direction", direction)
	set_shader_prop(&"speed", speed)
	set_shader_prop(&"force", force)

func _ready_shader() -> void:
	set_shader_prop(&"noise_texture", GlobalServer.global_usable_res.noise_texture_seamless)

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform sampler2D {noise_texture}: hint_default_black, repeat_enable;
#uniform vec2 {direction} = vec2(.0, 1.);
#uniform float {speed}: hint_range(.0, 1.);
#uniform float {force}: hint_range(.0, .1);
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {noise_uv} = UV + normalize({direction}) * time * {speed};
	#float {noise_value} = texture({noise_texture}, {noise_uv}).r;
	#float {distortion} = ({noise_value} * 2. - 1.) * {force};
	#vec2 {distorted_uv} = UV + {distortion};
	#color = texture(TEXTURE, {distorted_uv}).rgb;
#"
