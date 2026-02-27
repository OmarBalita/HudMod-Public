shader_type canvas_item;

uniform vec2 position = vec2(.0);
uniform vec4 tint: source_color;
uniform float brightness: hint_range(.0, 5.) = 1.2;
uniform float _length: hint_range(.0, 1.) = .8;
uniform float threshold: hint_range(.0, 1.) = .5;
uniform float radius: hint_range(.0, 2.) = 1.;
uniform float darkness: hint_range(.0, 1.) = .5;
uniform float darkness_threshold: hint_range(.0, 1.) = .5;
uniform int quality: hint_range(8, 256) = 32;

void fragment() {
	float _threshold = 1. - threshold;
	vec2 ray_origin = position + vec2(.5);
	vec2 delta = (UV - ray_origin) * _length / float(quality);
	vec2 current_uv = UV;
	vec3 light_acc = vec3(.0);
	
	float dist = distance(UV, ray_origin);
	
	for (int i = 0; i < quality; i++) {
		current_uv -= delta;
		vec3 col = texture(TEXTURE, current_uv).rgb;
		
		float brightness_value = max(col.r, max(col.g, col.b));
		float mask = smoothstep(_threshold, _threshold + .1, brightness_value);
		
		float radial_mask = smoothstep(radius, .0, dist);
		
		light_acc += col * mask * radial_mask;
	}
	
	vec3 screen_col = texture(TEXTURE, UV).rgb;
	float screen_brightness = max(screen_col.r, max(screen_col.g, screen_col.b));
	
	float proximity = smoothstep(.0, radius, dist);
	float d_limit = smoothstep(darkness_threshold, darkness_threshold - .1, screen_brightness);
	
	float final_darkness = mix(1. - (darkness * d_limit), 1., proximity);
	vec3 darkened_col = screen_col * final_darkness;
	
	vec3 final_rays = (light_acc / float(quality)) * brightness * tint.rgb;
	
	COLOR = vec4(darkened_col + final_rays, 1.);
}