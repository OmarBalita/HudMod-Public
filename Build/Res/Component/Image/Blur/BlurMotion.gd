class_name CompBlurMotion extends PassShaderComponentRes

@export var auto: bool = false
@export var dir: Vector2 = Vector2.RIGHT
@export var power: float = .05
@export var quality: int = 8
@export var clip_border: bool = false
@export var transparancy: bool = true

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"auto": export(bool_args(auto)),
		&"dir": export(vec2_args(dir), [get.bind(&"auto"), [false]]),
		&"power": export(float_args(power, .0, 100., .001)),
		&"quality": export(int_args(quality, 1, 64)),
		&"clip_border": export(bool_args(clip_border)),
		&"transparancy": export(bool_args(transparancy))
	}

func _postprocess(frame: int) -> void:
	var _dir: Vector2
	var _power: float
	
	if auto:
		var dict: Dictionary[StringName, Array] = owner.shared_data_get_stacked_at(frame - 1)
		var pos_key: StringName = &"position"
		if dict.has(pos_key):
			var old_pos: Vector2 = owner.get_custom_stacked_values_key_result(dict, pos_key)
			var delta: Vector2 = owner.get_stacked_values_key_result(pos_key) - old_pos
			_dir = delta.normalized()
			_power = delta.length() * power
			if _dir == Vector2.ZERO:
				_dir = Vector2.RIGHT
	else:
		_dir = dir
		_power = power
	
	set_shader_props({
		&"dir": _dir,
		&"power": _power,
		&"quality": quality,
		&"clip_border": clip_border,
		&"transparancy": transparancy
	})

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/BlurMotion.gdshader")

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform vec2 {dir} = vec2(1., .0);
#uniform float {power} = .05;
#uniform int {quality}: hint_range(1, 64) = 4;
#uniform bool {clip_border} = false;
#uniform bool {transparancy} = true;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#float {in_square} = inside_unit_square(UV);
	#float {num_samples} = {in_square};
	#
	#vec4 {color} = texture(TEXTURE, UV) * {in_square};
	#vec2 {step_size} = normalize({dir}) * {power} / (float({quality}));
	#vec2 {uv};
	#
	#for(int i = 1; i <= {quality}; i++){
		#vec2 {uv_scalar} = {step_size} * float(i);
		#
		#{uv} = UV + {uv_scalar};
		#{in_square} = inside_unit_square({uv});
		#{num_samples} += {in_square};
		#{color} += texture(TEXTURE, {uv}) * {in_square};
		#
		#{uv} = UV - {uv_scalar};
		#{in_square} = inside_unit_square({uv});
		#{num_samples} += {in_square};
		#{color} += texture(TEXTURE, {uv}) * {in_square};
	#}
	#
	#{color}.rgb /= {num_samples};
	#if ({transparancy}) {
		#{color}.a /= float({quality}) * 2.0 + 1.0;
	#}
	#
	#color.rgb = {color}.rgb;
	#alpha = {color}.a;
#"
#
#func _get_shader_vertex_snip() -> String:
	#return "
	#if ({clip_border} == false) {
		#vec2 {blur_size} = abs(normalize({dir}) * {power}) * 2.;
		#vertex *= {blur_size} + 1.;
		#uv = (uv - .5) * ({blur_size} + 1.) + .5;
	#}
#"

