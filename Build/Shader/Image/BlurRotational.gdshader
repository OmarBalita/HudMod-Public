shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform vec2 center = vec2(0.0);
uniform float blur_amount: hint_range(-3.141592, 3.141592) = .05;
uniform int quality: hint_range(1, 128) = 8;
uniform bool clip_border = false;
uniform bool transparency = true;

const float ROOT_TWO = 1.41421356237;

void vertex(){
	if (clip_border == false) {
		vec2 vertex = TEXTURE_PIXEL_SIZE * VERTEX;
		vertex = vertex * (2.0 * length(center) + ROOT_TWO) + center;
		VERTEX = vertex / TEXTURE_PIXEL_SIZE;
		VERTEX += center;
		UV = (UV - 0.5) * (2.0 * length(center) + ROOT_TWO) + center + 0.5;
	}
}

void fragment() {
	float in_square = inside_unit_square(UV);
	float num_samples = in_square;
	float step_size = blur_amount / (float(quality));
	
	vec4 color = texture(TEXTURE, UV) * in_square;
	
	vec2 uv;
	
	for(int i = 1; i <= quality; i++){
		uv = rotate(UV, center + 0.5, float(i) * step_size);
		in_square = inside_unit_square(uv);
		num_samples += in_square;
		color += texture(TEXTURE, uv) * in_square;
		
		uv = rotate(UV, center + 0.5, -float(i) * step_size);
		in_square = inside_unit_square(uv);
		num_samples += in_square;
		color += texture(TEXTURE, uv) * in_square;
	}
	
	color.rgb = color.rgb / num_samples;
	if (transparency) {
		color.a /= float(quality) * 2. + 1.;
	}
	
	COLOR = color;
}