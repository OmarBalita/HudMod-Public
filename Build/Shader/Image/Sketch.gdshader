shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform float line_strength: hint_range(.0, 5.) = 2.;
uniform float hatch_strength: hint_range(.0, 1.) = .5;
uniform float hatch_density: hint_range(100., 1000.) = 500.;
uniform float hatch_weight: hint_range(.1, 5.) = .1;
uniform vec4 ink_color: source_color = vec4(.0, .0, .0, 1.);
uniform vec4 paper_color: source_color = vec4(.8, .8, .8, 1.);

void fragment() {
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 uv = UV;
	
	vec4 color = texture(TEXTURE, uv);
	float brightness = get_luminance(color.rgb);
	
	float x = 1. / tex_size.x;
	float y = 1. / tex_size.y;
	float s00 = texture(TEXTURE, uv + vec2(-x, -y)).r;
	float s01 = texture(TEXTURE, uv + vec2(0, -y)).r;
	float s02 = texture(TEXTURE, uv + vec2(x, -y)).r;
	float s10 = texture(TEXTURE, uv + vec2(x, 0)).r;
	float s12 = texture(TEXTURE, uv + vec2(x, 0)).r;
	float s20 = texture(TEXTURE, uv + vec2(-x, y)).r;
	float s21 = texture(TEXTURE, uv + vec2(0, y)).r;
	float s22 = texture(TEXTURE, uv + vec2(x, y)).r;
	float gx = s00 + 2. * s10 + s20 - s02 - 2. * s12 - s22;
	float gy = s00 + 2. * s01 + s02 - s20 - 2. * s21 - s22;
	float edge = sqrt(gx * gx + gy * gy);
	edge = smoothstep(.1, .4, edge * line_strength);
	
	float h1 = clamp(sin((UV.x + UV.y) * hatch_density), .0, 1.);
	h1 = pow(h1, hatch_weight);
	
	float h2 = clamp(sin((UV.x - UV.y) * hatch_density), .0, 1.);
	h2 = pow(h2, hatch_weight);
	
	float shading = brightness;
	if (brightness < .6) shading += h1;
	if (brightness < .3) shading += h2 * .8;
	
	float final_sketch = mix(1., .0, edge);
	final_sketch -= shading * hatch_strength * (1. - brightness);
	
	vec4 final_color = mix(ink_color, paper_color, clamp(final_sketch, .0, 1.));
	
	COLOR = final_color;
}