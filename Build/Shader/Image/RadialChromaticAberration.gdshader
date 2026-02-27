shader_type canvas_item;

uniform float amount: hint_range(.0, 256.) = 1.;
uniform int quality: hint_range(1, 32) = 8;

void fragment() {
	vec2 center = vec2(.5);
	vec2 dir = UV - center;
	float dist = length(dir);
	
	float strength = clamp(dist * amount * .02, .0, 1.);
	
	vec3 col = vec3(.0);
	float total_weight = .0;
	
	for (int i = 0; i < quality; i++) {
		float t = float(i) / float(quality - 1);
		
		float r_offset = 1. + strength * t;
		float g_offset = 1. + strength * t * .5;
		float b_offset = 1.; 
		
		col.r += texture(TEXTURE, center + dir * r_offset).r;
		col.g += texture(TEXTURE, center + dir * g_offset).g;
		col.b += texture(TEXTURE, center + dir * b_offset).b;
		
		total_weight += 1.;
	}
	
	COLOR = vec4(col / total_weight, 1.);
}

