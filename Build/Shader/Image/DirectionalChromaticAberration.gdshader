shader_type canvas_item;

uniform vec2 direction = vec2(1., .0);
uniform float amount = .02;
uniform int quality: hint_range(1, 32) = 8;

void fragment() {
	vec2 dir = normalize(direction) * amount;
	
	vec3 final_color = vec3(0.0);
	
	for (int i = 0; i < quality; i++) {
		float t = float(i) / float(quality - 1) - 0.5;
		
		float r = texture(TEXTURE, UV + dir * t).r;
		float g = texture(TEXTURE, UV + dir * t * 0.5).g;
		float b = texture(TEXTURE, UV).b;
		
		final_color += vec3(r, g, b);
	}
	COLOR = vec4(final_color / float(quality), 1.0);
}