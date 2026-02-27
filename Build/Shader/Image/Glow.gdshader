shader_type canvas_item;

uniform vec4 color: source_color = vec4(1.);
uniform float power: hint_range(.0, 20.) = 4.;
uniform float radius: hint_range(.0, 30.) = 5.;
uniform int quality: hint_range(1, 20) = 8;

vec4 calculate_glow(sampler2D tex, vec2 uv, vec2 pixel_size) {
	vec4 glow_accum = vec4(.0);
	float total_weight = .0;
	
	for (int i = -quality; i <= quality; i++) {
		for (int j = -quality; j <= quality; j++) {
			vec2 offset = vec2(float(i), float(j)) * radius * pixel_size;
			
			float weight = 1. - (length(vec2(float(i), float(j))) / float(quality));
			weight = clamp(weight, .0, 1.);
			weight = pow(weight, 2.);
			
			glow_accum += texture(tex, uv + offset) * weight;
			total_weight += weight;
		}
	}
	
	return glow_accum / total_weight;
}

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;
	
	vec4 glow = calculate_glow(TEXTURE, UV, pixel_size);
	
	glow.rgb *= color.rgb * power;
	
	vec4 final_color = original_color;
	
	final_color.rgb += glow.rgb * glow.a;
	
	final_color.a = max(original_color.a, glow.a * power * 0.5);
	
	COLOR = final_color;
}