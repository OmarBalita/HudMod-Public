class_name CompSketch extends PassShaderComponentRes

@export var line_strength: float = 2.
@export var hatch_strength: float = .2
@export var hatch_density: float = 500.
@export var ink_color: Color = Color.BLACK
@export var paper_color: Color = Color.GRAY

func _get_exported_props() -> Dictionary[StringName, ExportInfo]:
	return {
		&"line_strength": export(float_args(line_strength, .0, 5.)),
		&"hatch_strength": export(float_args(hatch_strength, .0, 1.)),
		&"hatch_density": export(float_args(hatch_density, 100., 1000.)),
		&"ink_color": export(color_args(ink_color)),
		&"paper_color": export(color_args(paper_color))
	}

static func _shader() -> Shader:
	return preload("res://Build/Shader/Image/Sketch.gdshader")

func _process(frame: int) -> void:
	set_shader_props({
		&"line_strength": line_strength,
		&"hatch_strength": hatch_strength,
		&"hatch_density": hatch_density,
		&"ink_color": ink_color,
		&"paper_color": paper_color,
	})

#func _get_shader_global_params_snip() -> String:
	#return "
#uniform float {line_strength}: hint_range(.0, 5.);
#uniform float {hatch_strength}: hint_range(.0, 1.);
#uniform float {hatch_density}: hint_range(100., 1000.);
#uniform float {hatch_weight}: hint_range(.1, 5.);
#uniform vec4 {ink_color}: source_color;
#uniform vec4 {paper_color}: source_color;
#"
#
#func _get_shader_fragment_snip() -> String:
	#return "
	#vec2 {tex_size} = vec2(textureSize(TEXTURE, 0));
	#float {brightness} = get_luminance(color.rgb);
	#
	#float {x} = 1. / {tex_size}.x;
	#float {y} = 1. / {tex_size}.y;
	#float {s00} = texture(TEXTURE, UV + vec2(-{x}, -{y})).r;
	#float {s01} = texture(TEXTURE, UV + vec2(0, -{y})).r;
	#float {s02} = texture(TEXTURE, UV + vec2({x}, -{y})).r;
	#float {s10} = texture(TEXTURE, UV + vec2({x}, 0)).r;
	#float {s12} = texture(TEXTURE, UV + vec2({x}, 0)).r;
	#float {s20} = texture(TEXTURE, UV + vec2(-{x}, {y})).r;
	#float {s21} = texture(TEXTURE, UV + vec2(0, {y})).r;
	#float {s22} = texture(TEXTURE, UV + vec2({x}, {y})).r;
	#float {gx} = {s00} + 2. * {s10} + {s20} - {s02} - 2. * {s12} - {s22};
	#float {gy} = {s00} + 2. * {s01} + {s02} - {s20} - 2. * {s21} - {s22};
	#float {edge} = sqrt({gx} * {gx} + {gy} * {gy});
	#{edge} = smoothstep(.1, .4, {edge} * {line_strength});
	#
	#float {h1} = clamp(sin((UV.x + UV.y) * {hatch_density}), .0, 1.);
	#{h1} = pow({h1}, {hatch_weight});
	#
	#float {h2} = clamp(sin((UV.x - UV.y) * {hatch_density}), .0, 1.);
	#{h2} = pow({h2}, {hatch_weight});
	#
	#float {shading} = {brightness};
	#if ({brightness} < .6) {shading} += {h1};
	#if ({brightness} < .3) {shading} += {h2} * .8;
	#
	#float {final_sketch} = mix(1., .0, {edge});
	#{final_sketch} -= {shading} * {hatch_strength} * (1. - {brightness});
	#
	#vec4 {final_color} = mix({ink_color}, {paper_color}, clamp({final_sketch}, .0, 1.));
	#
	#color = {final_color}.rgb;
	#alpha = {final_color}.a;
#"
