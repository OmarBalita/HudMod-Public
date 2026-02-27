shader_type canvas_item;

uniform float time;
uniform sampler2D noise_texture: repeat_enable, hint_default_black;
uniform vec2 direction = vec2(.0, 1.);
uniform float speed: hint_range(.0, 1.) = .1;
uniform float force: hint_range(.0, .1) = .02;

void fragment() {
	vec2 noise_uv = UV + normalize(direction) * time * speed;
	float noise_value = texture(noise_texture, noise_uv).r;
	float distortion = (noise_value * 2. - 1.) * force;
	vec2 distorted_uv = UV + distortion;
	COLOR.rgb = texture(TEXTURE, distorted_uv).rgb;
}

