shader_type canvas_item;

#include "res://Build/Shader/Global.gdshaderinc"

uniform float blur_amount: hint_range(.0, 1.) = .02;
uniform int quality: hint_range(1, 32) = 4;
uniform bool transparancy = true;

void vertex(){
	if (transparancy) {
		VERTEX *= (blur_amount + 1.);
		UV = (UV - .5) * (blur_amount + 1.) + .5;
	}
}

void fragment(){
	vec4 color = vec4(.0);
	float total_samples = .0;
	float count = float((quality * 2 + 1) * (quality * 2 + 1));
	
	float ratio = float(TEXTURE_PIXEL_SIZE.x) / float(TEXTURE_PIXEL_SIZE.y);
	vec2 step_size = vec2(blur_amount * ratio, blur_amount) / float(quality);
	
	for(int x = -quality; x <= quality; x++){
		for(int y = -quality; y <= quality; y++){
			vec2 offset = vec2(float(x), float(y)) * step_size;
			vec2 target_uv = UV + offset;
			
			float in_square = inside_unit_square(target_uv);
			
			color += texture(TEXTURE, target_uv) * in_square;
			total_samples += in_square;
		}
	}
	
	if (total_samples > .0) {
		color.rgb /= total_samples;
		
		if (transparancy) {
			color.a /= count;
		} else {
			color.a = (color.a / total_samples);
		}
	}
	
	if (transparancy) {
		color.a *= color.a;
		//vec2 center_dist = abs(UV - .5) * 1.5;
		//float max_dist = max(center_dist.x, center_dist.y);
		//float edge_factor = smoothstep(1. - edge_fade, 1., max_dist);
		//color.a *= (1. - edge_factor);
	}
	
	COLOR = color;
}