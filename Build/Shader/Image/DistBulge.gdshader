shader_type canvas_item;

uniform vec2 center = vec2(.0);
uniform float force: hint_range(-1., 1.) = .5;
uniform float radius: hint_range(.0, 1.) = .5;

void fragment() {
	vec2 _center = center + vec2(.5);
	vec2 uv = UV - _center;
	float dist = length(uv);
	
	if (dist < radius) {
		float percent = dist / radius;
		
		if (force >= .0) {
			uv *= mix(1., percent, force * (1. - percent));
		} else {
			uv /= mix(1., percent, -force * (1. - percent));
		}
	}
	
	COLOR = texture(TEXTURE, uv + _center);
}