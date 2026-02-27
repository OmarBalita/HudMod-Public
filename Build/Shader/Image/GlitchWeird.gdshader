shader_type canvas_item;

uniform float time;

uniform float glitch_chance: hint_range(0.0, 1.0) = 0.2;
uniform float glitch_speed = 7.0;
uniform float slice_density = 14.0;
uniform float slice_strength = 0.38;
uniform float shake_strength = 0.02;
uniform float chroma_offset = 0.016;
uniform float noise_strength = 0.2;
uniform float color_flash_strength = 0.4;
uniform float scanline_strength = 0.18;
uniform float local_warp_strength = 0.14;
uniform float flip_chance: hint_range(0.0,1.0) = 0.15;

float rand(float x) { 
	return fract(sin(x * 143758.5453) * 43758.5453); 
}

float rand2(vec2 p) { 
	return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); 
}

void fragment() {
	vec2 uv = UV;
	
	float glitch = step(1.0 - glitch_chance, rand(floor(time * glitch_speed)));
	
	float slice_id = floor(uv.y * slice_density + rand(floor(time)));
	float slice_rand = rand(slice_id + floor(time * glitch_speed));
	float slice_mask = step(0.5, slice_rand) * glitch;
	
	if(rand(slice_id * time) < flip_chance) {
		uv.x = 1.0 - uv.x;
	}
	
	uv.x += (slice_rand - 0.5) * slice_strength * slice_mask;
	
	float jitter = step(0.85, rand(time * 12.0)) * glitch;
	uv.x += (rand(time * 3.0) - 0.5) * 0.08 * jitter;
	
	float warp_zone = step(0.65, rand2(vec2(slice_id, time)));
	uv += (vec2(rand2(uv + time), rand2(uv - time)) - 0.5) * local_warp_strength * warp_zone * glitch;
	
	uv += vec2(
		rand(time * 1.3) - 0.5,
		rand(time * 1.7) - 0.5
	) * shake_strength * glitch;
	
	vec4 base = texture(TEXTURE, uv);
	float r = texture(TEXTURE, uv + vec2(chroma_offset * glitch, 0.0)).r;
	float b = texture(TEXTURE, uv - vec2(chroma_offset * glitch, 0.0)).b;
	vec3 color = vec3(r, base.g, b);
	
	color += (rand2(uv * time * 1.5) - 0.5) * noise_strength * glitch;
	
	float scan = step(0.9, rand(uv.y * 100.0 + time * 10.0));
	color *= 1.0 - scan * scanline_strength * glitch;
	
	vec3 flash_color = vec3(
		step(0.5, rand(time + 0.1)),
		step(0.5, rand(time + 3.1)),
		step(0.5, rand(time + 6.1))
	);
	color = mix(color, flash_color, rand(time * 4.0) * color_flash_strength * glitch);
	
	COLOR = vec4(color, base.a);
}
