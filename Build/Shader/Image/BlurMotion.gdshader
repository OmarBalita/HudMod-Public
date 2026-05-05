shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform vec2 dir = vec2(1., .0);
uniform float blur_amount = .05;
uniform int quality: hint_range(1, 64) = 4;
uniform bool clip_border = false;
uniform bool transparancy = true;

void vertex(){
	if (clip_border == false) {
		vec2 blur_size = abs(normalize(dir) * blur_amount) * 2.;
		VERTEX *= blur_size + 1.;
		UV = (UV - .5) * (blur_size + 1.) + .5;
	}
}

void fragment(){
	float in_square = inside_unit_square(UV);
	float num_samples = in_square;
	
	vec4 color = texture(TEXTURE, UV) * in_square;
	vec2 step_size = normalize(dir) * blur_amount / (float(quality));
	vec2 uv;
	
	for(int i = 1; i <= quality; i++){
		vec2 uv_scalar = step_size * float(i);
		
		uv = UV + uv_scalar;
		in_square = inside_unit_square(uv);
		num_samples += in_square;
		color += texture(TEXTURE, uv) * in_square;
		
		uv = UV - uv_scalar;
		in_square = inside_unit_square(uv);
		num_samples += in_square;
		color += texture(TEXTURE, uv) * in_square;
	}
	
	color.rgb /= num_samples;
	if (transparancy) {
		color.a /= float(quality) * 2.0 + 1.0;
	}
	
	COLOR = color;
}
