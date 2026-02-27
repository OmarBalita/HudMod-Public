shader_type canvas_item;

uniform float clarity_amount : hint_range(.0, 4.) = 2.; 
uniform float detail_radius : hint_range(.1, 5.) = 1.;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	
	vec2 ps = (1. / vec2(textureSize(TEXTURE, 0))) * detail_radius;
	
	vec3 neighbors = vec3(.0);
	neighbors += texture(TEXTURE, UV + vec2(-ps.x, .0)).rgb;
	neighbors += texture(TEXTURE, UV + vec2(ps.x, .0)).rgb;
	neighbors += texture(TEXTURE, UV + vec2(.0, -ps.y)).rgb;
	neighbors += texture(TEXTURE, UV + vec2(.0, ps.y)).rgb;
	vec3 blurred = neighbors / 4.;

	vec3 high_pass = (base_color.rgb - blurred) + 0.5;
	
	vec3 result;
	for(int i = 0; i < 3; i++) {
		float a = base_color.rgb[i];
		float b = high_pass[i];
		result[i] = (1. - 2. * b) * (a * a) + 2. * b * a;
	}
	vec3 final_rgb = mix(base_color.rgb, result, clarity_amount);
	COLOR = vec4(final_rgb, base_color.a);
}